import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../nip_01_event_service/nip_01_event_service.dart';

/// auth event to send to relays
class AuthEvent extends Nip01Event {
  /// auth kind
  // ignore: constant_identifier_names
  static const int KIND = 22242;

  /// Zap Request
  AuthEvent._({
    required super.pubKey,
    required super.tags,
    required super.id,
  }) : super(
          kind: KIND,
          content: '',
          sig: null,
          validSig: null,
        );

  factory AuthEvent({
    required String pubKey,
    required List<List<String>> tags,
  }) {
    final calculatedId = Nip01EventService.calculateEventIdSync(
      pubKey: pubKey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: KIND,
      tags: tags,
      content: '',
    );

    return AuthEvent._(
      pubKey: pubKey,
      tags: tags,
      id: calculatedId,
    );
  }
}
