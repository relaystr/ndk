import 'package:ndk/domain_layer/entities/nip_01_event.dart';

class ZapRequest extends Nip01Event {
  static const int KIND = 9734;

  ZapRequest(
      {required String pubKey,
      required List<List<String>> tags,
      required String content})
      : super(kind: KIND, pubKey: pubKey, tags: tags, content: content);
}
