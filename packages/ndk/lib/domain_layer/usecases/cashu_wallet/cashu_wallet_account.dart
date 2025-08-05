import 'package:rxdart/rxdart.dart';

import '../../../shared/logger/logger.dart';
import '../../repositories/cache_manager.dart';
import '../wallet/wallet.dart';
import 'cashu_wallet.dart';

class CashuWalletAccount implements WalletAccount {
  @override
  final String id;

  @override
  String name;

  @override
  final WalletAccountType type;

  @override
  final String unit;

  final String mintUrl;

  final CacheManager _cacheManager;

  final List<Transaction> _latestTransactions = [];

  BehaviorSubject<List<Transaction>>? _latestTransactionsSubject;

  final Set<CashuTransaction> _pendingTransactions = {};
  BehaviorSubject<List<CashuTransaction>> pendingTransactionsSubject =
      BehaviorSubject<List<CashuTransaction>>.seeded([]);

  BehaviorSubject<int>? _balanceSubject;

  final CashuWallet cashuWallet;

  CashuWalletAccount({
    required this.id,
    required this.name,
    this.type = WalletAccountType.CASHU,
    required this.unit,
    required this.mintUrl,
    required CacheManager cacheManager,
    required this.cashuWallet,
  }) : _cacheManager = cacheManager;

  @override
  BehaviorSubject<int> get balance {
    if (_balanceSubject == null) {
      _balanceSubject = BehaviorSubject<int>.seeded(0);
      updateBalance();
    }

    return _balanceSubject!;
  }

  Future<int> _getBalanceDb() async {
    return await cashuWallet.getBalance(unit: unit, mintUrl: mintUrl);
  }

  Future<void> updateBalance() async {
    final balance = await _getBalanceDb();
    _balanceSubject?.add(balance);
  }

  Future<List<Transaction>> _getLatestTransactionsDb({int limit = 10}) async {
    final transactions = await _cacheManager.getTransactions(
      accountId: id,
      unit: unit,
      limit: limit,
    );

    return transactions;
  }

  @override
  BehaviorSubject<List<Transaction>> latestTransactions({int count = 10}) {
    if (_latestTransactionsSubject == null) {
      _latestTransactionsSubject =
          BehaviorSubject<List<Transaction>>.seeded([]);

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
  BehaviorSubject<List<CashuTransaction>> get pendingTransactions =>
      pendingTransactionsSubject;

  /// initiate funding the account
  Future<CashuTransaction> initiateFund({
    required int amount,
    String method = 'bolt11',
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
  Future<CashuTransaction> retriveFunds({
    required CashuTransaction draftTransaction,
  }) async {
    final transactionStream = cashuWallet.retriveFunds(
      draftTransaction: draftTransaction,
    );

    final subscription = transactionStream.listen(
      (data) {
        _pendingTransactions.add(data);
        pendingTransactionsSubject.add(_pendingTransactions.toList());
      },
      onDone: () {
        _pendingTransactions.remove(draftTransaction);
        pendingTransactionsSubject.add(_pendingTransactions.toList());
      },
      onError: (error) {
        _pendingTransactions.remove(draftTransaction);
        pendingTransactionsSubject.add(_pendingTransactions.toList());
        throw error;
      },
    );

    final stateList = await transactionStream.toList();
    _latestTransactions.add(stateList.last);
    _latestTransactionsSubject?.add(_latestTransactions);
    subscription.cancel();
    return stateList.last;
  }
}
