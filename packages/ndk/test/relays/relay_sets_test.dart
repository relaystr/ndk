// ignore_for_file: avoid_print

import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() async {
  KeyPair key1 = Bip340.generatePrivateKey();
  KeyPair key2 = Bip340.generatePrivateKey();
  KeyPair key3 = Bip340.generatePrivateKey();
  KeyPair key4 = Bip340.generatePrivateKey();

  Map<KeyPair, String> keyNames = {
    key1: "key1",
    key2: "key2",
    key3: "key3",
    key4: "key4",
  };

  Nip01Event textNote(KeyPair key2) {
    return Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key2.publicKey,
        content: "some note from key ${keyNames[key2]}",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};
  Map<KeyPair, Nip01Event> key2TextNotes = {key2: textNote(key2)};
  Map<KeyPair, Nip01Event> key3TextNotes = {key3: textNote(key3)};
  Map<KeyPair, Nip01Event> key4TextNotes = {key4: textNote(key4)};

  group('Request Manager', () {
    test('Request text note', () async {
      MockRelay relay1 = MockRelay(name: "relay 1");
      await relay1.startServer(textNotes: key1TextNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      ));

      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      Filter filter =
          Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey]);

      NdkResponse query = ndk.requests.query(filters: [filter]);

      await expectLater(query.stream, emitsInAnyOrder(key1TextNotes.values));

      await relay1.stopServer();
      await ndk.destroy();
    });
  });

  group("Calculate best relays (internal MOCKs)", () {
    /// key1 reads and writes to relay 1,2,3 & 4, has its notes on all those relays
    /// key2 reads and writes to relay 1 & 2, has its notes on both relays
    /// key3 reads and writes to relay 1, has its notes ONLY on relay 1
    /// key4 reads and writes ONLY to relay 4, has its notes ONLY on relay 4

    MockRelay relay1 = MockRelay(name: "relay 1");
    MockRelay relay2 = MockRelay(name: "relay 2");
    MockRelay relay3 = MockRelay(name: "relay 3");
    MockRelay relay4 = MockRelay(name: "relay 4");

    Map<String, String> relayNames = {
      relay1.url: relay1.name,
      relay2.url: relay2.name,
      relay3.url: relay3.name,
      relay4.url: relay4.name,
    };
    Nip65 nip65ForKey1 = Nip65.fromMap(key1.publicKey, {
      relay1.url: ReadWriteMarker.readWrite,
      relay2.url: ReadWriteMarker.readWrite,
      relay3.url: ReadWriteMarker.readWrite,
      relay4.url: ReadWriteMarker.readWrite,
    });
    Nip65 nip65ForKey2 = Nip65.fromMap(key2.publicKey, {
      relay1.url: ReadWriteMarker.readWrite,
      relay2.url: ReadWriteMarker.readWrite,
    });
    Nip65 nip65ForKey3 =
        Nip65.fromMap(key3.publicKey, {relay1.url: ReadWriteMarker.readWrite});
    Nip65 nip65ForKey4 =
        Nip65.fromMap(key4.publicKey, {relay4.url: ReadWriteMarker.readWrite});

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
      // r4 -> k1,k4
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
        relay4.startServer(textNotes: key4TextNotes..addAll(key1TextNotes))
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

    setUp(() async {
      await startServers();
    });

    tearDown(() async {
      await stopServers();
    });

    // // ================================================================================================
    // test('loadMissingRelayListsFromNip65OrNip02', () async {
    //   GlobalState globalState = GlobalState();
    //   RelaySetsEngine manager = RelaySetsEngine(
    //       globalState: globalState,
    //       relayManager: RelayManager(
    //         bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url],
    //         globalState: globalState,
    //         nostrTransportFactory: webSocketNostrTransportFactory,
    //       ));
    //
    //   await manager.loadMissingRelayListsFromNip65OrNip02([key4.publicKey]);
    //
    //   UserRelayList? userRelayList =
    //       manager.cacheManager.loadUserRelayList(key4.publicKey);
    //   await expectLater(userRelayList!.relays.isEmpty, false);
    // });

    // ================================================================================================
    test('query events from key that writes only on one relay', () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      RelaySet relaySet = await ndk.relaySets.calculateRelaySet(
        name: "test",
        ownerPubKey: "test",
        pubKeys: [key4.publicKey],
        direction: RelayDirection.outbox,
        relayMinCountPerPubKey: 2,
      );

      NdkResponse query = ndk.requests.query(filters: [
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key4.publicKey])
      ], relaySet: relaySet);

      await for (final event in query.stream.take(4)) {
        await expectLater(event.sources, [relay4.url]);
        await expectLater(event, key4TextNotes[key4]);
        // print(event);
      }
      await ndk.destroy();
    });

    // ================================================================================================
    // test('query events from key that writes only on one relay (JIT)', () async {
    //   JitEngine manager = JitEngine(
    //     seedRelays: [relay1.url, relay2.url, relay3.url, relay4.url],
    //   );
    //   EventVerifier eventVerifier = MockEventVerifier();
    //
    //   NostrRequestJit myquery = NostrRequestJit.query(
    //     "test",
    //     eventVerifier: eventVerifier,
    //     filters: [
    //       Filter(kinds: [
    //         Nip01Event.kTextNodeKind
    //       ], authors: [
    //         key4.publicKey,
    //       ]),
    //     ],
    //     desiredCoverage: 1,
    //   );
    //   manager.handleRequest(
    //     myquery,
    //   );
    //   await for (final event in myquery.responseStream.take(4)) {
    //     expect(event.sources, [relay4.url]);
    //     expect(event, key4TextNotes[key4]);
    //     // print(event);
    //   }
    // });

    // ================================================================================================
    test(
        // skip: 'WiP',
        'query all keys and do not use redundant relays', () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url],
      ));

      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      /// query text notes for all keys, should discover where each key keeps its notes (according to nip65) and return all notes
      /// only relay 1,2 & 4 should be used, since relay 3 keys are all also kept on relay 1 so should not be needed
      RelaySet relaySet = await ndk.relaySets.calculateRelaySet(
          name: "feed",
          ownerPubKey: "ownerPubKey",
          pubKeys: [
            key1.publicKey,
            key2.publicKey,
            key3.publicKey,
            key4.publicKey
          ],
          direction: RelayDirection.outbox,
          relayMinCountPerPubKey: 1,
          onProgress: (stepName, count, total) {
            if (count % 100 == 0 || (total - count) < 10) {
              print("[PROGRESS] $stepName: $count/$total");
            }
          });
      print("BEST ${relaySet.relaysMap.length} RELAYS:");
      relaySet.relaysMap.forEach((url, pubKeyMappings) {
        print("  ${relayNames[url]} => has ${pubKeyMappings.length} follows");
      });
      NdkResponse query = ndk.requests.query(filters: [
        Filter(kinds: [
          Nip01Event.kTextNodeKind
        ], authors: [
          key1.publicKey,
        ]),
        Filter(kinds: [
          Nip01Event.kTextNodeKind
        ], authors: [
          key2.publicKey,
        ]),
        Filter(kinds: [
          Nip01Event.kTextNodeKind
        ], authors: [
          key3.publicKey,
        ]),
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key4.publicKey])
      ], relaySet: relaySet);

      await for (final event in query.stream) {
        print(event);
        if (event.sources.contains(relay3.url)) {
          fail("should not use relay 3 (${relay3.url}) in gossip model");
        }
      }

      /// todo: how to ALSO check if actually all notes are returned in the stream?
      //List<Nip01Event> expectedAllNotes = [...key1TextNotes.values, ...key2TextNotes.values, ...key3TextNotes.values, ...key4TextNotes.values];
      //expect(query, emitsInAnyOrder(key1TextNotes.values));
      await ndk.destroy();
    });

    // ================================================================================================
    // test(skip: true, 'query all keys and do not use redundant relays (JIT)',
    //     () async {
    //   JitEngine manager = JitEngine(
    //     seedRelays: [relay1.url, relay2.url, relay3.url, relay4.url],
    //   );
    //   EventVerifier eventVerifier = MockEventVerifier();
    //
    //   /// query text notes for all keys, should discover where each key keeps its notes (according to nip65) and return all notes
    //   /// only relay 1,2 & 4 should be used, since relay 3 keys are all also kept on relay 1 so should not be needed
    //
    //   NostrRequestJit myquery = NostrRequestJit.query(
    //     "feed",
    //     eventVerifier: eventVerifier,
    //     filters: [
    //       Filter(kinds: [
    //         Nip01Event.kTextNodeKind
    //       ], authors: [
    //         key1.publicKey,
    //         key2.publicKey,
    //         key3.publicKey,
    //         key4.publicKey
    //       ]),
    //     ],
    //     desiredCoverage: 1,
    //   );
    //   manager.handleRequest(
    //     myquery,
    //   );
    //   await for (final event in myquery.responseStream) {
    //     print(event);
    //     if (event.sources.contains(relay3.url)) {
    //       fail("should not use relay 3 (${relay3.url}) in gossip model");
    //     }
    //   }
    //
    //   /// todo: how to ALSO check if actually all notes are returned in the stream?
    //   //List<Nip01Event> expectedAllNotes = [...key1TextNotes.values, ...key2TextNotes.values, ...key3TextNotes.values, ...key4TextNotes.values];
    //   //expect(query, emitsInAnyOrder(key1TextNotes.values));
    // });

    test(
        "calculate best relays for relayMinCountPerPubKey=1 and check that it doesn't use redundant relays",
        () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url],
      ));

      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      // relayMinCountPerPubKey: 1
      RelaySet relaySet = await ndk.relaySets.calculateRelaySet(
          name: "feed",
          ownerPubKey: "ownerPubKey",
          pubKeys: [
            key1.publicKey,
            key2.publicKey,
            key3.publicKey,
            key4.publicKey
          ],
          direction: RelayDirection.outbox,
          relayMinCountPerPubKey: 1,
          onProgress: (stepName, count, total) {
            if (count % 100 == 0 || (total - count) < 10) {
              print("[PROGRESS] $stepName: $count/$total");
            }
          });
      print("BEST ${relaySet.relaysMap.length} RELAYS:");
      relaySet.relaysMap.forEach((url, pubKeyMappings) {
        print("  $url => has ${pubKeyMappings.length} follows");
      });

      expect(relaySet.urls.contains(relay1.url), true);
      expect(relaySet.urls.contains(relay2.url), false);
      expect(relaySet.urls.contains(relay3.url), false);
      expect(relaySet.urls.contains(relay4.url), true);
      expect(relaySet.notCoveredPubkeys.isEmpty, true);
      await ndk.destroy();
    });

    test(
        "calculate best relays for relayMinCountPerPubKey=2 and check that it doesn't use redundant relays",
        () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url, relay2.url, relay3.url, relay4.url],
      ));

      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      RelaySet relaySet = await ndk.relaySets.calculateRelaySet(
          name: "feed",
          ownerPubKey: "ownerPubKey",
          pubKeys: [
            key1.publicKey,
            key2.publicKey,
            key3.publicKey,
            key4.publicKey
          ],
          direction: RelayDirection.outbox,
          relayMinCountPerPubKey: 2,
          onProgress: (stepName, count, total) {
            if (count % 100 == 0 || (total - count) < 10) {
              print("[PROGRESS] $stepName: $count/$total");
            }
          });
      print("BEST ${relaySet.relaysMap.length} RELAYS:");
      relaySet.relaysMap.forEach((url, pubKeyMappings) {
        print("  $url => has ${pubKeyMappings.length} follows");
      });

      expect(relaySet.urls.contains(relay1.url), true);
      expect(relaySet.urls.contains(relay2.url), true);
      expect(relaySet.urls.contains(relay3.url), false);
      expect(relaySet.urls.contains(relay4.url), true);
      await ndk.destroy();
    });
  });

  group("Calculate best relays (external REAL)", skip: true, () {
// ================================================================================================
// REAL EXTERNAL RELAYS FOR SOME NPUBS
// ================================================================================================
    calculateBestRelaysForNpubContactsFeed(String npub,
        {String? expectedRelayUrl,
        int iterations = 1,
        required int relayMinCountPerPubKey}) async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
      ));

      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      int i = 1;
      while (i <= iterations) {
        final t0 = DateTime.now();

        KeyPair key = KeyPair.justPublicKey(Helpers.decodeBech32(npub)[0]);

        ContactList? contactList =
            await ndk.follows.getContactList(key.publicKey);

        expect(contactList != null, true);

        String setName = "feed,$relayMinCountPerPubKey,";
        RelaySet? bestRelays = await ndk.relaySets.calculateRelaySet(
            name: "feed",
            ownerPubKey: key.publicKey,
            pubKeys: contactList!.contacts,
            direction: RelayDirection.outbox,
            relayMinCountPerPubKey: relayMinCountPerPubKey,
            onProgress: (stepName, count, total) {
              if (count % 100 == 0 || (total - count) < 10) {
                print("[PROGRESS] $stepName: $count/$total");
              }
            });
        bestRelays.name = setName;
        bestRelays.pubKey = key.publicKey;
//          await manager.saveRelaySet(bestRelays);
        print(
            "BEST ${bestRelays.relaysMap.length} RELAYS (min $relayMinCountPerPubKey per pubKey):");
        bestRelays.relaysMap.forEach((url, pubKeyMappings) {
          print(
              "  $url ${pubKeyMappings.length} follows ${pubKeyMappings.length <= 2 ? pubKeyMappings : ""}");
        });

        if (Helpers.isNotBlank(expectedRelayUrl)) {
          expect(bestRelays.urls.contains(expectedRelayUrl), true);
        }
        final t1 = DateTime.now();
        print(
            "===== run #$i, time took ${t1.difference(t0).inMilliseconds} ms");
        i++;
        await ndk.destroy();
      }
    }

    // test('test fmar.link', () async {
    //   RelayManager relayManager = RelayManager();
    //   // String relay = "wss://nostr.fmar.link";
    //   await relayManager.connect();
    //   KeyPair key = KeyPair.justPublicKey(Helpers.decodeBech32("npub1xpuz4qerklyck9evtg40wgrthq5rce2mumwuuygnxcg6q02lz9ms275ams")[0]);
    //
    //   String pubKey = "48e7d9b7813958c13679ac82971211a3be9031015a2248bb041fb74652a1ddd7";
    //   var filter = Filter(
    //       kinds: [1],
    //       authors: [
    //         pubKey
    //       ]);
    //   ContactList? contactList = await relayManager.loadContactList(key.publicKey);
    //
    //   expect(contactList != null, true);
    //
    //   RelaySet? bestRelays = await relayManager.calculateRelaySet(
    //         name: "feed",
    //         ownerPubKey: key.publicKey,
    //         pubKeys: contactList!.contacts,
    //         direction: RelayDirection.outbox,
    //         relayMinCountPerPubKey: 1);
    //   await for (final event in (await relayManager.subscription(filter, bestRelays)).stream)  {
    //     print(event);
    //   }
    //   // await Future<void>.delayed(const Duration(seconds: 10));
    // }, timeout: const Timeout.factor(10));
    //
    test('Leo feed best relays', () async {
      await calculateBestRelaysForNpubContactsFeed(
          "npub1w9llyw8c3qnn7h27u3msjlet8xyjz5phdycr5rz335r2j5hj5a0qvs3tur",
          iterations: 1,
          relayMinCountPerPubKey: 2);
    }, timeout: const Timeout.factor(10));

    test('Fmar feed best relays', () async {
      await calculateBestRelaysForNpubContactsFeed(
          "npub1xpuz4qerklyck9evtg40wgrthq5rce2mumwuuygnxcg6q02lz9ms275ams",
          iterations: 1,
          relayMinCountPerPubKey: 2);
    }, timeout: const Timeout.factor(10));

    test('mikedilger feed best relays', () async {
      await calculateBestRelaysForNpubContactsFeed(
          "npub1acg6thl5psv62405rljzkj8spesceyfz2c32udakc2ak0dmvfeyse9p35c",
          iterations: 1,
          relayMinCountPerPubKey: 2);
    }, timeout: const Timeout.factor(10));

    test('Fiatjaf feed best relays', () async {
      await calculateBestRelaysForNpubContactsFeed(
          "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6",
          iterations: 1,
          relayMinCountPerPubKey: 2);
    }, timeout: const Timeout.factor(10));

    test('Love is Bitcoin (3k follows) feed best relays', () async {
      await calculateBestRelaysForNpubContactsFeed(
          "npub1kwcatqynqmry9d78a8cpe7d882wu3vmrgcmhvdsayhwqjf7mp25qpqf3xx",
          iterations: 1,
          relayMinCountPerPubKey: 2);
    }, timeout: const Timeout.factor(10));
  });
// test('testing not timing out on subscriptions', () async {
//   RelayManager manager = RelayManager();
//   await manager.init();
//   await manager.connect();
//   KeyPair key = KeyPair.justPublicKey(Helpers.decodeBech32(
//       // "npub1cd32tje2tyhcnm3mwen2hwcghs0vfyupcxjd9aff9e64rhgu755qa9wt08"
//           "npub1xpuz4qerklyck9evtg40wgrthq5rce2mumwuuygnxcg6q02lz9ms275ams"
//   )[0]);
//   // Map<String, List<PubkeyMapping>> bestRelays =
//   // await manager.calculateBestRelaysForPubKeyMappings(
//   //     [PubkeyMapping(pubKey: key.publicKey, rwMarker: ReadWriteMarker.readWrite)],
//   //     relayMinCountPerPubKey: 1
//   // );
//   // print(
//   //     "BEST ${bestRelays.length} RELAYS (min 1 per pubKey):");
//   // bestRelays.forEach((url, pubKeys) {
//   //   print("  $url ${pubKeys.length} follows");
//   // });
//   Nip02ContactList? contactList =
//       await manager.loadContactList(key.publicKey);
//
//   if (contactList != null) {
//     print(
//         "Have contact list with ${contactList.contacts.length} contacts");
//     Stream<Nip01Event> query = await manager.subscriptionWithCalculation(
//         Filter(
//             kinds: [Nip01Event.textNoteKind],
//             authors: contactList.contacts),
//         relayMinCountPerPubKey: 2);
//     // Stream<Nip01Event> query = await manager.subscription(
//     //     Filter(
//     //         kinds: [Nip01Event.textNoteKind],
//     //         authors: [key.publicKey]));
//     //
//     await for (final event in query) {
//      print(event);
//     }
//   }
// }, timeout: const Timeout.factor(10));
}
