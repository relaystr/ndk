import 'package:ndk/ndk.dart';
import 'package:test/test.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

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

    MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 4140);
    MockRelay relay2 = MockRelay(name: "relay 2", explicitPort: 4141);
    MockRelay relay3 = MockRelay(name: "relay 3", explicitPort: 4142);
    MockRelay relay4 = MockRelay(name: "relay 4", explicitPort: 4143);

    final myRelayUrls = [relay1.url, relay2.url, relay3.url, relay4.url];

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

    test('test if events get replayed on concurrency requests',
        timeout: const Timeout(Duration(seconds: 3)), () async {
      Ndk ndkJit = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          eventSigner: Bip340EventSigner(
            privateKey: key1.privateKey,
            publicKey: key1.publicKey,
          ),
          cache: MemCacheManager(),
          engine: NdkEngine.JIT,
          bootstrapRelays: myRelayUrls,
        ),
      );

      final myfilter = Filter(
          kinds: [Nip01Event.TEXT_NODE_KIND],
          authors: [key1.publicKey, key2.publicKey]);

      NdkResponse response0 = ndkJit.requests.query(
        filters: [myfilter],
        desiredCoverage: 1,
      );
      await Future.delayed(Duration(milliseconds: 1));
      NdkResponse response1 = ndkJit.requests.query(
        filters: [myfilter],
        desiredCoverage: 1,
      );

      await expectLater(
          response0.stream, emitsInAnyOrder(key1TextNotes.values));

      await expectLater(
          response1.stream, emitsInAnyOrder(key1TextNotes.values));
      await ndkJit.close();

    });
  });
}
