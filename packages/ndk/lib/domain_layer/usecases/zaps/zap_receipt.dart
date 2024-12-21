import 'package:ndk/domain_layer/entities/nip_01_event.dart';

class ZapReceipt extends Nip01Event {

  static const int KIND = 9735;

  ZapReceipt(
      {required super.pubKey, required super.tags, required super.content})
      : super(kind: KIND);
}