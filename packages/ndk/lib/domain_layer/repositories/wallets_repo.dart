import '../entities/wallet/wallet.dart';
import '../entities/wallet/wallet_transaction.dart';
import '../entities/wallet/wallet_type.dart';

/// Repository for wallet storage operations
/// Thin abstraction over CacheManager for wallet persistence
abstract class WalletsRepo {
  /// Get wallets by id
  /// return all if [ids] is null
  Future<List<Wallet>> getWallets({List<String>? ids});

  /// Get a specific wallet by ID
  Future<Wallet> getWallet(String id) {
    return getWallets(ids: [id]).then((wallets) {
      if (wallets.isEmpty) {
        throw Exception('Wallet with id $id not found');
      }
      return wallets.first;
    });
  }

  /// Store a wallet
  Future<void> storeWallet(Wallet account);

  /// Remove a wallet by ID
  Future<void> removeWallet(String id);

  /// Get default wallet for sending funds (e.g. for paying invoices)
  String? getDefaultWalletIdForReceiving();

  /// Get default wallet for receiving funds (e.g. for generating invoices)
  String? getDefaultWalletIdForSending();

  /// Set default wallet for receiving funds (e.g. for generating invoices)
  void setDefaultWalletForReceiving(String? walletId);

  /// Set default wallet for sending funds (e.g. for paying invoices)
  void setDefaultWalletForSending(String? walletId);

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

  /// Remove transactions by ID
  /// should only be used for deleting a wallet
  Future<void> removeTransactions(List<String>? transactionIds);
}
