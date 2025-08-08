import 'wallet_type.dart';

/// compatitability layer for generic wallets usecase as well as storage.
/// [metadata] is used to store additional information required for the specific wallet type
abstract class Wallet {
  /// local wallet identifier
  final String id;

  final WalletType type;

  /// unit like sat, usd, etc.
  final Set<String> supportedUnits;

  /// user defined name for the wallet
  String name;

  /// metadata to store additional information for the specific wallet type
  /// e.g. for Cashu store mintUrl
  final Map<String, dynamic> metadata;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.supportedUnits,
    required this.metadata,
  });

  /// constructs the concrete wallet type based on the type string \
  /// metadata is used to provide additional information required for the wallet type
  static Wallet toWalletType({
    required String id,
    required String name,
    required String typeUnparsed,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final type = WalletType.fromValue(typeUnparsed);

    switch (type) {
      case WalletType.CASHU:
        final mintUrl = metadata['mintUrl'] as String?;
        if (mintUrl == null || mintUrl.isEmpty) {
          throw ArgumentError('CashuWallet requires metadata["mintUrl"]');
        }
        return CashuWallet(
          id: id,
          name: name,
          type: type,
          supportedUnits: supportedUnits,
          metadata: metadata,
          mintUrl: mintUrl,
        );
      case WalletType.NWC:
        final nwcUrl = metadata['nwcUrl'] as String?;
        if (nwcUrl == null || nwcUrl.isEmpty) {
          throw ArgumentError('NwcWallet requires metadata["nwcUrl"]');
        }
        return NwcWallet(
          id: id,
          name: name,
          type: type,
          supportedUnits: supportedUnits,
          metadata: metadata,
          nwcUrl: nwcUrl,
        );
    }
  }
}

class CashuWallet extends Wallet {
  final String mintUrl;

  CashuWallet({
    required super.id,
    required super.name,
    super.type = WalletType.CASHU,
    required super.supportedUnits,
    required this.mintUrl,
    Map<String, dynamic>? metadata,
  }) : super(
          /// update metadata to include mintUrl
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'mintUrl': mintUrl,
          }),
        );
}

class NwcWallet extends Wallet {
  final String nwcUrl;

  NwcWallet({
    required super.id,
    required super.name,
    super.type = WalletType.NWC,
    required super.supportedUnits,
    required this.nwcUrl,
    Map<String, dynamic>? metadata,
  }) : super(
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'nwcUrl': nwcUrl,
          }),
        );
}
