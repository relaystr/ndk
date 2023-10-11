import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/nips/nip01/bip340.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_relay.dart';

void main() {
  MockRelay relay1 = MockRelay();
  MockRelay relay2 = MockRelay();
  MockRelay relay3 = MockRelay();
  MockRelay relay4 = MockRelay();

  KeyPair key1 = Bip340.generatePrivateKey();
  KeyPair key2 = Bip340.generatePrivateKey();
  KeyPair key3 = Bip340.generatePrivateKey();
  KeyPair key4 = Bip340.generatePrivateKey();

  Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};
  Map<KeyPair, Nip01Event> key2TextNotes = {key2: textNote(key1)};
  Map<KeyPair, Nip01Event> key3TextNotes = {key3: textNote(key3)};
  Map<KeyPair, Nip01Event> key4TextNotes = {key4: textNote(key4)};

  group('Relay Manager', () {
    test('Connect to relay', () async {
      await relay1.startServer();
      RelayManager manager = RelayManager();
      await manager
          .connectRelay(relay1.url)
          .then((value) {})
          .onError((error, stackTrace) async {
        await relay1.stopServer();
      });
      await relay1.stopServer();
    });

    test('Try to connect to dead relay', () async {
      RelayManager manager = RelayManager();
      try {
        await manager.connectRelay(relay1.url);
        fail("should throw exception");
      } catch (e) {
        // success
      }
    });

    test('Request text note', () async {
      await relay1.startServer(textNotes: key1TextNotes);

      RelayManager manager = RelayManager();
      await manager.connect(bootstrapRelays: [relay1.url]);

      Filter filter =
          Filter(kinds: [Nip01Event.textNoteKind], authors: [key1.publicKey]);

      Stream<Nip01Event> query = manager.request(relay1.url, filter);

      expect(query, emitsInAnyOrder(key1TextNotes.values));

      await relay1.stopServer();
    });
  });

  group("Gossip/Outbox model", () {
    /// key1 reads and writes to relay 1,2 & 3, has its notes on all those relays
    /// key2 reads and writes to relay 1 & 2, has its notes on both relays
    /// key3 reads and writes to relay 1, has its notes ONLY on relay 1
    /// key4 reads and writes ONLY to relay 4, has its notes ONLY on relay 4
    Nip65 nip65ForKey1 = Nip65({
      relay1.url: ReadWriteMarker.readWrite,
      relay2.url: ReadWriteMarker.readWrite,
      relay3.url: ReadWriteMarker.readWrite
    });
    Nip65 nip65ForKey2 = Nip65({
      relay1.url: ReadWriteMarker.readWrite,
      relay2.url: ReadWriteMarker.readWrite
    });
    Nip65 nip65ForKey3 = Nip65({relay1.url: ReadWriteMarker.readWrite});
    Nip65 nip65ForKey4 = Nip65({relay4.url: ReadWriteMarker.readWrite});

    Map<KeyPair, Nip65> nip65s = {
      key1: nip65ForKey1,
      key2: nip65ForKey2,
      key3: nip65ForKey3,
      key4: nip65ForKey4,
    };

    startServers() async {
      // r1 -> k1, k2, k3
      // r2 -> k1, k2
      // r3 -> k1
      // r4 -> k4
      await Future.wait([
        relay1.startServer(
            nip65s: nip65s,
            textNotes: {}
              ..addAll(key1TextNotes)
              ..addAll(key2TextNotes)
              ..addAll(key3TextNotes)),
        relay2.startServer(
            nip65s: nip65s,
            textNotes: {}
              ..addAll(key1TextNotes)
              ..addAll(key2TextNotes)),
        relay3.startServer(
            nip65s: nip65s, textNotes: {}..addAll(key1TextNotes)),
        relay4.startServer(textNotes: key4TextNotes)
      ]);
    }

    stopServers() async {
      await Future.wait([
        relay1.stopServer(),
        relay2.stopServer(),
        relay3.stopServer(),
        relay4.stopServer(),
      ]);
    }

    // ================================================================================================

    test('query events from key that writes only on one relay', () async {
      await startServers();

      RelayManager manager = RelayManager();
      await manager.connect(
          bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url]);

      Stream<Nip01Event> query = manager.query(
          Filter(kinds: [Nip01Event.textNoteKind], authors: [key4.publicKey]));
      await for (final event in query.take(4)) {
        print(event);
      }
//      expect(query, emitsInAnyOrder(key4TextNotes.values));

      await stopServers();
    });

    // ================================================================================================

    test(
        skip: 'WiP', 'query all keys and do not use redundant relays',
        () async {
      await startServers();
      RelayManager manager = RelayManager();
      await manager.connect(
          bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url]);

      /// query text notes for all keys, should discover where each key keeps its notes (according to nip65) and return all notes
      /// only relay 1, 3 & 4 should be used, since relay 2 keys are all also kept on relay 1 so should not be needed
      Stream<Nip01Event> query = manager.subscription(Filter(kinds: [
        Nip01Event.textNoteKind
      ], authors: [
        key1.publicKey,
        key2.publicKey,
        key3.publicKey,
        key4.publicKey
      ]));

      await for (final event in query.take(4)) {
        print(event);
        if (event.sources.contains(relay2.url)) {
          fail("should not use relay 2 (${relay2.url}) in gossip model");
        }
      }
      /// todo: how to ALSO check if actually all notes are returned in the stream?
      //List<Nip01Event> expectedAllNotes = [...key1TextNotes.values, ...key2TextNotes.values, ...key3TextNotes.values, ...key4TextNotes.values];
      //expect(query, emitsInAnyOrder(key1TextNotes.values));

      await stopServers();
    });
  });
}

Nip01Event textNote(KeyPair key2) {
  return Nip01Event(
      kind: Nip01Event.textNoteKind,
      pubKey: key2.publicKey,
      content: "some note from key ${key2.publicKey}",
      tags: []);
}
