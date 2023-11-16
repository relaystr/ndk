import 'package:dart_ndk/nips/nip01/bip340.dart';
import 'package:dart_ndk/nips/nip01/bip340_event_signer.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip51/nip51.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nip51 relay sets', () {
    test('fromEvent public', () {
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
      final nip51RelaySet = Nip51RelaySet.fromEvent(event, null);
      expect(['wss://example.com','wss://example.org'], nip51RelaySet.relays);

      Nip01Event toEvent = nip51RelaySet.toPublicEvent();
      event.tags.removeLast();
      expect(event.pubKey, toEvent.pubKey);
      expect(event.content, toEvent.content);
      expect(event.kind, toEvent.kind);
      expect(event.createdAt, toEvent.createdAt);
      expect(event.tags, toEvent.tags);
    });
    test('fromEvent private', () {
      KeyPair key1 = Bip340.generatePrivateKey();
      Bip340EventSigner signer = Bip340EventSigner(key1.privateKey, key1.publicKey);

      Nip51RelaySet relaySet = Nip51RelaySet(pubKey: key1.publicKey, name: "test", relays: ['wss://example.com','wss://example.org'], createdAt: Helpers.now);
      Nip01Event event = relaySet.toPrivateEvent(signer);
      Nip51RelaySet from = Nip51RelaySet.fromEvent(event, signer);

      expect(relaySet.relays, from.relays);
    });
  });
}
