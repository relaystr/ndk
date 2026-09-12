import '../../wallet.dart';
import '../../wallet_type.dart';

/// Wallet backed by an LNbits instance and wallet Admin Key.
class LnBitsWallet extends Wallet {
  static const String urlMetadataKey = 'lnbitsUrl';
  static const String adminKeyMetadataKey = 'adminKey';
  static const String remoteWalletIdMetadataKey = 'remoteWalletId';

  final String lnbitsUrl;
  final String adminKey;
  final String? remoteWalletId;

  LnBitsWallet({
    required super.id,
    required super.name,
    super.type = WalletType.LNBITS,
    required super.supportedUnits,
    required this.lnbitsUrl,
    required this.adminKey,
    this.remoteWalletId,
    Map<String, dynamic>? metadata,
  }) : super(
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            urlMetadataKey: lnbitsUrl,
            adminKeyMetadataKey: adminKey,
            if (remoteWalletId != null)
              remoteWalletIdMetadataKey: remoteWalletId,
          }),
        );

  @override
  bool get canReceive => true;

  @override
  bool get canSend => true;

  @override
  Map<String, dynamic> toMetadata() => metadata;

  static LnBitsWallet fromStorage({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final url = metadata[urlMetadataKey] as String?;
    final adminKey = metadata[adminKeyMetadataKey] as String?;
    if (url == null || url.isEmpty) {
      throw ArgumentError(
          'LNbits storage requires metadata["$urlMetadataKey"]');
    }
    if (adminKey == null || adminKey.isEmpty) {
      throw ArgumentError(
        'LNbits storage requires metadata["$adminKeyMetadataKey"]',
      );
    }
    return LnBitsWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      lnbitsUrl: url,
      adminKey: adminKey,
      remoteWalletId: metadata[remoteWalletIdMetadataKey] as String?,
      metadata: metadata,
    );
  }
}
