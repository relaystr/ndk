import 'dart:async';

import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/nips/nip01/bip340.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip02/metadata.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:async/async.dart' show StreamGroup;

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

  Nip01Event textNote(KeyPair key2) {
    return Nip01Event(
        kind: Nip01Event.textNoteKind,
        pubKey: key2.publicKey,
        content: "some note from key ${key2.publicKey}",
        tags: []);
  }

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

  group("Calculate best relays (internal MOCKs)", () {
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

      Stream<Nip01Event> query = await manager.query(
          Filter(kinds: [Nip01Event.textNoteKind], authors: [key4.publicKey]));
      await for (final event in query.take(4)) {
        print(event);
      }
//      expect(query, emitsInAnyOrder(key4TextNotes.values));

      await stopServers();
    });

    // ================================================================================================

    test(
        // skip: 'WiP',
        'query all keys and do not use redundant relays', () async {
      await startServers();
      RelayManager manager = RelayManager();
      await manager.connect(
          bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url]);

      /// query text notes for all keys, should discover where each key keeps its notes (according to nip65) and return all notes
      /// only relay 1, 3 & 4 should be used, since relay 2 keys are all also kept on relay 1 so should not be needed
      Stream<Nip01Event> query = await manager.query(
          Filter(kinds: [
            Nip01Event.textNoteKind
          ], authors: [
            key1.publicKey,
            key2.publicKey,
            key3.publicKey,
            key4.publicKey
          ]),
          relayMinCountPerPubKey: 1);

      await for (final event in query) {
        print(event);
        if (event.sources.contains(relay2.url)) {
          fail("should not use relay 2 (${relay2.url}) in gossip model");
        }
        if (event.sources.contains(relay3.url)) {
          fail("should not use relay 3 (${relay3.url}) in gossip model");
        }
      }

      /// todo: how to ALSO check if actually all notes are returned in the stream?
      //List<Nip01Event> expectedAllNotes = [...key1TextNotes.values, ...key2TextNotes.values, ...key3TextNotes.values, ...key4TextNotes.values];
      //expect(query, emitsInAnyOrder(key1TextNotes.values));

      await stopServers();
    });

    test("calculate best relays and check that it doesn't use redundant relays",
        () async {
      await startServers();
      RelayManager manager = RelayManager();
      await manager.connect(
          bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url]);

      // relayMinCountPerPubKey: 1
      Map<String, List<PubkeyMapping>> bestRelays = await manager
          .calculateBestRelaysForPubKeyMappings(
              [key1.publicKey, key2.publicKey, key3.publicKey, key4.publicKey]
                  .map((pubKey) => PubkeyMapping(
                      pubKey: pubKey, rwMarker: ReadWriteMarker.readWrite))
                  .toList(),
              relayMinCountPerPubKey: 1, onProgress: (stepName, count, total) {
        if (count % 100 == 0 || (total - count) < 10) {
          print("[PROGRESS] $stepName: $count/$total");
        }
      });
      print("BEST ${bestRelays.length} RELAYS:");
      bestRelays.forEach((url, pubKeys) {
        print("  $url ${pubKeys.length} follows");
      });

      expect(bestRelays.containsKey(relay1.url), true);
      expect(bestRelays.containsKey(relay2.url), false);
      expect(bestRelays.containsKey(relay3.url), false);
      expect(bestRelays.containsKey(relay4.url), true);

      // relayMinCountPerPubKey: 2
      bestRelays = await manager.calculateBestRelaysForPubKeyMappings(
          [key1.publicKey, key2.publicKey, key3.publicKey, key4.publicKey]
              .map((pubKey) => PubkeyMapping(
                  pubKey: pubKey, rwMarker: ReadWriteMarker.readWrite))
              .toList(),
          relayMinCountPerPubKey: 2, onProgress: (stepName, count, total) {
        if (count % 100 == 0 || (total - count) < 10) {
          print("[PROGRESS] $stepName: $count/$total");
        }
      });
      print("BEST ${bestRelays.length} RELAYS:");
      bestRelays.forEach((url, pubKeys) {
        print("  $url ${pubKeys.length} follows");
      });

      expect(bestRelays.containsKey(relay1.url), true);
      expect(bestRelays.containsKey(relay2.url), true);
      expect(bestRelays.containsKey(relay3.url), false);
      expect(bestRelays.containsKey(relay4.url), true);

      await stopServers();
    });
  });

  group(
      skip: true,
      "Calculate best relays (external REAL)", () {
    getFeedTextNotesForNpub(String npub, RelayManager manager,
        {int iterations = 1}) async {
      int iteration = 1;
      while (iteration <= iterations) {
        final t0 = DateTime.now();

        KeyPair key = KeyPair.justPublicKey(Helpers.decodeBech32(npub)[0]);

        Nip02ContactList? contactList =
            await manager.loadContactList(key.publicKey);

        if (contactList != null) {
          print(
              "Have contact list with ${contactList.contacts.length} contacts");
          Stream<Nip01Event> query = await manager.query(
              Filter(
                  kinds: [Nip01Event.textNoteKind],
                  authors: contactList.contacts,
                  limit: 10),
              relayMinCountPerPubKey: 2);
          List<Nip01Event> events = await query.toList();
          Map<String, int> eventCountsByRelay = {};
          events.forEach((event) {
            if (eventCountsByRelay[event.sources.first] == null) {
              eventCountsByRelay[event.sources.first] = 0;
            }
            eventCountsByRelay[event.sources.first] =
                eventCountsByRelay[event.sources.first]! + 1;
          });

          print(
              "Received ${events.length} text note events from ${eventCountsByRelay.length} relays");

          final t1 = DateTime.now();
          print(
              "===== iteration #$iteration, time took ${t1.difference(t0).inMilliseconds} ms");
          iteration++;
        }
      }
    }

    // ================================================================================================
    // REAL EXTERNAL RELAYS FOR SOME NPUBS
    // ================================================================================================
    _calculateBestRelaysForNpubContactsFeed(String npub,
        {String? expectedRelayUrl, int iterations = 1, required int relayMinCountPerPubKey}) async {
      RelayManager manager = RelayManager();
      await manager.connect();
      int i = 1;
      while (i <= iterations) {
        final t0 = DateTime.now();

        KeyPair key = KeyPair.justPublicKey(Helpers.decodeBech32(npub)[0]);

        Nip02ContactList? contactList =
            await manager.loadContactList(key.publicKey);

        expect(contactList != null, true);

        Map<String, List<PubkeyMapping>> bestRelays = await manager
            .calculateBestRelaysForPubKeyMappings(
                contactList!.contacts
                    .map((pubKey) => PubkeyMapping(
                        pubKey: pubKey, rwMarker: ReadWriteMarker.writeOnly))
                    .toList(),
                relayMinCountPerPubKey: relayMinCountPerPubKey,
                onProgress: (stepName, count, total) {
          if (count % 100 == 0 || (total - count) < 10) {
            print("[PROGRESS] $stepName: $count/$total");
          }
        });
        print(
            "BEST ${bestRelays.length} RELAYS (min $relayMinCountPerPubKey per pubKey):");
        bestRelays.forEach((url, pubKeys) {
          print("  $url ${pubKeys.length} follows");
        });

        if (Helpers.isNotBlank(expectedRelayUrl)) {
          expect(bestRelays.keys.contains(TEST_FMAR_RELAY_URL), true);
        }
        final t1 = DateTime.now();
        print(
            "===== run #$i, time took ${t1.difference(t0).inMilliseconds} ms");
        i++;
      }
    }

    test('Leo feed best relays', () async {
      await _calculateBestRelaysForNpubContactsFeed(
          "npub1w9llyw8c3qnn7h27u3msjlet8xyjz5phdycr5rz335r2j5hj5a0qvs3tur",
          iterations: 2,
          relayMinCountPerPubKey: 3);
    }, timeout: const Timeout.factor(10));

    test('Fmar feed best relays', () async {
      await _calculateBestRelaysForNpubContactsFeed(
          "npub1xpuz4qerklyck9evtg40wgrthq5rce2mumwuuygnxcg6q02lz9ms275ams",
          iterations: 2,
          relayMinCountPerPubKey: 3);
    }, timeout: const Timeout.factor(10));

    test('Fiatjaf feed best relays', () async {
      await _calculateBestRelaysForNpubContactsFeed(
          "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6",
          iterations: 2,
          relayMinCountPerPubKey: 2);
    }, timeout: const Timeout.factor(10));

    test('Love is Bitcoin (3k follows) feed best relays', () async {
      await _calculateBestRelaysForNpubContactsFeed(
          "npub1kwcatqynqmry9d78a8cpe7d882wu3vmrgcmhvdsayhwqjf7mp25qpqf3xx",
          iterations: 3,
          relayMinCountPerPubKey: 1);
    }, timeout: const Timeout.factor(10));

  });
}
