import 'package:ndk/ndk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'mocks/mock_event_verifier.dart';
import 'mocks/mock_relay.dart';

void main() async {
  group('repeated queries', () {
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
          kind: Nip01Event.TEXT_NODE_KIND,
          pubKey: key2.publicKey,
          content: "some note from key ${keyNames[key2]}",
          tags: [],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }

    Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};
    Map<KeyPair, Nip01Event> key2TextNotes = {key2: textNote(key2)};
    Map<KeyPair, Nip01Event> key3TextNotes = {key3: textNote(key3)};
    Map<KeyPair, Nip01Event> key4TextNotes = {key4: textNote(key4)};

    MockRelay relay1 = MockRelay(name: "relay 1");
    MockRelay relay2 = MockRelay(name: "relay 2");
    MockRelay relay3 = MockRelay(name: "relay 3");
    MockRelay relay4 = MockRelay(name: "relay 4");

    final myRelayUrls = [relay1.url, relay2.url, relay3.url, relay4.url];

    final myFilters = [
      Filter(
        kinds: [Nip01Event.TEXT_NODE_KIND],
        authors: [key1.publicKey],
      ),
      Filter(
          kinds: [Nip01Event.TEXT_NODE_KIND],
          authors: [key1.publicKey, key2.publicKey]),
      Filter(
          kinds: [Nip01Event.TEXT_NODE_KIND],
          authors: [key4.publicKey, key3.publicKey]),
      Filter(
          kinds: [Nip01Event.TEXT_NODE_KIND],
          authors: [key4.publicKey, key2.publicKey]),
      Filter(
          kinds: [Nip01Event.TEXT_NODE_KIND],
          authors: [key1.publicKey, key2.publicKey, key3.publicKey]),
      Filter(kinds: [
        Nip01Event.TEXT_NODE_KIND
      ], authors: [
        key1.publicKey,
        key2.publicKey,
        key3.publicKey,
        key4.publicKey
      ]),
    ];

    setUp(() async {
      await relay1.startServer(textNotes: key1TextNotes);
      await relay2.startServer(textNotes: key2TextNotes);
      await relay3.startServer(textNotes: key3TextNotes);
      await relay4.startServer(textNotes: key4TextNotes);
    });

    tearDown(() async {
      await relay1.stopServer();
      await relay2.stopServer();
      await relay3.stopServer();
      await relay4.stopServer();
    });

    Future<void> testNdk(Ndk myNdk) async {
      NdkResponse response0 = myNdk.requests.query(filters: [
        myFilters[0],
      ]);

      await expectLater(
          response0.stream, emitsInAnyOrder(key1TextNotes.values));

      NdkResponse response1 = myNdk.requests.query(filters: [
        myFilters[1],
      ]);

      await expectLater(response1.stream,
          emitsInAnyOrder([...key1TextNotes.values, ...key2TextNotes.values]));

      NdkResponse response2 = myNdk.requests.query(filters: [
        myFilters[2],
      ]);

      await expectLater(response2.stream,
          emitsInAnyOrder([...key3TextNotes.values, ...key4TextNotes.values]));

      NdkResponse response3 = myNdk.requests.query(filters: [
        myFilters[3],
      ]);

      await expectLater(response3.stream,
          emitsInAnyOrder([...key2TextNotes.values, ...key4TextNotes.values]));

      NdkResponse response4 = myNdk.requests.query(filters: [
        myFilters[4],
      ]);
      await expectLater(
          response4.stream,
          emitsInAnyOrder([
            ...key1TextNotes.values,
            ...key2TextNotes.values,
            ...key3TextNotes.values,
          ]));

      NdkResponse response5 = myNdk.requests.query(filters: [
        myFilters[5],
      ]);

      await expectLater(
          response5.stream,
          emitsInAnyOrder([
            ...key1TextNotes.values,
            ...key2TextNotes.values,
            ...key3TextNotes.values,
            ...key4TextNotes.values,
          ]));
    }

    test('Lists Engine', timeout: const Timeout(Duration(seconds: 3)),
        () async {
      Ndk ndkLists = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          eventSigner: Bip340EventSigner(key1.privateKey, key1.publicKey),
          cache: MemCacheManager(),
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: myRelayUrls,
        ),
      );

      await testNdk(ndkLists);
    });

    test('JIT Engine', timeout: const Timeout(Duration(seconds: 3)), () async {
      Ndk ndkJit = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          eventSigner: Bip340EventSigner(key1.privateKey, key1.publicKey),
          cache: MemCacheManager(),
          engine: NdkEngine.JIT,
          bootstrapRelays: myRelayUrls,
        ),
      );

      await testNdk(ndkJit);
    });
  });
}
