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
  group('Relay Manager', () {
    test('Connect to relay', () async {
      MockRelay mockRelay = MockRelay();
      await mockRelay.startServer();
      RelayManager manager = RelayManager();
      await manager
          .connectRelay(mockRelay.url)
          .then((value) {})
          .onError((error, stackTrace) async {
        await mockRelay.stopServer();
      });
      await mockRelay.stopServer();
    });

    test('Try to connect to dead relay', () async {
      MockRelay mockRelay1 = MockRelay();
      RelayManager manager = RelayManager();
      try {
        await manager.connectRelay(mockRelay1.url);
        fail("should throw exception");
      } catch (e) {
        // success
      }
      ;
    });

    test('Request text note', () async {
      MockRelay mockRelay1 = MockRelay();
      KeyPair key1 = Bip340.generatePrivateKey();
      Map<KeyPair, Nip01Event> key1TextNotes = { key1: textNote(key1)};
      await mockRelay1.startServer(textNotes: key1TextNotes);

      RelayManager manager = RelayManager();
      await manager.init(bootstrapRelays: [mockRelay1.url]);

      Filter filter = Filter(
          kinds: [Nip01Event.textNoteKind], authors: [key1.publicKey]);
      expect(
          manager.request(mockRelay1.url, filter),
          emitsInAnyOrder(key1TextNotes.values));
    });

    test(
        // skip: 'WiP',
        'Gossip/Outbox model', () async {
      MockRelay mockRelay1 = MockRelay();
      MockRelay mockRelay2 = MockRelay();
      MockRelay mockRelay3 = MockRelay();

      KeyPair key1 = Bip340.generatePrivateKey();
      KeyPair key2 = Bip340.generatePrivateKey();
      KeyPair key3 = Bip340.generatePrivateKey();

      Map<KeyPair, Nip01Event> key1TextNotes = { key3: textNote(key1)};
      Map<KeyPair, Nip01Event> key2TextNotes = { key3: textNote(key1)};
      Map<KeyPair, Nip01Event> key3TextNotes = { key3: textNote(key3)};

      Nip65 nip65ForKey1 = Nip65({ mockRelay1.url: ReadWriteMarker.readWrite,mockRelay2.url: ReadWriteMarker.readWrite });
      Nip65 nip65ForKey2 = Nip65({ mockRelay1.url: ReadWriteMarker.readOnly, mockRelay2.url: ReadWriteMarker.writeOnly });
      Nip65 nip65ForKey3 = Nip65({ mockRelay3.url: ReadWriteMarker.readWrite});

      Map<KeyPair, Nip65> nip65s = {
        key1: nip65ForKey1,
        key2: nip65ForKey2,
        key3: nip65ForKey3
      };

      /// key1 reads and writes to relay 1 & 2, has its notes on both relays
      /// key2 reads from relay 1 and writes to relay 2, has its notes ONLY on relay 2
      /// key3 reads and writes ONLY to relay 3, has its notes ONLY on relay 3

      await Future.wait([
        mockRelay1.startServer(nip65s: nip65s, textNotes: key1TextNotes),
        mockRelay2.startServer(
            textNotes: {}..addAll(key1TextNotes)..addAll(key2TextNotes)),
        mockRelay3.startServer(textNotes: key3TextNotes)
      ]);
      // ===============================================

      RelayManager manager = RelayManager();
      await manager.init(
          bootstrapRelays: [mockRelay1.url, mockRelay2.url, mockRelay3.url]);

      /// query text notes for all keys, should discover where each key keeps its notes (according to nip65) and return all notes
      Stream<Nip01Event> query = manager.query(Filter(
          kinds: [Nip01Event.textNoteKind],
          authors: [key1.publicKey, key2.publicKey, key3.publicKey]));

      List<Nip01Event> expectedAllNotes = []..addAll(
          key1TextNotes.values)..addAll(key2TextNotes.values)..addAll(
          key3TextNotes.values);
      expect(query, emitsInAnyOrder(expectedAllNotes));

      // ===============================================
      await Future.wait([
        mockRelay1.stopServer(),
        mockRelay2.stopServer(),
        mockRelay3.stopServer
          (
        )
      ]
      );
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
