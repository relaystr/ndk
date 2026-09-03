import 'dart:async';

import '../../../../usecases/cashu/cashu.dart';
import '../../../../usecases/nwc/responses/pay_invoice_response.dart';
import '../../../../usecases/nwc/responses/pay_response.dart';
import '../../../../usecases/nwc/responses/receive_response.dart';
import '../../../cashu/cashu_mint_info.dart';
import '../../bip321.dart';
import '../../wallet.dart';
import '../../wallet_balance.dart';
import '../../wallet_provider.dart';
import '../../wallet_transaction.dart';
import '../../wallet_type.dart';
import 'cashu_wallet.dart';

/// Provider for Cashu wallets
/// Implements factory and operations for Cashu mint-based wallets
class CashuWalletProvider implements WalletProvider {
  final Cashu _cashuUseCase;

  CashuWalletProvider(this._cashuUseCase);

  @override
  WalletType get type => WalletType.CASHU;

  @override
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final mintUrl = metadata['mintUrl'] as String?;
    if (mintUrl == null || mintUrl.isEmpty) {
      throw ArgumentError('CashuWallet requires metadata["mintUrl"]');
    }

    final mintInfoJson = metadata['mintInfo'] as Map<String, dynamic>?;
    if (mintInfoJson == null) {
      throw ArgumentError('CashuWallet requires metadata["mintInfo"]');
    }

    return CashuWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      mintUrl: mintUrl,
      mintInfo: CashuMintInfo.fromJson(mintInfoJson),
      metadata: metadata,
    );
  }

  @override
  Future<Wallet?> initialize(Wallet wallet) async {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    await _cashuUseCase.preflightChecks();

    // Ensure mint info is cached
    await _cashuUseCase.getMintInfoNetwork(mintUrl: wallet.mintUrl);
    return null; // No wallet update needed
  }

  @override
  Future<void> removeWallet(Wallet wallet) async {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    await _cashuUseCase.deleteKnownMint(mintUrl: wallet.mintUrl);
  }

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    return _cashuUseCase.balances.map((balances) {
      return balances.where((b) => b.mintUrl == wallet.mintUrl).expand((b) {
        return b.balances.entries.map(
          (entry) => WalletBalance(
            unit: entry.key,
            amount: entry.value,
            walletId: wallet.id,
          ),
        );
      }).toList();
    });
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }
    return _cashuUseCase.pendingTransactions.map((transactions) {
      return transactions.where((tx) => tx.walletId == wallet.id).toList();
    });
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet) {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    return _cashuUseCase.latestTransactions.map((transactions) {
      return transactions.where((tx) => tx.walletId == wallet.id).toList();
    });
  }

  @override
  Future<PayInvoiceResponse> send(
    Wallet wallet,
    String invoice, {
    Duration? timeout,
  }) async {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    final result = await _payBolt11(wallet, invoice, timeout: timeout);
    return result.legacyResponse;
  }

  Future<_CashuBolt11Payment> _payBolt11(
    CashuWallet wallet,
    String invoice, {
    int? expectedAmountMsat,
    Duration? timeout,
  }) async {
    final draftTransaction = await _cashuUseCase.initiateRedeem(
      mintUrl: wallet.mintUrl,
      request: invoice,
      unit: 'sat',
      method: 'bolt11',
    );

    final amountMsat = draftTransaction.qouteMelt!.amount * 1000;
    if (expectedAmountMsat != null && amountMsat != expectedAmountMsat) {
      throw ArgumentError(
        'BIP-321 amount $expectedAmountMsat msats conflicts with '
        'the BOLT11 invoice amount $amountMsat msats',
      );
    }

    var transactions = _cashuUseCase.redeem(
      draftRedeemTransaction: draftTransaction,
    );
    if (timeout != null) {
      transactions = transactions.timeout(timeout);
    }

    await for (final transaction in transactions) {
      if (transaction.state == WalletTransactionState.completed) {
        final int feesPaid;
        if (draftTransaction.qouteMelt?.feeReserve != null) {
          feesPaid = draftTransaction.qouteMelt!.feeReserve! * 1000;
        } else {
          feesPaid = 0;
        }

        final legacyResponse = PayInvoiceResponse(
          resultType: 'pay_invoice',
          preimage: null,
          feesPaid: feesPaid,
        );
        return _CashuBolt11Payment(
          legacyResponse: legacyResponse,
          transactionId: draftTransaction.id,
          amountMsat: amountMsat,
          createdAt: draftTransaction.initiatedDate ??
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
          settledAt: transaction.transactionDate,
        );
      } else if (transaction.state == WalletTransactionState.failed) {
        throw Exception('Cashu payment failed: ${transaction.completionMsg}');
      }
    }

    throw Exception('Cashu payment did not complete');
  }

  @override
  Stream<List<Wallet>> get discoveredWallets {
    return _cashuUseCase.knownMints.map((mints) {
      return mints
          .map(
            (mint) => CashuWallet(
              id: mint.urls.first,
              name: mint.name ?? mint.urls.first,
              supportedUnits: mint.supportedUnits,
              mintUrl: mint.urls.first,
              mintInfo: mint,
            ),
          )
          .toList();
    });
  }

  @override
  Future<String> receive(Wallet wallet, int amountSats) async {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    final draftTransaction = await _cashuUseCase.initiateFund(
      mintUrl: wallet.mintUrl,
      amount: amountSats,
      unit: 'sat',
      method: 'bolt11',
    );

    final invoice = draftTransaction.qoute?.request;
    if (invoice == null || invoice.isEmpty) {
      throw Exception('Cashu receive failed: mint did not return an invoice');
    }

    unawaited(() async {
      try {
        await _cashuUseCase
            .retrieveFunds(draftTransaction: draftTransaction)
            .last;
      } catch (_) {}
    }());

    return invoice;
  }

  @override
  Future<PayResponse> payBip321(
    Wallet wallet, {
    required String payment,
    int? amountMsat,
    String? payerNote,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }
    if (payerNote?.isNotEmpty == true) {
      throw UnsupportedError('BOLT11 does not support payer notes');
    }

    final invoice = Bip321.getBolt11(payment);
    final invoiceAmountMsat = Bip321.getBolt11AmountMsat(invoice);
    if (invoiceAmountMsat == null) {
      throw UnsupportedError(
        'Cashu does not support paying amountless BOLT11 invoices',
      );
    }
    if (invoiceAmountMsat % 1000 != 0) {
      throw UnsupportedError(
        'Cashu only supports whole-satoshi BOLT11 amounts',
      );
    }
    if (amountMsat != null && amountMsat != invoiceAmountMsat) {
      throw ArgumentError(
        'BIP-321 amount $amountMsat msats conflicts with '
        'the BOLT11 invoice amount $invoiceAmountMsat msats',
      );
    }

    final result = await _payBolt11(
      wallet,
      invoice,
      expectedAmountMsat: invoiceAmountMsat,
      timeout: timeout,
    );
    return PayResponse(
      resultType: 'pay',
      transactionId: result.transactionId,
      state: 'settled',
      instructionType: 'bolt11',
      amountMsat: result.amountMsat,
      feesPaid: result.legacyResponse.feesPaid,
      preimage: result.legacyResponse.preimage,
      createdAt: result.createdAt,
      settledAt: result.settledAt,
    );
  }

  @override
  Future<ReceiveResponse> receiveBip321(
    Wallet wallet, {
    int? amountMsat,
    String? description,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    if (amountMsat == null) {
      throw UnsupportedError(
        'Cashu does not support variable-amount BOLT11 invoices',
      );
    }
    if (amountMsat <= 0 || amountMsat % 1000 != 0) {
      throw ArgumentError.value(
        amountMsat,
        'amountMsat',
        'Cashu requires a positive whole-satoshi amount',
      );
    }
    if (description?.isNotEmpty == true) {
      throw UnsupportedError(
        'Cashu does not support setting a BOLT11 description',
      );
    }

    var invoiceFuture = receive(wallet, amountMsat ~/ 1000);
    if (timeout != null) {
      invoiceFuture = invoiceFuture.timeout(timeout);
    }
    final invoice = await invoiceFuture;
    return ReceiveResponse(
      resultType: 'receive',
      bip321: Bip321.fromBolt11(invoice),
    );
  }
}

class _CashuBolt11Payment {
  final PayInvoiceResponse legacyResponse;
  final String transactionId;
  final int amountMsat;
  final int createdAt;
  final int? settledAt;

  const _CashuBolt11Payment({
    required this.legacyResponse,
    required this.transactionId,
    required this.amountMsat,
    required this.createdAt,
    required this.settledAt,
  });
}
