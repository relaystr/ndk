import 'dart:async';

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
  final Map<String, StreamSubscription> _notificationSubscriptions = {};
  final Map<String, bool> _refreshInFlight = {};

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
  Future<Wallet?> initialize(Wallet wallet) async {
    final nwcWallet = wallet as NwcWallet;
    // NWC wallets connect on-demand, but we can pre-connect here
    if (!nwcWallet.isConnected()) {
      nwcWallet.connection = await _nwcUseCase.connect(
        nwcWallet.nwcUrl,
        doGetInfoMethod: true,
      );
    }

    _ensureNotificationSubscription(nwcWallet);
    return null; // No wallet update needed
  }

  @override
  Future<void> dispose(Wallet wallet) async {
    final nwcWallet = wallet as NwcWallet;
    final sub = _notificationSubscriptions.remove(nwcWallet.id);
    if (sub != null) {
      await sub.cancel();
    }
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

    await _refreshBalance(nwcWallet);

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

    await _refreshPendingTransactions(nwcWallet);

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

    await _refreshRecentTransactions(nwcWallet);

    yield* nwcWallet.transactionsSubject!.stream;
  }

  @override
  Future<PayInvoiceResponse> payInvoice(Wallet wallet, String invoice) async {
    final nwcWallet = wallet as NwcWallet;

    if (!nwcWallet.isConnected()) {
      await initialize(wallet);
    }

    final response = await _nwcUseCase.payInvoice(
      nwcWallet.connection!,
      invoice: invoice,
    );
    await _refreshAll(nwcWallet);
    return response;
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
      amountSats: amountSats,
    );

    await _refreshAll(nwcWallet);
    return response.invoice;
  }

  void _ensureNotificationSubscription(NwcWallet wallet) {
    if (_notificationSubscriptions.containsKey(wallet.id)) {
      return;
    }
    final connection = wallet.connection;
    if (connection == null) {
      return;
    }

    _notificationSubscriptions[wallet.id] =
        connection.notificationStream.stream.listen((_) async {
      await _refreshAll(wallet);
    });
  }

  Future<void> _refreshAll(NwcWallet wallet) async {
    if (_refreshInFlight[wallet.id] == true) {
      return;
    }
    _refreshInFlight[wallet.id] = true;
    try {
      await Future.wait([
        _refreshBalance(wallet),
        _refreshPendingTransactions(wallet),
        _refreshRecentTransactions(wallet),
      ]);
    } finally {
      _refreshInFlight[wallet.id] = false;
    }
  }

  Future<void> _refreshBalance(NwcWallet wallet) async {
    wallet.balanceSubject ??= BehaviorSubject<List<WalletBalance>>();
    final balanceResponse = await _nwcUseCase.getBalance(wallet.connection!);
    wallet.balanceSubject!.add([
      WalletBalance(
        walletId: wallet.id,
        unit: "sat",
        amount: balanceResponse.balanceSats,
      ),
    ]);
  }

  Future<void> _refreshPendingTransactions(NwcWallet wallet) async {
    wallet.pendingTransactionsSubject ??=
        BehaviorSubject<List<WalletTransaction>>();
    final transactions = await _nwcUseCase.listTransactions(
      wallet.connection!,
      unpaid: true,
    );

    wallet.pendingTransactionsSubject!.add(
      transactions.transactions.reversed.map((e) {
        return NwcWalletTransaction(
          id: e.paymentHash,
          walletId: wallet.id,
          changeAmount: e.isIncoming ? e.amountSat : -e.amountSat,
          unit: "sat",
          walletType: WalletType.NWC,
          state: _mapState(e.state, defaultPending: true),
          metadata: e.metadata ?? {},
          transactionDate: e.settledAt ?? e.createdAt,
          initiatedDate: e.createdAt,
        );
      }).toList(),
    );
  }

  Future<void> _refreshRecentTransactions(NwcWallet wallet) async {
    wallet.transactionsSubject ??= BehaviorSubject<List<WalletTransaction>>();
    final transactions = await _nwcUseCase.listTransactions(
      wallet.connection!,
      unpaid: false,
    );

    wallet.transactionsSubject!.add(
      transactions.transactions.reversed.map((e) {
        return NwcWalletTransaction(
          id: e.paymentHash,
          walletId: wallet.id,
          changeAmount: e.isIncoming ? e.amountSat : -e.amountSat,
          unit: "sat",
          walletType: WalletType.NWC,
          state:
              _mapState(e.state, defaultPending: false, settledAt: e.settledAt),
          metadata: e.metadata ?? {},
          transactionDate: e.settledAt ?? e.createdAt,
          initiatedDate: e.createdAt,
        );
      }).toList(),
    );
  }

  WalletTransactionState _mapState(String? state,
      {required bool defaultPending, int? settledAt}) {
    if (state == null) {
      if (settledAt != null) {
        return WalletTransactionState.completed;
      }
      return defaultPending
          ? WalletTransactionState.pending
          : WalletTransactionState.completed;
    }
    switch (state) {
      case "pending":
        return WalletTransactionState.pending;
      case "settled":
        return WalletTransactionState.completed;
      case "failed":
        return WalletTransactionState.failed;
      case "expired":
        return WalletTransactionState.canceled;
      default:
        return WalletTransactionState.completed;
    }
  }
}
