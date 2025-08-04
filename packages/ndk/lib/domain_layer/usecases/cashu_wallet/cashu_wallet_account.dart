import 'package:rxdart/rxdart.dart';

import '../../entities/cashu/wallet_cashu_proof.dart';
import '../wallet/wallet.dart';
import 'cashu_wallet.dart';

class CashuWalletAccount implements WalletAccount {
  @override
  String id;

  @override
  String name;

  @override
  AccountType type;

  @override
  String unit;

  String mintUrl;

  CashuWalletAccount({
    required this.id,
    required this.name,
    this.type = AccountType.CASHU,
    required this.unit,
    required this.mintUrl,
  });
  @override
  // TODO: implement balance
  BehaviorSubject<int> get balance => throw UnimplementedError();

  @override
  BehaviorSubject<List<Transaction>> latestTransactions({int count = 10}) {
    // TODO: implement latestTransactions
    throw UnimplementedError();
  }

  @override
  // TODO: implement pendingTransactions
  BehaviorSubject<List<Transaction>> get pendingTransactions =>
      throw UnimplementedError();
}

/// re exports the actions by CashuWallet with account details already set
class CashuWalletAccountActions {
  final CashuWallet cashuWallet;
  final String mintUrl;
  final String unit;

  CashuWalletAccountActions({
    required this.cashuWallet,
    required this.mintUrl,
    required this.unit,
  });

  Future<List<WalletCashuProof>> fund({
    required int amount,
    String method = 'bolt11',
  }) {
    return cashuWallet.fund(
      mintUrl: mintUrl,
      amount: amount,
      unit: unit,
      method: method,
    );
  }

  Future redeem({
    required String request,
    String method = 'bolt11',
  }) {
    return cashuWallet.redeem(
      mintUrl: mintUrl,
      request: request,
      unit: unit,
      method: method,
    );
  }

  Future<List<WalletCashuProof>> spend({required int amount}) {
    return cashuWallet.spend(
      mintUrl: mintUrl,
      amount: amount,
      unit: unit,
    );
  }

  /// can be called on any Account, if the account does not exist, it will be created
  Future<List<WalletCashuProof>> receive(String token) {
    // todo: create account if it does not exist
    return cashuWallet.receive(token);
  }
}
