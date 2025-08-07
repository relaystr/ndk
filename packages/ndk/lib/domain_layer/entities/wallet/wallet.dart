import 'package:rxdart/rxdart.dart';

import 'wallet_transaction.dart';
import 'wallet_type.dart';

/// generic wallet account interface
/// This interface allows for different types of wallets (e.g., NWC, Cashu) to be used interchangeably.
abstract class Wallet {
  /// local wallet identifier
  final String id;

  final WalletType type;

  /// unit like sat, usd, etc.
  final Set<String> supportedUnits;

  /// user defined name for the wallet
  String name;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.supportedUnits,
  });

  /// stream of the latest transactions for this wallet \
  /// e.g. history, including all transactions, pending, completed, etc.
  BehaviorSubject<List<WalletTransaction>> latestTransactions({int count = 10});

  /// stream of balances for all supported currencies
  /// Map key is the unit (e.g., 'sat', 'usd'), value is the balance
  /// BehaviorSubject to allow for immediate access to the current balance.
  BehaviorSubject<Map<String, int>> get balances;

  /// stream of pending transactions for this wallet \
  ///
  BehaviorSubject<List<WalletTransaction>> get pendingTransactions;
}
