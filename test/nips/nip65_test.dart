import 'package:dart_ndk/nips/Nip65.dart';
import 'package:dart_ndk/nostr_event.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nip65.fromEvent', () {
    final event = NostrEvent(
      publishAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      pubKey: 'pubkeyUser1',
      kind: Nip65.kind,
      content: "",
      tags: [
        ['r', 'https://example.com', 'read'],
        ['r', 'https://example.org', 'write'],
        ['r', 'https://example.net'],
        ['invalid'],
      ],
    );
    final nip65 = Nip65.fromEvent(event);
    expect(nip65.relays, {
      'https://example.com': ReadWriteMarker(read: true),
      'https://example.org': ReadWriteMarker(write: true),
      'https://example.net': null,
    });
  });
}
