import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../entities/wallet/wallet_balance.dart';
import '../../entities/wallet/wallet_transaction.dart';
import '../../repositories/wallets_repo.dart';
import '../../entities/wallet/wallet.dart';

/// Proposal for a unified wallet system that can handle multiple account types (NWC, Cashu).
class Wallets {
  final Set<Wallet> _wallets = {};
  final List<WalletBalance> _walletsBalances = [];
  final List<WalletTransaction> _walletsPendingTransactions = [];
  final List<WalletTransaction> _walletsRecentTransactions = [];

  // Combined streams for all wallets
  final BehaviorSubject<List<WalletBalance>> _combinedBalancesSubject =
      BehaviorSubject<List<WalletBalance>>();
  final BehaviorSubject<List<WalletTransaction>>
      _combinedPendingTransactionsSubject =
      BehaviorSubject<List<WalletTransaction>>();
  final BehaviorSubject<List<WalletTransaction>>
      _combinedRecentTransactionsSubject =
      BehaviorSubject<List<WalletTransaction>>();

  // Individual account streams
  final Map<String, BehaviorSubject<List<WalletBalance>>>
      _accountBalancesSubjects = {};
  final Map<String, BehaviorSubject<List<WalletTransaction>>>
      _accountPendingTransactionsSubjects = {};
  final Map<String, BehaviorSubject<List<WalletTransaction>>>
      _accountRecentTransactionsSubjects = {};

  final WalletsRepo _walletsRepository;

  /// Private subject to control the balances stream.
  final BehaviorSubject<Map<String, int>> _balancesSubject =
      BehaviorSubject<Map<String, int>>.seeded({});

  final Map<String, StreamSubscription> _balanceSubscriptions = {};

  /// Public-facing stream of combined balances, grouped by currency.
  ValueStream<Map<String, int>> get balances => _balancesSubject.stream;

  int latestTransactionCount;
  String defaultAccountId = '';

  Wallet? get defaultAccount {
    if (defaultAccountId.isEmpty) {
      return null;
    }
    return _wallets.firstWhere((account) => account.id == defaultAccountId);
  }

  Wallets({
    required WalletsRepo walletsRepository,
    this.latestTransactionCount = 10,
  }) : _walletsRepository = walletsRepository {
    for (final account in _wallets) {
      _subscribeToAccountBalance(account);
    }
    _recalculateAndEmitBalances();
  }

  void _subscribeToAccountBalance(Wallet account) {
    // Ensure there's no existing subscription for this account
    _balanceSubscriptions[account.id]?.cancel();

    _balanceSubscriptions[account.id] = account.balances.listen((_) {
      _recalculateAndEmitBalances();
    });
  }

  /// Recalculates the total balance for each currency and emits an update.
  void _recalculateAndEmitBalances() {
    final newBalances = <String, int>{};
    for (final account in _wallets) {
      final accountBalances = account.balances.value;
      for (final entry in accountBalances.entries) {
        newBalances[entry.key] = (newBalances[entry.key] ?? 0) + entry.value;
      }
    }
    _balancesSubject.add(newBalances);
  }

  void addAccount(Wallet account) {
    _wallets.add(account);
    if (defaultAccountId.isEmpty) {
      defaultAccountId = account.id;
    }
    _subscribeToAccountBalance(account);
    _recalculateAndEmitBalances();
  }

  void removeAccount(String accountId) {
    _wallets.removeWhere((account) => account.id == accountId);

    _balanceSubscriptions[accountId]?.cancel();
    _balanceSubscriptions.remove(accountId);
    if (defaultAccountId == accountId) {
      defaultAccountId = _wallets.isNotEmpty ? _wallets.first.id : '';
    }
    _recalculateAndEmitBalances();
  }

  void setDefaultAccount(String accountId) {
    if (_wallets.any((account) => account.id == accountId)) {
      defaultAccountId = accountId;
    } else {
      throw ArgumentError('Account with id $accountId does not exist.');
    }
  }

  /// here could be unified actions like zap, rcv ln (invoice) etc.

  void dispose() {
    for (final subscription in _balanceSubscriptions.values) {
      subscription.cancel();
    }
    _balanceSubscriptions.clear();
    _balancesSubject.close();
  }
}
