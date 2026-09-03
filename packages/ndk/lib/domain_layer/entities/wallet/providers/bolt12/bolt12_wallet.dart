import '../../wallet.dart';
import '../../wallet_type.dart';

/// A receive-only wallet backed by a reusable BOLT12 offer.
class Bolt12Wallet extends Wallet {
  /// Canonical, lowercase `lno...` offer.
  final String offer;

  /// The value originally entered or scanned by the user.
  final String source;

  /// BIP353 address used to resolve [offer], when applicable.
  final String? bip353Address;

  final String? description;
  final String? nodeId;
  final String? offerId;
  final String? amount;
  final String? issuer;
  final String? currency;
  final int? expiresAt;
  final int? quantityMax;
  final bool hasBlindedPaths;

  Bolt12Wallet({
    required super.id,
    required super.name,
    super.type = WalletType.BOLT12,
    required super.supportedUnits,
    required this.offer,
    required this.source,
    this.bip353Address,
    this.description,
    this.nodeId,
    this.offerId,
    this.amount,
    this.issuer,
    this.currency,
    this.expiresAt,
    this.quantityMax,
    this.hasBlindedPaths = false,
    Map<String, dynamic>? metadata,
  }) : super(
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'offer': offer,
            'source': source,
            'bip353Address': bip353Address,
            'description': description,
            'nodeId': nodeId,
            'offerId': offerId,
            'amount': amount,
            'issuer': issuer,
            'currency': currency,
            'expiresAt': expiresAt,
            'quantityMax': quantityMax,
            'hasBlindedPaths': hasBlindedPaths,
          }),
        );

  @override
  Map<String, dynamic> toMetadata() => metadata;

  static Bolt12Wallet fromStorage({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final offer = metadata['offer'] as String?;
    if (offer == null || offer.isEmpty) {
      throw ArgumentError('Bolt12Wallet storage requires metadata["offer"]');
    }

    return Bolt12Wallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      offer: offer,
      source: metadata['source'] as String? ?? offer,
      bip353Address: metadata['bip353Address'] as String?,
      description: metadata['description'] as String?,
      nodeId: metadata['nodeId'] as String?,
      offerId: metadata['offerId'] as String?,
      amount: metadata['amount']?.toString(),
      issuer: metadata['issuer'] as String?,
      currency: metadata['currency'] as String?,
      expiresAt: _readInt(metadata['expiresAt']),
      quantityMax: _readInt(metadata['quantityMax']),
      hasBlindedPaths: metadata['hasBlindedPaths'] == true,
      metadata: metadata,
    );
  }

  @override
  bool get canReceive => true;

  @override
  bool get canSend => false;

  @override
  Set<WalletPaymentProtocol> get receivePaymentProtocols => const {
        WalletPaymentProtocol.bolt12,
      };

  @override
  bool get supportsBip321Receive => true;

  @override
  bool get supportsBolt11InvoiceReceive => false;

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
