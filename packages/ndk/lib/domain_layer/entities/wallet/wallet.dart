import 'wallet_type.dart';

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
}
