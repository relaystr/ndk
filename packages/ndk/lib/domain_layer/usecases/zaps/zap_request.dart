import '../../entities/nip_01_event.dart';
import '../../entities/nip_01_utils.dart';

/// Zap Request
class ZapRequest extends Nip01Event {
  static const kZapRequestKind = 9734;

  /// creates a zap request from a nip01 event \
  /// [event] the nip01 event \
  /// returns the zap request \
  /// kind is set to [kZapRequestKind]
  ZapRequest.nip01Event({
    required Nip01Event event,
  }) : super(
          pubKey: event.pubKey,
          tags: event.tags,
          content: event.content,
          id: event.id,
          sig: event.sig,
          kind: kZapRequestKind,
          validSig: event.validSig,
        );

  /// Zap Request
  ZapRequest._({
    required super.pubKey,
    required super.tags,
    required super.content,
    required super.id,
    super.sig,
  }) : super(
          kind: kZapRequestKind,
          validSig: null,
        );

  /// creates a zap request \
  /// [pubKey] the pubkey of the zap requester \
  /// [tags] the tags of the zap request \
  /// [content] the content of the zap request \
  /// [sig] the signature of the zap request (optional) \
  /// returns the zap request \
  factory ZapRequest({
    required String pubKey,
    required List<List<String>> tags,
    required String content,
    String? sig,
  }) {
    final calculatedId = Nip01Utils.calculateEventIdSync(
      pubKey: pubKey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: kZapRequestKind,
      tags: tags,
      content: content,
    );

    return ZapRequest._(
      pubKey: pubKey,
      tags: tags,
      content: content,
      id: calculatedId,
      sig: sig,
    );
  }
}
