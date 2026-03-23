import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../../entities/wallet/wallet.dart';
import '../../entities/wallet/wallet_balance.dart';
import '../../entities/wallet/wallet_provider.dart';
import '../../entities/wallet/wallet_transaction.dart';
import '../../entities/wallet/wallet_type.dart';
import '../../repositories/wallets_repo.dart';
import '../../usecases/nwc/responses/pay_invoice_response.dart';

/// Unified wallet system that handles multiple wallet types (NWC, Cashu, etc.)
/// Uses WalletProvider pattern for pluggability
class Wallets {
  final Map<WalletType, WalletProvider> _providers;
  final WalletsRepo _repository;

  int latestTransactionCount;

  StreamSubscription<List<Wallet>>? _walletsUsecaseSubscription;

  /// in memory storage
  final Set<Wallet> _wallets = {};
  final Map<String, List<WalletBalance>> _walletsBalances = {};
  final Map<String, List<WalletTransaction>> _walletsPendingTransactions = {};
  final Map<String, List<WalletTransaction>> _walletsRecentTransactions = {};

  final BehaviorSubject<List<Wallet>> _walletsSubject =
      BehaviorSubject<List<Wallet>>();

  /// combined streams for all wallets
  final BehaviorSubject<List<WalletBalance>> _combinedBalancesSubject =
      BehaviorSubject<List<WalletBalance>>();

  final BehaviorSubject<List<WalletTransaction>>
      _combinedPendingTransactionsSubject =
      BehaviorSubject<List<WalletTransaction>>();

  final BehaviorSubject<List<WalletTransaction>>
      _combinedRecentTransactionsSubject =
      BehaviorSubject<List<WalletTransaction>>();

  /// individual wallet streams - created on demand
  final Map<String, BehaviorSubject<List<WalletBalance>>>
      _walletBalanceStreams = {};

  final Map<String, BehaviorSubject<List<WalletTransaction>>>
      _walletPendingTransactionStreams = {};

  final Map<String, BehaviorSubject<List<WalletTransaction>>>
      _walletRecentTransactionStreams = {};

  /// stream subscriptions for cleanup
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  late final Future<void> _initializationFuture;
  bool _isDisposed = false;

  Wallets({
    required List<WalletProvider> providers,
    required WalletsRepo repository,
    this.latestTransactionCount = 10,
  })  : _providers = {for (final p in providers) p.type: p},
        _repository = repository {
    _initializationFuture = _initialize();
  }

  bool _balancesActivated = false;
  bool _pendingActivated = false;
  bool _recentActivated = false;

  /// public-facing stream of combined balances, grouped by currency.
  late final Stream<List<WalletBalance>> combinedBalances =
      _combinedBalancesSubject.stream.doOnListen(_activateBalances);

  /// public-facing stream of combined pending transactions.
  late final Stream<List<WalletTransaction>> combinedPendingTransactions =
      _combinedPendingTransactionsSubject.stream.doOnListen(_activatePending);

  /// public-facing stream of combined recent transactions.
  late final Stream<List<WalletTransaction>> combinedRecentTransactions =
      _combinedRecentTransactionsSubject.stream.doOnListen(_activateRecent);

  void _activateBalances() {
    if (_balancesActivated) return;
    _balancesActivated = true;
    for (final wallet in _wallets) {
      _initBalanceStream(wallet.id);
    }
  }

  void _activatePending() {
    if (_pendingActivated) return;
    _pendingActivated = true;
    for (final wallet in _wallets) {
      _initPendingTransactionStream(wallet.id);
    }
  }

  void _activateRecent() {
    if (_recentActivated) return;
    _recentActivated = true;
    for (final wallet in _wallets) {
      _initRecentTransactionStream(wallet.id);
    }
  }

  /// stream of all wallets
  Stream<List<Wallet>> get walletsStream => _walletsSubject.stream;

  Future<List<WalletTransaction>> combinedTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    return _repository.getTransactions(
      limit: limit,
      offset: offset,
      walletId: walletId,
      unit: unit,
      walletType: walletType,
    );
  }

  /// Get default wallet for receiving
  Wallet? get defaultWalletForReceiving {
    final walletId = _repository.getDefaultWalletIdForReceiving();
    if (walletId == null) {
      return null;
    }
    return _wallets.firstWhereOrNull((wallet) => wallet.id == walletId);
  }

  /// Get default wallet for sending
  Wallet? get defaultWalletForSending {
    final walletId = _repository.getDefaultWalletIdForSending();
    if (walletId == null) {
      return null;
    }
    return _wallets.firstWhereOrNull((wallet) => wallet.id == walletId);
  }

  Future<void> _initialize() async {
    if (_isDisposed) {
      return;
    }

    // Load wallets from repository
    final wallets = await _repository.getWallets();

    for (final wallet in wallets) {
      await _addWalletToMemory(wallet);
    }

    // Listen to discovered wallets from all providers
    _walletsUsecaseSubscription = Rx.merge(
      _providers.values.map((p) => p.discoveredWallets),
    ).listen((wallets) {
      for (final wallet in wallets) {
        if (!_wallets.any((w) => w.id == wallet.id)) {
          addWallet(wallet);
        }
      }
    });

    if (_isDisposed) {
      return;
    }

    _updateCombinedStreams();
  }

  void _updateCombinedStreams() {
    // combine all wallet balances
    final allBalances =
        _walletsBalances.values.expand((balances) => balances).toList();
    if (!_combinedBalancesSubject.isClosed) {
      _combinedBalancesSubject.add(allBalances);
    }

    // combine all pending transactions
    final allPending = _walletsPendingTransactions.values
        .expand((transactions) => transactions)
        .toList();
    if (!_combinedPendingTransactionsSubject.isClosed) {
      _combinedPendingTransactionsSubject.add(allPending);
    }

    // combine all recent transactions
    final allRecent = _walletsRecentTransactions.values
        .expand((transactions) => transactions)
        .toList();
    if (!_combinedRecentTransactionsSubject.isClosed) {
      _combinedRecentTransactionsSubject.add(allRecent);
    }
  }

  Future<void> _addWalletToMemory(Wallet wallet) async {
    // store wallet in memory while preserving order
    final list = _wallets.toList();
    final existingIndex = list.indexWhere((w) => w.id == wallet.id);
    if (existingIndex >= 0) {
      list[existingIndex] = wallet;
    } else {
      list.add(wallet);
    }
    _wallets.clear();
    _wallets.addAll(list);
    _safeAddWallets(list);

    // initialize empty data collections
    _walletsBalances[wallet.id] = [];
    _walletsPendingTransactions[wallet.id] = [];
    _walletsRecentTransactions[wallet.id] = [];

    // Initialize transaction streams so combined feeds stay updated.
    // Only subscribe if someone is already listening
    if (_balancesActivated) _initBalanceStream(wallet.id);
    if (_pendingActivated) _initPendingTransactionStream(wallet.id);
    if (_recentActivated) _initRecentTransactionStream(wallet.id);
  }

  /// Create a new wallet using the appropriate provider
  Wallet createWallet({
    required String id,
    required String name,
    required WalletType type,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final provider = _providers[type];
    if (provider == null) {
      throw ArgumentError('No provider registered for wallet type: $type');
    }
    return provider.createWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      metadata: metadata,
    );
  }

  /// Add a new wallet to the system
  Future<void> addWallet(Wallet wallet) async {
    await _repository.storeWallet(wallet);
    await _addWalletToMemory(wallet);

    // Initialize with provider
    final provider = _providers[wallet.type];
    if (provider != null) {
      final updatedWallet = await provider.initialize(wallet);
      if (updatedWallet != null) {
        // Replace old wallet with updated one while preserving order
        final list = _wallets.toList();
        final existingIndex = list.indexWhere((w) => w.id == wallet.id);
        if (existingIndex >= 0) {
          list[existingIndex] = updatedWallet;
          _wallets.clear();
          _wallets.addAll(list);
          _safeAddWallets(list);
        }
        // Also update in repository (addWallet handles updates too)
        await _repository.storeWallet(updatedWallet);
      }
    }

    if (wallet.canReceive &&
        _repository.getDefaultWalletIdForReceiving() == null) {
      _repository.setDefaultWalletForReceiving(wallet.id);
    }

    if (wallet.canSend && _repository.getDefaultWalletIdForSending() == null) {
      _repository.setDefaultWalletForSending(wallet.id);
    }

    _updateCombinedStreams();
  }

  /// Remove wallet - persists on disk
  Future<void> removeWallet(String walletId) async {
    final wallet = _wallets.firstWhereOrNull((w) => w.id == walletId);
    if (wallet != null) {
      // Dispose with provider
      final provider = _providers[wallet.type];
      if (provider != null) {
        await provider.removeWallet(wallet);
      }
    }

    await _repository.removeWallet(walletId);

    // clean up in-memory data
    _wallets.removeWhere((wallet) => wallet.id == walletId);
    _walletsBalances.remove(walletId);
    _walletsPendingTransactions.remove(walletId);
    _walletsRecentTransactions.remove(walletId);

    // clean up streams
    _walletBalanceStreams[walletId]?.close();
    _walletPendingTransactionStreams[walletId]?.close();
    _walletRecentTransactionStreams[walletId]?.close();

    _walletBalanceStreams.remove(walletId);
    _walletPendingTransactionStreams.remove(walletId);
    _walletRecentTransactionStreams.remove(walletId);

    // clean up subscriptions
    _subscriptions[walletId]?.forEach((sub) => sub.cancel());
    _subscriptions.remove(walletId);

    // update wallets stream with the new list
    _safeAddWallets(_wallets.toList());

    _updateCombinedStreams();

    if (walletId == _repository.getDefaultWalletIdForReceiving()) {
      Wallet? wallet = _wallets.where((w) => w.canReceive).firstOrNull;
      if (wallet != null) {
        _repository.setDefaultWalletForReceiving(wallet.id);
      }
    }
    if (walletId == _repository.getDefaultWalletIdForSending()) {
      Wallet? wallet = _wallets.where((w) => w.canSend).firstOrNull;
      if (wallet != null) {
        _repository.setDefaultWalletForSending(wallet.id);
      }
    }
  }

  /// Set the default wallet to use by common operations
  void setDefaultWallet(String walletId) {
    if (_wallets.any((wallet) => wallet.id == walletId)) {
      _repository.setDefaultWalletForReceiving(walletId);
      _repository.setDefaultWalletForSending(walletId);
    } else {
      throw ArgumentError('Wallet with id $walletId does not exist.');
    }
  }

  /// Set default wallet for receiving funds (e.g. for generating invoices)
  void setDefaultWalletForReceiving(String walletId) {
    if (_wallets.any((wallet) => wallet.id == walletId)) {
      _repository.setDefaultWalletForReceiving(walletId);
    } else {
      throw ArgumentError('Wallet with id $walletId does not exist.');
    }
  }

  /// Set default wallet for sending funds (e.g. for paying invoices)
  void setDefaultWalletForSending(String walletId) {
    if (_wallets.any((wallet) => wallet.id == walletId)) {
      _repository.setDefaultWalletForSending(walletId);
    } else {
      throw ArgumentError('Wallet with id $walletId does not exist.');
    }
  }

  void _initBalanceStream(String id) {
    if (_walletBalanceStreams[id] == null) {
      _walletBalanceStreams[id] = BehaviorSubject<List<WalletBalance>>();
      final subscriptions = <StreamSubscription>[];

      _getWalletAsync(id).then((wallet) {
        if (wallet != null) {
          final provider = _providers[wallet.type];
          if (provider != null) {
            subscriptions.add(
              provider.getBalances(wallet).listen((balances) {
                _walletsBalances[id] = balances;
                _walletBalanceStreams[id]?.add(balances);
                _updateCombinedStreams();
              }, onError: (error) {
                _walletBalanceStreams[id]?.add([]);
              }),
            );
          }
        }
      });

      if (_subscriptions[id] == null) {
        _subscriptions[id] = subscriptions;
      } else {
        _subscriptions[id]?.addAll(subscriptions);
      }
    }
  }

  void _initRecentTransactionStream(String id) {
    if (_walletRecentTransactionStreams[id] == null) {
      _walletRecentTransactionStreams[id] =
          BehaviorSubject<List<WalletTransaction>>();
      final subscriptions = <StreamSubscription>[];

      _getWalletAsync(id).then((wallet) {
        if (wallet != null) {
          final provider = _providers[wallet.type];
          if (provider != null) {
            subscriptions.add(
              provider.getRecentTransactions(wallet).listen((transactions) {
                transactions =
                    transactions.where((tx) => tx.state.isDone).toList();
                _walletsRecentTransactions[id] = transactions;
                _walletRecentTransactionStreams[id]?.add(transactions);
                _updateCombinedStreams();
              }, onError: (error) {
                _walletRecentTransactionStreams[id]?.add([]);
              }),
            );
          }
        }
      });

      if (_subscriptions[id] == null) {
        _subscriptions[id] = subscriptions;
      } else {
        _subscriptions[id]?.addAll(subscriptions);
      }
    }
  }

  void _initPendingTransactionStream(String id) {
    if (_walletPendingTransactionStreams[id] == null) {
      _walletPendingTransactionStreams[id] =
          BehaviorSubject<List<WalletTransaction>>();
      final subscriptions = <StreamSubscription>[];

      _getWalletAsync(id).then((wallet) {
        if (wallet != null) {
          final provider = _providers[wallet.type];
          if (provider != null) {
            subscriptions.add(
              provider.getPendingTransactions(wallet).listen((transactions) {
                transactions =
                    transactions.where((tx) => tx.state.isPending).toList();
                _walletsPendingTransactions[id] = transactions;
                _walletPendingTransactionStreams[id]?.add(transactions);
                _updateCombinedStreams();
              }, onError: (error) {
                _walletPendingTransactionStreams[id]?.add([]);
              }),
            );
          }
        }
      });

      if (_subscriptions[id] == null) {
        _subscriptions[id] = subscriptions;
      } else {
        _subscriptions[id]?.addAll(subscriptions);
      }
    }
  }

  Future<Wallet?> _getWalletAsync(String id) async {
    return _wallets.firstWhereOrNull((w) => w.id == id);
  }

  Stream<List<WalletBalance>> getBalancesStream(String walletId) {
    _initBalanceStream(walletId);
    return _walletBalanceStreams[walletId]!.stream;
  }

  Stream<List<WalletTransaction>> getRecentTransactionsStream(String walletId) {
    _initRecentTransactionStream(walletId);
    return _walletRecentTransactionStreams[walletId]!.stream;
  }

  Stream<List<WalletTransaction>> getPendingTransactionsStream(
      String walletId) {
    _initPendingTransactionStream(walletId);
    return _walletPendingTransactionStreams[walletId]!.stream;
  }

  int getBalance(String walletId, String unit) {
    _initBalanceStream(walletId);
    final balances = _walletsBalances[walletId];
    if (balances == null) {
      return 0;
    }
    final balance =
        balances.firstWhereOrNull((balance) => balance.unit == unit);
    return balance?.amount ?? 0;
  }

  /// Calculate combined balance for a specific currency
  int getCombinedBalance(String unit) {
    return _walletsBalances.values
        .expand((balances) => balances)
        .where((balance) => balance.unit == unit)
        .fold(0, (sum, balance) => sum + balance.amount);
  }

  /// Get wallets that support a specific currency
  List<Wallet> getWalletsForUnit(String unit) {
    return _wallets
        .where((wallet) => wallet.supportedUnits.any((u) => u == unit))
        .toList();
  }

  /// Get transactions from storage
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    return _repository.getTransactions(
      limit: limit,
      offset: offset,
      walletId: walletId,
      unit: unit,
      walletType: walletType,
    );
  }

  /// Send payment
  Future<PayInvoiceResponse> send(
      {String? walletId, required String invoice}) async {
    await _initializationFuture;
    walletId ??= _repository.getDefaultWalletIdForSending();
    if (walletId == null) {
      throw StateError('No default wallet set');
    }
    final wallet = await _getWalletForOperation(walletId);
    final provider = _providers[wallet.type];
    if (provider == null) {
      throw ArgumentError('No provider for wallet type: ${wallet.type}');
    }
    return provider.send(wallet, invoice);
  }

  /// Create a Lightning invoice to receive funds
  /// Returns the invoice string
  Future<String> receive({String? walletId, required int amountSats}) async {
    await _initializationFuture;
    walletId ??= _repository.getDefaultWalletIdForReceiving();
    if (walletId == null) {
      throw StateError('No default wallet set');
    }
    final wallet = await _getWalletForOperation(walletId);
    final provider = _providers[wallet.type];
    if (provider == null) {
      throw ArgumentError('No provider for wallet type: ${wallet.type}');
    }
    return provider.receive(wallet, amountSats);
  }

  Future<Wallet> _getWalletForOperation(String walletId) async {
    final inMemory =
        _wallets.firstWhereOrNull((wallet) => wallet.id == walletId);
    if (inMemory != null) {
      return inMemory;
    }

    final stored = await _repository.getWallet(walletId);
    await _addWalletToMemory(stored);
    return stored;
  }

  /// todo: implement zap
  Future<void> zap({
    required String pubkey,
    required int amount,
    String? comment,
  }) {
    throw UnimplementedError('Zap not yet implemented');
  }

  Future<void> dispose() async {
    _isDisposed = true;

    try {
      await _initializationFuture;
    } catch (_) {
      // Ignore initialization errors during dispose.
    }

    final futures = <Future>[];

    _walletsUsecaseSubscription?.cancel();

    // Dispose all wallets with their providers
    for (final wallet in _wallets) {
      final provider = _providers[wallet.type];
      if (provider != null) {
        futures.add(provider.removeWallet(wallet));
      }
    }

    // cancel all subscriptions
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        futures.add(sub.cancel());
      }
    }

    // close all streams
    futures.addAll([
      _combinedBalancesSubject.close(),
      _combinedPendingTransactionsSubject.close(),
      _combinedRecentTransactionsSubject.close(),
    ]);

    for (final stream in _walletBalanceStreams.values) {
      futures.add(stream.close());
    }
    for (final stream in _walletPendingTransactionStreams.values) {
      futures.add(stream.close());
    }
    for (final stream in _walletRecentTransactionStreams.values) {
      futures.add(stream.close());
    }

    await Future.wait(futures);

    _balancesActivated = false;
    _pendingActivated = false;
    _recentActivated = false;

    _wallets.clear();
    _walletsBalances.clear();
    _walletsPendingTransactions.clear();
    _walletsRecentTransactions.clear();
    _walletBalanceStreams.clear();
    _walletPendingTransactionStreams.clear();
    _walletRecentTransactionStreams.clear();
    _subscriptions.clear();
  }

  void _safeAddWallets(List<Wallet> wallets) {
    if (_walletsSubject.isClosed) {
      return;
    }
    _walletsSubject.add(wallets);
  }
}
