import 'dart:async';

import '../../../../usecases/cashu/cashu.dart';
import '../../../../usecases/nwc/responses/pay_invoice_response.dart';
import '../../../cashu/cashu_mint_info.dart';
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

    // Ensure mint info is cached
    await _cashuUseCase.getMintInfoNetwork(mintUrl: wallet.mintUrl);
    return null; // No wallet update needed
  }

  @override
  Future<void> removeWallet(Wallet wallet) async {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    _cashuUseCase.deleteKnownMint(mintUrl: wallet.mintUrl);
  }

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    return _cashuUseCase.balances.map((balances) {
      return balances.where((b) => b.mintUrl == wallet.mintUrl).expand((b) {
        return b.balances.entries.map((entry) => WalletBalance(
              unit: entry.key,
              amount: entry.value,
              walletId: wallet.id,
            ));
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
  Future<PayInvoiceResponse> send(Wallet wallet, String invoice) async {
    if (wallet is! CashuWallet) {
      throw ArgumentError('Expected a CashuWallet');
    }

    final draftTransaction = await _cashuUseCase.initiateRedeem(
      mintUrl: wallet.mintUrl,
      request: invoice,
      unit: 'sat',
      method: 'bolt11',
    );

    await for (final transaction in _cashuUseCase.redeem(
      draftRedeemTransaction: draftTransaction,
    )) {
      if (transaction.state == WalletTransactionState.completed) {
        final int feesPaid;
        if (draftTransaction.qouteMelt?.feeReserve != null) {
          feesPaid = draftTransaction.qouteMelt!.feeReserve! * 1000;
        } else {
          feesPaid = 0;
        }

        return PayInvoiceResponse(
          resultType: 'pay_invoice',
          preimage: null,
          feesPaid: feesPaid,
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
          .map((mint) => CashuWallet(
                id: mint.urls.first,
                name: mint.name ?? mint.urls.first,
                supportedUnits: mint.supportedUnits,
                mintUrl: mint.urls.first,
                mintInfo: mint,
              ))
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
}
