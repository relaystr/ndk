import '../../entities/nip_01_event.dart';
import '../nip_01_event_service/nip_01_event_service.dart';

/// Zap Request
class ZapRequest extends Nip01Event {
  static const kZapRequestKind = 9734;

  /// Zap Request
  ZapRequest._({
    required super.pubKey,
    required super.tags,
    required super.content,
    required super.id,
  }) : super(
          kind: kZapRequestKind,
          sig: null,
          validSig: null,
        );

  factory ZapRequest({
    required String pubKey,
    required List<List<String>> tags,
    required String content,
  }) {
    final calculatedId = Nip01EventService.calculateEventIdSync(
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
    );
  }
}
