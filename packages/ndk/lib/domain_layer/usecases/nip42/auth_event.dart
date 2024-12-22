import 'package:ndk/domain_layer/entities/nip_01_event.dart';

class AuthEvent extends Nip01Event {
  static const int KIND = 22242;

  /// Zap Request
  AuthEvent(
      {required super.pubKey, required super.tags})
      : super(kind: KIND, content:'');

}