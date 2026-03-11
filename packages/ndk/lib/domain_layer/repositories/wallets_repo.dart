import '../entities/wallet/wallet.dart';
import '../entities/wallet/wallet_transaction.dart';
import '../entities/wallet/wallet_type.dart';

/// Repository for wallet storage operations
/// Thin abstraction over CacheManager for wallet persistence
abstract class WalletsRepo {
  /// Get all wallets
  Future<List<Wallet>> getWallets();

  /// Get a specific wallet by ID
  Future<Wallet> getWallet(String id);

  /// Add or update a wallet
  Future<void> addWallet(Wallet account);

  /// Remove a wallet by ID
  Future<void> removeWallet(String id);

  /// Get transactions with optional filtering
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  });

  /// Save transactions to storage
  Future<void> saveTransactions(List<WalletTransaction> transactions);
}
