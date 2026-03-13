import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';

/// LNURL wallet implementation for read-only/receive-only operations
/// Stores LNURL-pay endpoint configuration and generates invoices for receiving payments
class LnurlWallet extends Wallet {
  /// The identifier in user@domain.com format
  final String identifier;

  /// The resolved LNURL-pay HTTPS endpoint URL
  final String lnurlPayUrl;

  /// Cached min sendable amount in millisats (from LNURL metadata)
  final int? minSendable;

  /// Cached max sendable amount in millisats (from LNURL metadata)
  final int? maxSendable;

  /// Timestamp when metadata was last fetched (milliseconds since epoch)
  final int? metadataFetchedAt;

  LnurlWallet({
    required super.id,
    required super.name,
    super.type = WalletType.LNURL,
    required super.supportedUnits,
    required this.identifier,
    required this.lnurlPayUrl,
    this.minSendable,
    this.maxSendable,
    this.metadataFetchedAt,
    Map<String, dynamic>? metadata,
  }) : super(
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'identifier': identifier,
            'lnurlPayUrl': lnurlPayUrl,
            'minSendable': minSendable,
            'maxSendable': maxSendable,
            'metadataFetchedAt': metadataFetchedAt,
          }),
        );

  @override
  Map<String, dynamic> toMetadata() => metadata;

  /// Factory method for deserialization from storage
  /// Creates LnurlWallet from stored metadata
  static LnurlWallet fromStorage({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final identifier = metadata['identifier'] as String?;
    if (identifier == null || identifier.isEmpty) {
      throw ArgumentError(
          'LnurlWallet storage requires metadata["identifier"]');
    }

    final lnurlPayUrl = metadata['lnurlPayUrl'] as String?;
    if (lnurlPayUrl == null || lnurlPayUrl.isEmpty) {
      throw ArgumentError(
          'LnurlWallet storage requires metadata["lnurlPayUrl"]');
    }

    return LnurlWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      identifier: identifier,
      lnurlPayUrl: lnurlPayUrl,
      minSendable: metadata['minSendable'] as int?,
      maxSendable: metadata['maxSendable'] as int?,
      metadataFetchedAt: metadata['metadataFetchedAt'] as int?,
      metadata: metadata,
    );
  }

  /// Check if cached metadata is still valid (within 10 minutes)
  bool get isMetadataValid {
    if (metadataFetchedAt == null) return false;
    final tenMinutesAgo =
        DateTime.now().millisecondsSinceEpoch - (10 * 60 * 1000);
    return metadataFetchedAt! > tenMinutesAgo;
  }

  @override
  bool get canReceive => true;

  @override
  bool get canSend => false;
}
