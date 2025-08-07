import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../entities/wallet/wallet_balance.dart';
import '../../entities/wallet/wallet_transaction.dart';
import '../../repositories/wallets_operations_repo.dart';
import '../../repositories/wallets_repo.dart';
import '../../entities/wallet/wallet.dart';

/// Proposal for a unified wallet system that can handle multiple wallet types (NWC, Cashu).
class Wallets {
  final WalletsRepo _walletsRepository;
  final WalletsOperationsRepo _walletsOperationsRepository;

  int latestTransactionCount;

  String defaultWalletId = '';

  /// in memory storage
  final Set<Wallet> _wallets = {};
  final Map<String, List<WalletBalance>> _walletsBalances = {};
  final Map<String, List<WalletTransaction>> _walletsPendingTransactions = {};
  final Map<String, List<WalletTransaction>> _walletsRecentTransactions = {};

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
      _walletPendingStreams = {};

  final Map<String, BehaviorSubject<List<WalletTransaction>>>
      _walletRecentStreams = {};

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

  Wallet? get defaultWallet {
    if (defaultWalletId.isEmpty) {
      return null;
    }
    return _wallets.firstWhere((wallet) => wallet.id == defaultWalletId);
  }

  Future<void> _initializeWallet() async {
    // load wallets from repository
    final wallets = await _walletsRepository.getWallets();

    for (final wallet in wallets) {
      await _addWalletToMemory(wallet);
    }

    _updateCombinedStreams();
  }

  void _ensureWalletStreamExists(String walletId) {
    _walletBalanceStreams[walletId] ??= BehaviorSubject<List<WalletBalance>>();
    _walletPendingStreams[walletId] ??=
        BehaviorSubject<List<WalletTransaction>>();
    _walletRecentStreams[walletId] ??=
        BehaviorSubject<List<WalletTransaction>>();
  }

  void _updateCombinedStreams() {
    // combine all wallet balances
    final newBalances = <String, int>{};
    for (final wallet in _wallets) {
      final walletBalances = wallet.balances.value;
      for (final entry in walletBalances.entries) {
        newBalances[entry.key] = (newBalances[entry.key] ?? 0) + entry.value;
      }
    }
    _combinedBalancesSubject.add(newBalances.entries
        .map((entry) => WalletBalance(
              unit: entry.key,
              amount: entry.value,
              walletId: '',
            ))
        .toList());

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

    // initialize empty data collections
    _walletsBalances[wallet.id] = [];
    _walletsPendingTransactions[wallet.id] = [];
    _walletsRecentTransactions[wallet.id] = [];

    // create individual streams if they don't exist
    _ensureWalletStreamExists(wallet.id);

    // subscribe to repository streams and update in memory data
    final subscriptions = <StreamSubscription>[];

    // balance stream
    subscriptions
        .add(_walletsRepository.getBalancesStream(wallet.id).listen((balances) {
      _walletsBalances[wallet.id] = balances;
      _walletBalanceStreams[wallet.id]?.add(balances);
      _updateCombinedStreams();
    }));

    // pending transactions stream
    subscriptions.add(_walletsRepository
        .getPendingTransactionsStream(wallet.id)
        .listen((transactions) {
      _walletsPendingTransactions[wallet.id] = transactions;
      _walletPendingStreams[wallet.id]?.add(transactions);
      _updateCombinedStreams();
    }));

    // recent transactions stream
    subscriptions.add(_walletsRepository
        .getRecentTransactionsStream(wallet.id)
        .listen((transactions) {
      _walletsRecentTransactions[wallet.id] = transactions;
      _walletRecentStreams[wallet.id]?.add(transactions);
      _updateCombinedStreams();
    }));

    _subscriptions[wallet.id] = subscriptions;
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
    _walletPendingStreams[walletId]?.close();
    _walletRecentStreams[walletId]?.close();

    _walletBalanceStreams.remove(walletId);
    _walletPendingStreams.remove(walletId);
    _walletRecentStreams.remove(walletId);

    // clean up subscriptions
    _subscriptions[walletId]?.forEach((sub) => sub.cancel());
    _subscriptions.remove(walletId);

    _updateCombinedStreams();
  }

  /// set the default wallet to use by common operations \

  void setDefaultWallet(String walletId) {
    if (_wallets.any((wallet) => wallet.id == walletId)) {
      defaultWalletId = walletId;
    } else {
      throw ArgumentError('Wallet with id $walletId does not exist.');
    }
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

  void dispose() {
    // cancel all subscriptions
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }

    // close all streams
    _combinedBalancesSubject.close();
    _combinedPendingTransactionsSubject.close();
    _combinedRecentTransactionsSubject.close();

    for (final stream in _walletBalanceStreams.values) {
      stream.close();
    }
    for (final stream in _walletPendingStreams.values) {
      stream.close();
    }
    for (final stream in _walletRecentStreams.values) {
      stream.close();
    }
  }

  /**
   * here unified actions like zap, rcv ln (invoice) etc.
   */

  /// todo: just as an example
  Future<void> zap() {
    return _walletsOperationsRepository.zap();
  }
}
