import 'wallet_type.dart';

/// Lightning payment protocols a wallet can use for internal transfers.
enum WalletPaymentProtocol { bolt11, bolt12 }

/// Base interface for all wallet types
/// Provides common properties and methods that all wallets must implement
abstract class Wallet {
  /// Local wallet identifier
  final String id;

  /// The type of wallet (NWC, Cashu, etc.)
  final WalletType type;

  /// Supported currency units (sat, usd, etc.)
  final Set<String> supportedUnits;

  /// User-defined name for the wallet
  String name;

  /// Metadata for storing wallet-specific information
  /// e.g., mintUrl for Cashu, nwcUrl for NWC
  final Map<String, dynamic> metadata;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.supportedUnits,
    required this.metadata,
  });

  /// Converts wallet data to metadata map for storage
  /// Each implementation must define how it serializes to metadata
  Map<String, dynamic> toMetadata();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Indicates if the wallet can receive funds
  bool get canReceive;

  /// Indicates if the wallet can send funds
  bool get canSend;

  /// Payment protocols this wallet can send.
  ///
  /// Wallets keep BOLT11 as the compatibility default. Wallet types with
  /// richer or dynamic capabilities should override this getter.
  Set<WalletPaymentProtocol> get sendPaymentProtocols => canSend
      ? const {WalletPaymentProtocol.bolt11}
      : const <WalletPaymentProtocol>{};

  /// Payment protocols this wallet can receive.
  Set<WalletPaymentProtocol> get receivePaymentProtocols => canReceive
      ? const {WalletPaymentProtocol.bolt11}
      : const <WalletPaymentProtocol>{};

  /// Whether this wallet can use the NWC-321/BIP-321 `pay` operation.
  bool get supportsBip321Pay => false;

  /// Whether this wallet can use the NWC-321/BIP-321 `receive` operation.
  bool get supportsBip321Receive => false;

  /// Whether this wallet can directly pay a BOLT11 invoice.
  bool get supportsBolt11InvoicePay => canSend;

  /// Whether this wallet can directly create a BOLT11 invoice.
  bool get supportsBolt11InvoiceReceive => canReceive;
}
