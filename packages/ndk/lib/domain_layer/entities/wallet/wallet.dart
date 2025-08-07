import 'wallet_type.dart';

/// generic wallet account interface
/// This interface allows for different types of wallets (e.g., NWC, Cashu) to be used interchangeably.
abstract class Wallet {
  /// local wallet identifier
  final String id;

  final WalletType type;

  /// unit like sat, usd, etc.
  final Set<String> supportedUnits;

  /// user defined name for the wallet
  String name;

  /// metadata to store additional information for the specific wallet type
  /// e.g. for Cashu store the mintUrl here
  final Map<String, dynamic> metadata;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.supportedUnits,
    required this.metadata,
  });
}
