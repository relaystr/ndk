
import '../../usecases/nwc/responses/pay_invoice_response.dart';
import 'wallet.dart';
import 'wallet_balance.dart';
import 'wallet_transaction.dart';
import 'wallet_type.dart';

/// Unified interface for wallet providers
/// Combines factory pattern with wallet operations
/// Each wallet type implements this interface
abstract class WalletProvider {
  /// The wallet type this provider handles
  WalletType get type;

  /// Factory method: Creates a wallet instance from metadata
  /// Throws ArgumentError if required metadata is missing
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  });

  /// Initializes the wallet (e.g., establishes connections)
  /// Called when wallet is first loaded or activated
  /// Returns an updated wallet if initialization resulted in changes, null otherwise
  Future<Wallet?> initialize(Wallet wallet);

  /// removes the wallet (e.g., closes connections, streams)
  Future<void> removeWallet(Wallet wallet);


  /// Returns a stream of wallet balances
  /// Stream emits whenever balance changes
  Stream<List<WalletBalance>> getBalances(Wallet wallet);

  /// Returns a stream of pending transactions
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet);

  /// Returns a stream of recent/completed transactions
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet);

  /// Pays a Lightning invoice using this wallet
  /// Returns payment result with preimage and fees
  Future<PayInvoiceResponse> send(Wallet wallet, String invoice);

  /// Receive by creating a Lightning Invoice
  Future<String> receive(Wallet wallet, int amountSats);

  /// Stream of wallets discovered by this provider
  /// For auto-discovery (e.g., Cashu mints, NWC connections from events)
  Stream<List<Wallet>> get discoveredWallets;
}
