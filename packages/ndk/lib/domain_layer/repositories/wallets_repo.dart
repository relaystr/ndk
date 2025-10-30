import '../entities/wallet/wallet.dart';
import '../entities/wallet/wallet_balance.dart';
import '../entities/wallet/wallet_transaction.dart';
import '../entities/wallet/wallet_type.dart';

abstract class WalletsRepo {
  Future<List<Wallet>> getWallets();
  Future<Wallet> getWallet(String id);
  Future<void> addWallet(Wallet account);
  Future<void> removeWallet(String id);
  Stream<List<WalletBalance>> getBalancesStream(String accountId);
  Stream<List<WalletTransaction>> getPendingTransactionsStream(
      String accountId);
  Stream<List<WalletTransaction>> getRecentTransactionsStream(String accountId);
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  });
  Stream<List<Wallet>> walletsUsecaseStream();
}
