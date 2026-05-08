import 'nip_01_event.dart';

/// Result of unwrapping a gift wrap with signature verification
class GiftWrapUnwrapResult {
  /// Whether the seal event has a valid signature
  final bool isSealSignatureValid;

  /// The seal event (kind:13) extracted from the gift wrap
  final Nip01Event seal;

  /// The rumor event extracted from the seal
  final Nip01Event rumor;

  GiftWrapUnwrapResult({
    required this.isSealSignatureValid,
    required this.seal,
    required this.rumor,
  });

  /// Whether the seal's pubkey matches the rumor's pubkey
  bool get isPubkeyMatch => seal.pubKey == rumor.pubKey;
}
