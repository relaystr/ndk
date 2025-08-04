import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// Proposal for a unified wallet system that can handle multiple account types (NWC, Cashu).
class Wallet {
  List<WalletAccount> accounts;
  BehaviorSubject<List<Transaction>> latestTransactions;

  /// Private subject to control the balances stream.
  final BehaviorSubject<Map<String, int>> _balancesSubject =
      BehaviorSubject<Map<String, int>>.seeded({});

  final Map<String, StreamSubscription> _balanceSubscriptions = {};

  /// Public-facing stream of combined balances, grouped by currency.
  ValueStream<Map<String, int>> get balances => _balancesSubject.stream;

  int latestTransactionCount;
  String defaultAccountId = '';

  WalletAccount? get defaultAccount {
    if (defaultAccountId.isEmpty) {
      return null;
    }
    return accounts.firstWhere((account) => account.id == defaultAccountId);
  }

  Wallet({
    required this.accounts,
    required this.latestTransactions,
    this.latestTransactionCount = 10,
  }) {
    for (final account in accounts) {
      _subscribeToAccountBalance(account);
    }
    _recalculateAndEmitBalances();
  }

  void _subscribeToAccountBalance(WalletAccount account) {
    // Ensure there's no existing subscription for this account
    _balanceSubscriptions[account.id]?.cancel();

    _balanceSubscriptions[account.id] = account.balance.listen((_) {
      _recalculateAndEmitBalances();
    });
  }

  /// Recalculates the total balance for each currency and emits an update.
  void _recalculateAndEmitBalances() {
    final newBalances = <String, int>{};
    for (final account in accounts) {
      // Use the latest value from the account's balance BehaviorSubject
      final currentBalance = account.balance.value;

      newBalances.update(
        account.unit,
        (existingTotal) => existingTotal + currentBalance,
        ifAbsent: () => currentBalance,
      );
    }
    _balancesSubject.add(newBalances);
  }

  void addAccount(WalletAccount account) {
    accounts.add(account);
    if (defaultAccountId.isEmpty) {
      defaultAccountId = account.id;
    }
    _subscribeToAccountBalance(account);
    _recalculateAndEmitBalances();
  }

  void removeAccount(String accountId) {
    accounts.removeWhere((account) => account.id == accountId);

    _balanceSubscriptions[accountId]?.cancel();
    _balanceSubscriptions.remove(accountId);
    if (defaultAccountId == accountId) {
      defaultAccountId = accounts.isNotEmpty ? accounts.first.id : '';
    }
    _recalculateAndEmitBalances();
  }

  void setDefaultAccount(String accountId) {
    if (accounts.any((account) => account.id == accountId)) {
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

/// generic wallet account interface
/// This interface allows for different types of wallet accounts (e.g., NWC, Cashu) to be used interchangeably.
abstract class WalletAccount<T> {
  /// local wallet identifier
  String id;

  AccountType type;

  /// unit like sat, usd, etc.
  String unit;

  /// user defined name for the account
  String name;

  /// the actual account object, e.g., NWC or Cashu wallet
  T account;

  WalletAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    required this.account,
  });

  /// stream of the latest transactions for this account
  BehaviorSubject<List<Transaction>> latestTransactions({int count = 10});

  /// stream of the current balance for this account
  /// BehaviorSubject to allow for immediate access to the current balance.
  BehaviorSubject<int> get balance;

  /// stream of pending transactions for this account
  BehaviorSubject<List<PendingTransaction>> get pendingTransactions;
}

enum AccountType {
  // ignore: constant_identifier_names
  NWC('nwc'),
  // ignore: constant_identifier_names
  CASHU('cashu');

  final String value;

  const AccountType(this.value);

  factory AccountType.fromValue(String value) {
    return AccountType.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Invalid event kind value: $value'),
    );
  }
}

abstract class Transaction {
  String id;
  String accountId;
  int changeAmount;
  String unit;
  AccountType accountType;
  TransactionState state;

  Transaction({
    required this.id,
    required this.accountId,
    required this.changeAmount,
    required this.unit,
    required this.accountType,
    required this.state,
  });
}

abstract class SettledTransaction<T> extends Transaction {
  /// Date in milliseconds since epoch
  int transactionDate;
  T? details;

  SettledTransaction({
    required this.transactionDate,
    this.details,
    required super.id,
    required super.accountId,
    required super.unit,
    required super.accountType,
    required super.state,
    required super.changeAmount,
  });
}

abstract class PendingTransaction<T, Z> extends Transaction {
  /// Date in milliseconds since epoch
  int initiatedDate;

  /// Optional details about the pending transaction, e.g., objects by NWC or cashu
  T? details;

  /// Actions that can be performed on this transaction, e.g., approve, reject
  Z? actions;

  PendingTransaction({
    required this.initiatedDate,
    this.details,
    this.actions,
    required super.id,
    required super.accountId,
    required super.changeAmount,
    required super.unit,
    required super.accountType,
    required super.state,
  });
}

enum TransactionState {
  draft('DRAFT'),
  canceled('CANCELED'),
  pending('PENDING'),
  completed('COMPLETED'),
  failed('FAILED');

  final String value;

  const TransactionState(this.value);

  factory TransactionState.fromValue(String value) {
    return TransactionState.values.firstWhere(
      (state) => state.value == value,
      orElse: () =>
          throw ArgumentError('Invalid pending transaction state: $value'),
    );
  }
}
