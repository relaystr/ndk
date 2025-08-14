import '../entities/wallet/wallet.dart';
import '../entities/wallet/wallet_balance.dart';
import '../entities/wallet/wallet_transaction.dart';

abstract class WalletsRepo {
  Future<List<Wallet>> getWallets();
  Future<Wallet> getWallet(String id);
  Future<void> addWallet(Wallet account);
  Future<void> removeWallet(String id);
  Stream<List<WalletBalance>> getBalancesStream(String accountId);
  Stream<List<WalletTransaction>> getPendingTransactionsStream(
      String accountId);
  Stream<List<WalletTransaction>> getRecentTransactionsStream(String accountId);
  Stream<List<Wallet>> walletsUsecaseStream();
}
