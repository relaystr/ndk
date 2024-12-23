import '../../entities/nip_01_event.dart';

/// Zap Request
class ZapRequest extends Nip01Event {
  static const int KIND = 9734;

  /// Zap Request
  ZapRequest(
      {required super.pubKey, required super.tags, required super.content})
      : super(kind: KIND);
}
