import 'package:rxdart/rxdart.dart';

import '../../../../usecases/nwc/nwc.dart';
import '../../../../usecases/nwc/responses/pay_invoice_response.dart';
import '../../wallet.dart';
import '../../wallet_balance.dart';
import '../../wallet_provider.dart';
import '../../wallet_transaction.dart';
import '../../wallet_type.dart';
import 'nwc_wallet.dart';

/// Provider for NWC wallets
/// Implements factory and operations for Nostr Wallet Connect wallets
class NwcWalletProvider implements WalletProvider {
  final Nwc _nwcUseCase;

  NwcWalletProvider(this._nwcUseCase);

  @override
  WalletType get type => WalletType.NWC;

  @override
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final nwcUrl = metadata['nwcUrl'] as String?;
    if (nwcUrl == null || nwcUrl.isEmpty) {
      throw ArgumentError('NwcWallet requires metadata["nwcUrl"]');
    }

    return NwcWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      nwcUrl: nwcUrl,
      metadata: metadata,
    );
  }

  @override
  Future<void> initialize(Wallet wallet) async {
    final nwcWallet = wallet as NwcWallet;
    // NWC wallets connect on-demand, but we can pre-connect here
    if (!nwcWallet.isConnected()) {
      nwcWallet.connection = await _nwcUseCase.connect(
        nwcWallet.nwcUrl,
        doGetInfoMethod: true,
      );
    }
  }

  @override
  Future<void> dispose(Wallet wallet) async {
    final nwcWallet = wallet as NwcWallet;
    if (nwcWallet.connection != null) {
      await _nwcUseCase.disconnect(nwcWallet.connection!);
      await nwcWallet.balanceSubject?.close();
      await nwcWallet.transactionsSubject?.close();
      await nwcWallet.pendingTransactionsSubject?.close();
      nwcWallet.connection = null;
    }
  }

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) async* {
    final nwcWallet = wallet as NwcWallet;

    if (!nwcWallet.isConnected()) {
      await initialize(wallet);
    }

    nwcWallet.balanceSubject ??= BehaviorSubject<List<WalletBalance>>();

    final balanceResponse = await _nwcUseCase.getBalance(nwcWallet.connection!);
    nwcWallet.balanceSubject!.add([
      WalletBalance(
        walletId: wallet.id,
        unit: "sat",
        amount: balanceResponse.balanceSats,
      ),
    ]);

    yield* nwcWallet.balanceSubject!.stream;
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) async* {
    final nwcWallet = wallet as NwcWallet;

    if (!nwcWallet.isConnected()) {
      await initialize(wallet);
    }

    nwcWallet.pendingTransactionsSubject ??=
        BehaviorSubject<List<WalletTransaction>>();

    final transactions = await _nwcUseCase.listTransactions(
      nwcWallet.connection!,
      unpaid: true,
    );

    nwcWallet.pendingTransactionsSubject!.add(
      transactions.transactions.reversed
          .where((e) => e.state != null && e.state == "pending")
          .map((e) => NwcWalletTransaction(
                id: e.paymentHash,
                walletId: wallet.id,
                changeAmount: e.isIncoming ? e.amountSat : -e.amountSat,
                unit: "sats",
                walletType: WalletType.NWC,
                state: WalletTransactionState.pending,
                metadata: e.metadata ?? {},
                transactionDate: e.settledAt ?? e.createdAt,
                initiatedDate: e.createdAt,
              ))
          .toList(),
    );

    yield* nwcWallet.pendingTransactionsSubject!.stream;
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet) async* {
    final nwcWallet = wallet as NwcWallet;

    if (!nwcWallet.isConnected()) {
      await initialize(wallet);
    }

    nwcWallet.transactionsSubject ??=
        BehaviorSubject<List<WalletTransaction>>();

    final transactions = await _nwcUseCase.listTransactions(
      nwcWallet.connection!,
      unpaid: false,
    );

    nwcWallet.transactionsSubject!.add(
      transactions.transactions.reversed
          .where((e) => e.state != null && e.state == "settled")
          .map((e) => NwcWalletTransaction(
                id: e.paymentHash,
                walletId: wallet.id,
                changeAmount: e.isIncoming ? e.amountSat : -e.amountSat,
                unit: "sats",
                walletType: WalletType.NWC,
                state: WalletTransactionState.completed,
                metadata: e.metadata ?? {},
                transactionDate: e.settledAt ?? e.createdAt,
                initiatedDate: e.createdAt,
              ))
          .toList(),
    );

    yield* nwcWallet.transactionsSubject!.stream;
  }

  @override
  Future<PayInvoiceResponse> payInvoice(Wallet wallet, String invoice) async {
    final nwcWallet = wallet as NwcWallet;

    if (!nwcWallet.isConnected()) {
      await initialize(wallet);
    }

    return _nwcUseCase.payInvoice(
      nwcWallet.connection!,
      invoice: invoice,
    );
  }

  @override
  Stream<List<Wallet>> get discoveredWallets {
    // NWC doesn't auto-discover wallets
    // Wallets must be explicitly connected via URI
    return Stream.value([]);
  }

  @override
  Future<String> receive(Wallet wallet, int amountSats) async {
    final nwcWallet = wallet as NwcWallet;

    if (!nwcWallet.isConnected()) {
      await initialize(wallet);
    }

    final response = await _nwcUseCase.makeInvoice(
      nwcWallet.connection!,
      amountSats: amountSats
    );

    return response.invoice;
  }
}
