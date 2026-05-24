import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../../usecases/nwc/consts/nwc_method.dart';
import '../../../../usecases/nwc/nwc.dart';
import '../../../../usecases/nwc/nwc_connection.dart';
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
  final Map<String, bool> _refreshInFlight = {};

  /// Track in-flight connection attempts to prevent concurrent connections for the same wallet
  final Map<String, Completer<void>> _connectionInProgress = {};

  /// Subscriptions to NWC notification streams, one per wallet.
  /// Cancelled in [removeWallet].
  final Map<String, StreamSubscription<dynamic>> _notificationSubscriptions = {};

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
  Future<void> removeWallet(Wallet wallet) async {
    final nwcWallet = wallet as NwcWallet;
    // Cancel notification listener before disconnecting.
    await _notificationSubscriptions[nwcWallet.id]?.cancel();
    _notificationSubscriptions.remove(nwcWallet.id);
    if (nwcWallet.connection != null) {
      await _nwcUseCase.disconnect(nwcWallet.connection!);
      await nwcWallet.balanceSubject?.close();
      await nwcWallet.transactionsSubject?.close();
      await nwcWallet.pendingTransactionsSubject?.close();
      nwcWallet.connection = null;
    }
  }

  @override
  Future<Wallet?> initialize(Wallet wallet) async {
    final nwcWallet = wallet as NwcWallet;

    if (nwcWallet.isConnected()) {
      return null;
    }

    final existingCompleter = _connectionInProgress[nwcWallet.id];
    if (existingCompleter != null) {
      // Wait for the existing connection attempt to complete.
      await existingCompleter.future;
      return null;
    }

    final completer = Completer<void>();
    _connectionInProgress[nwcWallet.id] = completer;

    try {
      await _connectWallet(nwcWallet);
      completer.complete();
      final fetchedPermissions = nwcWallet.connection?.permissions ?? {};
      if (!_setEquals(fetchedPermissions, nwcWallet.cachedPermissions)) {
        return nwcWallet.withCachedPermissions(fetchedPermissions);
      }
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _connectionInProgress.remove(nwcWallet.id);
    }
    return null;
  }

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) async* {
    final nwcWallet = wallet as NwcWallet;

    await initialize(wallet);

    nwcWallet.balanceSubject ??= BehaviorSubject<List<WalletBalance>>();

    await _refreshBalance(nwcWallet);

    yield* nwcWallet.balanceSubject!.stream;
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) async* {
    final nwcWallet = wallet as NwcWallet;

    await initialize(wallet);

    nwcWallet.pendingTransactionsSubject ??=
        BehaviorSubject<List<WalletTransaction>>();

    await _refreshPendingTransactions(nwcWallet);

    yield* nwcWallet.pendingTransactionsSubject!.stream;
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet) async* {
    final nwcWallet = wallet as NwcWallet;

    await initialize(wallet);

    nwcWallet.transactionsSubject ??=
        BehaviorSubject<List<WalletTransaction>>();

    await _refreshRecentTransactions(nwcWallet);

    yield* nwcWallet.transactionsSubject!.stream;
  }

  @override
  Future<PayInvoiceResponse> send(Wallet wallet, String invoice, {Duration? timeout}) async {
    final nwcWallet = wallet as NwcWallet;

    await initialize(wallet);
    final connection = _connectionOrThrow(nwcWallet);

    final response = await _nwcUseCase.payInvoice(
      connection,
      invoice: invoice,
      timeout: timeout
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

    await initialize(wallet);
    final connection = _connectionOrThrow(nwcWallet);

    final response = await _nwcUseCase.makeInvoice(
      connection,
      amountSats: amountSats,
    );

    // await _refreshAll(nwcWallet);
    return response.invoice;
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

  /// Fetches and caches the remaining NWC budget for [wallet].
  /// No-op if the connection is gone or the wallet lacks get_budget permission.
  Future<void> _refreshBudget(NwcWallet wallet) async {
    final connection = wallet.connection;
    if (connection == null) return;
    final perms = connection.permissions.isNotEmpty
        ? connection.permissions
        : wallet.cachedPermissions;
    if (!perms.contains(NwcMethod.GET_BUDGET.name)) return;
    try {
      final budget = await _nwcUseCase
          .getBudget(connection)
          .timeout(const Duration(seconds: 10));
      // totalBudget == 0 means no spending limit configured → null (unlimited).
      wallet.cachedRemainingBudgetSats = budget.totalBudget > 0
          ? budget.totalBudgetSats - budget.userBudgetSats
          : null;
    } catch (_) {
      // Leave existing cached value on error.
    }
  }

  Future<void> _refreshBalance(NwcWallet wallet) async {
    wallet.balanceSubject ??= BehaviorSubject<List<WalletBalance>>();
    final connection = _connectionOrThrow(wallet);
    final balanceResponse = await _nwcUseCase.getBalance(connection);
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
    final connection = _connectionOrThrow(wallet);
    final transactions = await _nwcUseCase.listTransactions(
      connection,
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
    final connection = _connectionOrThrow(wallet);
    final transactions = await _nwcUseCase.listTransactions(
      connection,
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

  NwcConnection _connectionOrThrow(NwcWallet wallet) {
    final connection = wallet.connection;
    if (connection == null) {
      throw StateError('NWC wallet ${wallet.id} is not connected');
    }
    return connection;
  }

  Future<void> _connectWallet(NwcWallet wallet) async {
    wallet.connection = await _nwcUseCase.connect(
      wallet.nwcUrl,
      doGetInfoMethod: true,
    );

    // Auto-refresh balance whenever the wallet reports a payment notification
    // (payment_sent, payment_received, hold_invoice_accepted).
    // This keeps ndk.wallets.getBalance() accurate without polling.
    _notificationSubscriptions[wallet.id]?.cancel();
    _notificationSubscriptions[wallet.id] =
        wallet.connection!.notificationStream.stream.listen((_) {
      _refreshBalance(wallet).catchError((_) {});
      _refreshBudget(wallet).catchError((_) {});
    });
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
