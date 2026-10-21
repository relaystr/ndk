import 'package:ndk/domain_layer/entities/nip_01_event.dart';

/// auth event to send to relays
class AuthEvent extends Nip01Event {
  /// auth kind
  // ignore: constant_identifier_names
  static const int KIND = 22242;

  AuthEvent({required super.pubKey, required super.tags})
    : super(kind: KIND, content: '', sig: null, validSig: null);
}
