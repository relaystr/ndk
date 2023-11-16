import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip51/nip51.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/read_write.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nip51 relay sets', () {
    test('fromEvent', () {
      final event = Nip01Event(
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: 'pubkeyUser1',
        kind: Nip51RelaySet.CATEGORIZED_RELAY_SETS,
        content: "",
        tags: [
          ['d', 'test'],
          ['r', 'wss://example.com'],
          ['r', 'wss://example.org'],
          ['invalid'],
        ],
      );
      final nip51RelaySet = Nip51RelaySet.fromEvent(event);
      expect(['wss://example.com','wss://example.org'], nip51RelaySet.relays);

      Nip01Event toEvent = nip51RelaySet.toEvent();
      event.tags.removeLast();
      expect(event.pubKey, toEvent.pubKey);
      expect(event.content, toEvent.content);
      expect(event.kind, toEvent.kind);
      expect(event.createdAt, toEvent.createdAt);
      expect(event.tags, toEvent.tags);
    });
  });
}
