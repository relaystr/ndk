import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nip65', ()
  {
    test('fromEvent', () {
      final event = Nip01Event(
        publishAt: DateTime
            .now()
            .millisecondsSinceEpoch ~/ 1000,
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
        'https://example.com': ReadWriteMarker.readOnly,
        'https://example.org': ReadWriteMarker.writeOnly,
        'https://example.net': ReadWriteMarker.readWrite,
      });
    });

    test('toEvent', () {
      final nip65 = Nip65({
        'https://example.com': ReadWriteMarker.readWrite,
        'https://example.org': ReadWriteMarker.readOnly,
        'https://example.net': ReadWriteMarker.writeOnly,
      });
      final myEvent = nip65.toEvent('pubkey123');
      expect(myEvent.pubKey, equals('pubkey123'));
      expect(myEvent.kind, equals(Nip65.kind));
      expect(
          myEvent.tags,
          equals([
            [
              'r',
              'https://example.com',
            ],
            ['r', 'https://example.org', 'read'],
            ['r', 'https://example.net', 'write'],
          ]));
      expect(myEvent.content, equals(''));
      expect(myEvent.createdAt, equals(nip65.createdAt));
    });
  });
}
