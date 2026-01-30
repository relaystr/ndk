import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../../entities/wallet/wallet_balance.dart';
import '../../entities/wallet/wallet_transaction.dart';
import '../../entities/wallet/wallet_type.dart';
import '../../repositories/wallets_operations_repo.dart';
import '../../repositories/wallets_repo.dart';
import '../../entities/wallet/wallet.dart';

/// Proposal for a unified wallet system that can handle multiple wallet types (NWC, Cashu).
class Wallets {
  final WalletsRepo _walletsRepository;
  final WalletsOperationsRepo _walletsOperationsRepository;

  int latestTransactionCount;

  String? defaultWalletId;

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

  Wallets({
    required WalletsRepo walletsRepository,
    required WalletsOperationsRepo walletsOperationsRepository,
    this.latestTransactionCount = 10,
  })  : _walletsRepository = walletsRepository,
        _walletsOperationsRepository = walletsOperationsRepository {
    _initializeWallet();
  }

  /// public-facing stream of combined balances, grouped by currency.
  Stream<List<WalletBalance>> get combinedBalances =>
      _combinedBalancesSubject.stream;

  /// public-facing stream of combined pending transactions.
  Stream<List<WalletTransaction>> get combinedPendingTransactions =>
      _combinedPendingTransactionsSubject.stream;

  /// public-facing stream of combined recent transactions.
  Stream<List<WalletTransaction>> get combinedRecentTransactions =>
      _combinedRecentTransactionsSubject.stream;

  Future<List<WalletTransaction>> combinedTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    return _walletsRepository.getTransactions(
      limit: limit,
      offset: offset,
      walletId: walletId,
      unit: unit,
      walletType: walletType,
    );
  }

  /// stream of all wallets, \
  /// usecases can add new wallets dynamically
  Stream<List<Wallet>> get walletsStream => _walletsSubject.stream;

  Wallet? get defaultWallet {
    if (defaultWalletId == null) {
      return null;
    }
    return _wallets.firstWhereOrNull((wallet) => wallet.id == defaultWalletId);
  }

  Future<void> _initializeWallet() async {
    // load wallets from repository
    final wallets = await _walletsRepository.getWallets();

    for (final wallet in wallets) {
      await _addWalletToMemory(wallet);
    }

    // listen to wallet updates from usecases
    _walletsUsecaseSubscription =
        _walletsRepository.walletsUsecaseStream().listen((wallets) {
      for (final wallet in wallets) {
        if (!_wallets.any((w) => w.id == wallet.id)) {
          addWallet(wallet);
        }
      }
    });

    _updateCombinedStreams();
  }

  void _updateCombinedStreams() {
    // combine all wallet balances
    final allBalances =
        _walletsBalances.values.expand((balances) => balances).toList();
    _combinedBalancesSubject.add(allBalances);

    // combine all pending transactions
    final allPending = _walletsPendingTransactions.values
        .expand((transactions) => transactions)
        .toList();
    _combinedPendingTransactionsSubject.add(allPending);

    // combine all recent transactions
    final allRecent = _walletsRecentTransactions.values
        .expand((transactions) => transactions)
        .toList();
    _combinedRecentTransactionsSubject.add(allRecent);
  }

  Future<void> _addWalletToMemory(Wallet wallet) async {
    // store wallet in memory
    _wallets.add(wallet);
    _walletsSubject.add(_wallets.toList());

    // initialize empty data collections
    _walletsBalances[wallet.id] = [];
    _walletsPendingTransactions[wallet.id] = [];
    _walletsRecentTransactions[wallet.id] = [];

    if (defaultWallet == null) {
      setDefaultWallet(wallet.id);
    }
  }

  /// add a new wallet to the system
  Future<void> addWallet(Wallet wallet) async {
    await _walletsRepository.addWallet(wallet);
    await _addWalletToMemory(wallet);
    _updateCombinedStreams();
  }

  /// remove wallet - persists on disk
  Future<void> removeWallet(String walletId) async {
    await _walletsRepository.removeWallet(walletId);

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
    _walletsSubject.add(_wallets.toList());

    _updateCombinedStreams();

    if (walletId == defaultWalletId) {
      defaultWalletId = _wallets.isNotEmpty ? _wallets.first.id : null;
    }
  }

  /// set the default wallet to use by common operations \

  void setDefaultWallet(String walletId) {
    if (_wallets.any((wallet) => wallet.id == walletId)) {
      defaultWalletId = walletId;
    } else {
      throw ArgumentError('Wallet with id $walletId does not exist.');
    }
  }

  void _initBalanceStream(String id) {
    if (_walletBalanceStreams[id] == null) {
      _walletBalanceStreams[id] ??= BehaviorSubject<List<WalletBalance>>();
      final subscriptions = <StreamSubscription>[];
      subscriptions.add(_walletsRepository.getBalancesStream(id).listen((balances) {
        _walletsBalances[id] = balances;
        _walletBalanceStreams[id]?.add(balances);
        _updateCombinedStreams();
      }));
      if (_subscriptions[id] == null) {
        _subscriptions[id] = subscriptions;
      } else {
        _subscriptions[id]?.addAll(subscriptions);
      }
    }
  }

  void _initRecentTransactionStream(String id) {
    if (_walletRecentTransactionStreams[id] == null) {
      _walletRecentTransactionStreams[id] ??=
          BehaviorSubject<List<WalletTransaction>>();
      final subscriptions = <StreamSubscription>[];
      subscriptions.add(_walletsRepository.getRecentTransactionsStream(id).listen((transactions) {
        transactions = transactions.where((tx) => tx.state.isDone).toList();
        _walletsRecentTransactions[id] = transactions;
        _walletRecentTransactionStreams[id]?.add(transactions);
        _updateCombinedStreams();
      }));
      if (_subscriptions[id] == null) {
        _subscriptions[id] = subscriptions;
      } else {
        _subscriptions[id]?.addAll(subscriptions);
    }
    }
  }

  void _initPendingTransactionStream(String id) {
    if (_walletPendingTransactionStreams[id] == null) {
      _walletPendingTransactionStreams[id] ??=
          BehaviorSubject<List<WalletTransaction>>();
      final subscriptions = <StreamSubscription>[];
      subscriptions.add(_walletsRepository.getPendingTransactionsStream(id).listen((transactions) {
        transactions = transactions.where((tx) => tx.state.isPending).toList();
        _walletsPendingTransactions[id] = transactions;
        _walletPendingTransactionStreams[id]?.add(transactions);
        _updateCombinedStreams();
      }));
      if (_subscriptions[id] == null) {
        _subscriptions[id] = subscriptions;
      } else {
        _subscriptions[id]?.addAll(subscriptions);
      }
    }
  }

  Stream<List<WalletBalance>> getBalancesStream(String walletId) {
    _initBalanceStream(walletId);
    return _walletBalanceStreams[walletId]!.stream;
  }

  Stream<List<WalletTransaction>> getRecentTransactionsStream(String walletId) {
    _initRecentTransactionStream(walletId);
    return _walletRecentTransactionStreams[walletId]!.stream;
  }

  Stream<List<WalletTransaction>> getPendingTransactionsStream(String walletId) {
    _initPendingTransactionStream(walletId);
    return _walletPendingTransactionStreams[walletId]!.stream;
  }

  int getBalance(String walletId, String unit) {
    _initBalanceStream(walletId);
    final balances = _walletsBalances[walletId];
    if (balances == null) {
      return 0;
    }
    final balance = balances.firstWhereOrNull((balance) => balance.unit == unit);
    return balance?.amount ?? 0;
  }

  /// calculate combined balance for a specific currency
  int getCombinedBalance(String unit) {
    return _walletsBalances.values
        .expand((balances) => balances)
        .where((balance) => balance.unit == unit)
        .fold(0, (sum, balance) => sum + balance.amount);
  }

  /// get wallets that support a specific currency
  List<Wallet> getWalletsForUnit(String unit) {
    return _wallets
        .where((wallet) => wallet.supportedUnits.any((u) => u == unit))
        .toList();
  }

  Future<void> dispose() async {
    final futures = <Future>[];

    _walletsUsecaseSubscription?.cancel();

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

    _wallets.clear();
    _walletsBalances.clear();
    _walletsPendingTransactions.clear();
    _walletsRecentTransactions.clear();
    _walletBalanceStreams.clear();
    _walletPendingTransactionStreams.clear();
    _walletRecentTransactionStreams.clear();
    _subscriptions.clear();
    defaultWalletId = null;
  }

  /**
   * here unified actions like zap, rcv ln (invoice) etc.
   */

  /// todo: just as an example
  Future<void> zap({
    required String pubkey,
    required int amount,
    String? comment,
  }) {
    return _walletsOperationsRepository.zap();
  }
}
