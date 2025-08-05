import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../entities/cashu/wallet_cashu_keyset.dart';
import '../../entities/cashu/wallet_cashu_quote.dart';

/// Proposal for a unified wallet system that can handle multiple account types (NWC, Cashu).
class Wallet {
  List<WalletAccount> accounts;
  BehaviorSubject<List<Transaction>> latestTransactions =
      BehaviorSubject<List<Transaction>>.seeded([]);

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
abstract class WalletAccount {
  /// local wallet identifier
  final String id;

  final WalletAccountType type;

  /// unit like sat, usd, etc.
  final String unit;

  /// user defined name for the account
  String name;

  WalletAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
  });

  /// stream of the latest transactions for this account \
  /// e.g. history, including all transactions, pending, completed, etc.
  BehaviorSubject<List<Transaction>> latestTransactions({int count = 10});

  /// stream of the current balance for this account
  /// BehaviorSubject to allow for immediate access to the current balance.
  BehaviorSubject<int> get balance;

  /// stream of pending transactions for this account \
  ///
  BehaviorSubject<List<Transaction>> get pendingTransactions;
}

enum WalletAccountType {
  // ignore: constant_identifier_names
  NWC('nwc'),
  // ignore: constant_identifier_names
  CASHU('cashu');

  final String value;

  const WalletAccountType(this.value);

  factory WalletAccountType.fromValue(String value) {
    return WalletAccountType.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Invalid event kind value: $value'),
    );
  }
}

abstract class Transaction {
  final String id;
  final String accountId;
  int changeAmount;
  String unit;
  WalletAccountType accountType;
  TransactionState state;
  String? completionMsg;

  /// Date in milliseconds since epoch
  int? transactionDate;

  /// Date in milliseconds since epoch
  int? initiatedDate;

  Transaction({
    required this.id,
    required this.accountId,
    required this.changeAmount,
    required this.unit,
    required this.accountType,
    required this.state,
    this.completionMsg,
    this.transactionDate,
    this.initiatedDate,
  });
}

class CashuTransaction extends Transaction {
  String mintUrl;
  String? note;
  WalletCashuQuote? qoute;
  String? method;
  WalletCahsuKeyset? usedKeyset;

  CashuTransaction({
    required super.id,
    required super.accountId,
    required super.changeAmount,
    required super.unit,
    required super.accountType,
    required super.state,
    required this.mintUrl,
    super.completionMsg,
    this.note,
    this.method,
    this.qoute,
    this.usedKeyset,
    super.transactionDate,
    super.initiatedDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashuTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  CashuTransaction copyWith({
    String? id,
    String? accountId,
    int? changeAmount,
    String? unit,
    WalletAccountType? accountType,
    TransactionState? state,
    String? mintUrl,
    String? note,
    String? method,
    WalletCashuQuote? qoute,
    WalletCahsuKeyset? usedKeyset,
    int? transactionDate,
    int? initiatedDate,
    String? completionMsg,
  }) {
    return CashuTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      changeAmount: changeAmount ?? this.changeAmount,
      unit: unit ?? this.unit,
      accountType: accountType ?? this.accountType,
      state: state ?? this.state,
      mintUrl: mintUrl ?? this.mintUrl,
      note: note ?? this.note,
      method: method ?? this.method,
      qoute: qoute ?? this.qoute,
      usedKeyset: usedKeyset ?? this.usedKeyset,
      transactionDate: transactionDate ?? this.transactionDate,
      initiatedDate: initiatedDate ?? this.initiatedDate,
      completionMsg: completionMsg ?? this.completionMsg,
    );
  }
}

enum TransactionState {
  /// pending states

  /// draft requires user confirmation
  draft('DRAFT'),

  /// payment is in flight
  pending('PENDING'),

  /// done states
  /// transaction went through
  completed('SUCCESS'),

  /// canceld by user - usually a canceld draft, or not sufficient funds
  canceled('CANCELED'),

  /// transaction failed
  failed('FAILED');

  bool get isPending => this == draft || this == pending;

  bool get isDone => this == completed || this == canceled || this == failed;

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
