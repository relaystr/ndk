import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../../domain_layer/entities/wallet/wallet_type.dart';
import '../../../domain_layer/repositories/cache_manager.dart';
import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/usecases/cashu_wallet/cashu.dart';

class CashuWallet implements Wallet {
  @override
  final String id;

  @override
  String name;

  @override
  final WalletType type;

  @override
  final Set<String> supportedUnits;

  final String mintUrl;

  final CacheManager _cacheManager;

  final List<WalletTransaction> _latestTransactions = [];

  BehaviorSubject<List<WalletTransaction>>? _latestTransactionsSubject;

  final Set<CashuWalletTransaction> _pendingTransactions = {};
  BehaviorSubject<List<CashuWalletTransaction>> pendingTransactionsSubject =
      BehaviorSubject<List<CashuWalletTransaction>>.seeded([]);

  BehaviorSubject<Map<String, int>>? _balanceSubject;

  final Cashu cashuWallet;

  CashuWallet({
    required this.id,
    required this.name,
    this.type = WalletType.CASHU,
    required this.supportedUnits,
    required this.mintUrl,
    required CacheManager cacheManager,
    required this.cashuWallet,
  }) : _cacheManager = cacheManager;

  @override
  BehaviorSubject<Map<String, int>> get balances {
    if (_balanceSubject == null) {
      _balanceSubject = BehaviorSubject<Map<String, int>>.seeded({});
      updateBalance();
    }

    return _balanceSubject!;
  }

  Future<Map<String, int>> _getBalanceDb() async {
    final balances = <String, int>{};
    for (final unit in supportedUnits) {
      final balance = await cashuWallet.getBalance(
        unit: unit,
        mintUrl: mintUrl,
      );
      balances[unit] = balance;
    }
    return balances;
  }

  Future<void> updateBalance() async {
    final balance = await _getBalanceDb();
    _balanceSubject?.add(balance);
  }

  Future<List<WalletTransaction>> _getLatestTransactionsDb(
      {int limit = 10}) async {
    final transactions = await _cacheManager.getTransactions(
      walletId: id,
      limit: limit,
    );

    return transactions;
  }

  @override
  BehaviorSubject<List<WalletTransaction>> latestTransactions(
      {int count = 10}) {
    if (_latestTransactionsSubject == null) {
      _latestTransactionsSubject =
          BehaviorSubject<List<WalletTransaction>>.seeded([]);

      _getLatestTransactionsDb(limit: count).then((transactions) {
        _latestTransactionsSubject?.add(transactions);
        _latestTransactions.addAll(transactions);
      }).catchError((error) {
        _latestTransactionsSubject?.addError(
          Exception('Failed to load latest transactions: $error'),
        );
      });
    }

    return _latestTransactionsSubject!;
  }

  @override
  BehaviorSubject<List<CashuWalletTransaction>> get pendingTransactions =>
      pendingTransactionsSubject;

  /// initiate funding the wallet
  Future<CashuWalletTransaction> initiateFund({
    required int amount,
    String method = 'bolt11',
    String unit = 'sat',
  }) async {
    final draftTransaction = await cashuWallet.initiateFund(
      mintUrl: mintUrl,
      amount: amount,
      unit: unit,
      method: method,
    );

    // add to pending transactions
    _pendingTransactions.add(draftTransaction);
    pendingTransactionsSubject.add(_pendingTransactions.toList());

    return draftTransaction;
  }

  /// call this when you payed the invoice and want to retrieve the funds
  /// it will update the streams and return the final transaction
  Future<CashuWalletTransaction> retriveFunds({
    required CashuWalletTransaction draftTransaction,
  }) async {
    final transactionStream = cashuWallet.retriveFunds(
      draftTransaction: draftTransaction,
    );

    final List<CashuWalletTransaction> stateList = [];
    final completer = Completer<CashuWalletTransaction>();

    final subscription = transactionStream.listen(
      (data) {
        stateList.add(data);
        _pendingTransactions.add(data);
        pendingTransactionsSubject.add(_pendingTransactions.toList());
      },
      onDone: () {
        _pendingTransactions.remove(draftTransaction);
        pendingTransactionsSubject.add(_pendingTransactions.toList());

        if (stateList.isNotEmpty) {
          _latestTransactions.add(stateList.last);
          _latestTransactionsSubject?.add(_latestTransactions);
          completer.complete(stateList.last);
        } else {
          completer.completeError('No transactions received');
        }
      },
      onError: (error) {
        _pendingTransactions.remove(draftTransaction);
        pendingTransactionsSubject.add(_pendingTransactions.toList());
        completer.completeError(error);
      },
    );

    await completer.future;
    await subscription.cancel();
    await updateBalance();
    return stateList.last;
  }
}
