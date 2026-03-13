import 'package:ndk/domain_layer/entities/cashu/cashu_mint_info.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';

/// Cashu wallet implementation
/// Stores mint information and handles Cashu-specific wallet operations
class CashuWallet extends Wallet {
  final String mintUrl;
  final CashuMintInfo mintInfo;

  CashuWallet({
    required super.id,
    required super.name,
    super.type = WalletType.CASHU,
    required super.supportedUnits,
    required this.mintUrl,
    required this.mintInfo,
    Map<String, dynamic>? metadata,
  }) : super(
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'mintUrl': mintUrl,
            'mintInfo': mintInfo.toJson(),
          }),
        );

  @override
  Map<String, dynamic> toMetadata() => metadata;

  /// Factory method for deserialization from storage
  /// Creates CashuWallet from stored metadata
  static CashuWallet fromStorage({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final mintUrl = metadata['mintUrl'] as String?;
    if (mintUrl == null || mintUrl.isEmpty) {
      throw ArgumentError('CashuWallet storage requires metadata["mintUrl"]');
    }

    final mintInfoJson = metadata['mintInfo'] as Map<String, dynamic>?;
    if (mintInfoJson == null) {
      throw ArgumentError('CashuWallet storage requires metadata["mintInfo"]');
    }

    return CashuWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      mintUrl: mintUrl,
      mintInfo: CashuMintInfo.fromJson(mintInfoJson),
      metadata: metadata,
    );
  }

  @override
  bool get canReceive => true;

  @override
  bool get canSend => true;
}
