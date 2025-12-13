import 'dart:convert';

import '../../domain_layer/entities/nip_01_event.dart';
import '../../domain_layer/entities/nip_01_event_raw.dart';

NostrMessageRaw decodeNostrMsg(String msgJsonStr) {
  try {
    final decoded = jsonDecode(msgJsonStr);

    if (decoded is! List || decoded.isEmpty) {
      return NostrMessageRaw(type: NostrMessageRawType.unknown);
    }

    final msgTypeStr = decoded[0];
    switch (msgTypeStr) {
      case 'NOTICE':
        return NostrMessageRaw(
            type: NostrMessageRawType.notice, otherData: decoded);
      case 'EVENT':
        if (decoded.length < 3) {
          return NostrMessageRaw(type: NostrMessageRawType.unknown);
        }
        final requestId = decoded[1];
        final eventData = decoded[2];
        final nip01Event = Nip01Event(
          id: eventData['id'],
          pubKey: eventData['pubkey'],
          createdAt: eventData['created_at'],
          kind: eventData['kind'],
          tags: (eventData['tags'] as List)
              .map((tag) => List<String>.from(tag))
              .toList(),
          content: eventData['content'],
          sig: eventData['sig'],
          validSig: null,
        );
        return NostrMessageRaw(
          type: NostrMessageRawType.event,
          nip01Event: nip01Event,
          requestId: requestId,
        );
      case 'EOSE':
        return NostrMessageRaw(
          type: NostrMessageRawType.eose,
          otherData: decoded,
        );
      case 'OK':
        return NostrMessageRaw(
            type: NostrMessageRawType.ok, otherData: decoded);
      case 'CLOSED':
        return NostrMessageRaw(
            type: NostrMessageRawType.closed, otherData: decoded);
      case 'AUTH':
        return NostrMessageRaw(
            type: NostrMessageRawType.auth, otherData: decoded);
      default:
        return NostrMessageRaw(
            type: NostrMessageRawType.unknown, otherData: decoded);
    }
  } catch (e) {
    return NostrMessageRaw(
        type: NostrMessageRawType.unknown, otherData: msgJsonStr);
  }
}
