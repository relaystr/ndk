import 'dart:core';

import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../../domain_layer/entities/wallet/wallet_type.dart';
import '../../../domain_layer/repositories/wallets_repo.dart';

class StubWalletsRepo extends WalletsRepo {

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    throw UnimplementedError("need to set a proper WalletsRepo in NdkConfig to use this method");
  }

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) {
    throw UnimplementedError("need to set a proper WalletsRepo in NdkConfig to use this method");
  }

  @override
  Future<List<Wallet>> getWallets({List<String>? ids}) {
    return Future.value([]);
  }

  @override
  Future<void> removeWallet(String id) {
    throw UnimplementedError("need to set a proper WalletsRepo in NdkConfig to use this method");
  }

  @override
  Future<void> storeWallet(Wallet wallet) {
    throw UnimplementedError("need to set a proper WalletsRepo in NdkConfig to use this method");
  }

  @override
  String? getDefaultWalletIdForReceiving() {
    throw UnimplementedError("need to set a proper WalletsRepo in NdkConfig to use this method");
  }

  @override
  String? getDefaultWalletIdForSending() {
    throw UnimplementedError("need to set a proper WalletsRepo in NdkConfig to use this method");
  }

  @override
  void setDefaultWalletForReceiving(String? walletId) {
    throw UnimplementedError("need to set a proper WalletsRepo in NdkConfig to use this method");
  }

  @override
  void setDefaultWalletForSending(String? walletId) {
    throw UnimplementedError("need to set a proper WalletsRepo in NdkConfig to use this method");
  }
}
