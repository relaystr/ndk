import 'package:ndk/domain_layer/entities/nip_01_event.dart';

class ZapRequest extends Nip01Event {

  static const int KIND = 9734;

  ZapRequest({required super.pubKey, required super.kind, required super.tags, required super.content});
}