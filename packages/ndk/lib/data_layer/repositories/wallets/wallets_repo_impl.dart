import 'dart:async';

import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../../domain_layer/entities/wallet/wallet_type.dart';
import '../../../domain_layer/repositories/cache_manager.dart';
import '../../../domain_layer/repositories/wallets_repo.dart';

/// Implementation of WalletsRepo
/// Thin wrapper around CacheManager for wallet storage operations
class WalletsRepoImpl implements WalletsRepo {
  final CacheManager _cacheManager;

  WalletsRepoImpl({
    required CacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  @override
  Future<void> addWallet(Wallet wallet) {
    return _cacheManager.saveWallet(wallet);
  }

  @override
  Future<Wallet> getWallet(String id) async {
    final wallets = await _cacheManager.getWallets(ids: [id]);
    if (wallets == null || wallets.isEmpty) {
      throw Exception('Wallet with id $id not found');
    }
    return wallets.first;
  }

  @override
  Future<List<Wallet>> getWallets() async {
    final wallets = await _cacheManager.getWallets();
    if (wallets == null) {
      return [];
    }
    return wallets;
  }

  @override
  Future<void> removeWallet(String id) {
    return _cacheManager.removeWallet(id);
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    return _cacheManager.getTransactions(
      limit: limit,
      offset: offset,
      walletId: walletId,
      unit: unit,
      walletType: walletType,
    );
  }

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) {
    return _cacheManager.saveTransactions(transactions: transactions);
  }
}
