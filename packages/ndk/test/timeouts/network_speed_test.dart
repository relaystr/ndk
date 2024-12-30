import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

/// test to check if the network is faster then the timeout (this should always be the case)
void main() {
  Nip01Event textNote(KeyPair myKey) {
    return Nip01Event(
      kind: Nip01Event.kTextNodeKind,
      pubKey: myKey.publicKey,
      content: "some note from key $myKey}",
      tags: [],
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Nip01Event nip65Note(KeyPair myKey) {
    return Nip01Event(
      kind: 10002,
      pubKey: myKey.publicKey,
      content: "",
      tags: [
        ["r", "wss://alicerelay.example.com"],
        ["r", "wss://brando-relay.com"],
        ["r", "wss://expensive-relay.example2.com", "write"],
        ["r", "wss://nostr-relay.example.com", "read"]
      ],
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  group('low level - network faster then timeout', () {
    KeyPair key1 = Bip340.generatePrivateKey();
    MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 8201);
    MockRelay relay2 = MockRelay(name: "relay 2", explicitPort: 8202);
    Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};

    const timoutMiliseconds = 5000;

    // startup and teardown
    setUp(() async {
      await relay1.startServer();
      relay1.textNotes = key1TextNotes;
      await relay2.startServer();
    });

    tearDown(() async {
      await relay1.server!.close(force: true);
      await relay2.server!.close(force: true);
    });

    test('query', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url, relay2.url],
      );

      final ndk = Ndk(config);

      bool timeoutTriggered = false;
      bool timeoutUserTriggered = false;
      // Start the stopwatch
      final stopwatch = Stopwatch()..start();

      final response = ndk.requests.query(
          filters: [
            Filter(
              authors: [key1.publicKey],
              kinds: [Nip01Event.kTextNodeKind],
            )
          ],
          timeout: Duration(milliseconds: timoutMiliseconds),
          timeoutCallback: () {
            timeoutTriggered = true;
          },
          timeoutCallbackUserFacing: () {
            timeoutUserTriggered = true;
          });

      // wait for completion
      await response.future;

      // Stop the stopwatch
      stopwatch.stop();

      expect(timeoutUserTriggered, isFalse);
      expect(timeoutTriggered, isFalse);

      expect(stopwatch.elapsedMilliseconds, lessThan(timoutMiliseconds));

      // ignore: avoid_print
      print(
          'low level - network faster then timeout Query took: ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('high level - network faster then timeout', () {
    KeyPair key1 = Bip340.generatePrivateKey();
    MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 8301);
    MockRelay relay2 = MockRelay(name: "relay 2", explicitPort: 8302);
    Map<KeyPair, Nip01Event> key1TextNotes = {key1: nip65Note(key1)};

    const timoutMiliseconds = 5000;

    // startup and teardown
    setUp(() async {
      await relay1.startServer();
      relay1.textNotes = key1TextNotes;
      await relay2.startServer();
    });

    tearDown(() async {
      await relay1.server!.close(force: true);
      await relay2.server!.close(force: true);
    });

    test('query - nip65', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url, relay2.url],
      );

      final ndk = Ndk(config);

      bool timeoutTriggered = false;
      bool timeoutUserTriggered = false;
      // Start the stopwatch
      final stopwatch = Stopwatch()..start();

      final response =
          ndk.userRelayLists.getSingleUserRelayList(key1.publicKey);

      // wait for completion
      await response;

      // Stop the stopwatch
      stopwatch.stop();

      expect(timeoutUserTriggered, isFalse);
      expect(timeoutTriggered, isFalse);

      expect(stopwatch.elapsedMilliseconds, lessThan(timoutMiliseconds));

      // ignore: avoid_print
      print(
          'high level - network faster then timeout Query took: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('query - nip65 - no data', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url, relay2.url],
      );

      final ndk = Ndk(config);

      bool timeoutTriggered = false;
      bool timeoutUserTriggered = false;
      // Start the stopwatch
      final stopwatch = Stopwatch()..start();

      final response =
          ndk.userRelayLists.getSingleUserRelayList("notExistingPubkey");

      // wait for completion
      await response;

      // Stop the stopwatch
      stopwatch.stop();

      expect(timeoutUserTriggered, isFalse);
      expect(timeoutTriggered, isFalse);

      expect(stopwatch.elapsedMilliseconds, lessThan(timoutMiliseconds));
    });

    test('query - metadata - no data', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url, relay2.url],
      );

      final ndk = Ndk(config);

      bool timeoutTriggered = false;
      bool timeoutUserTriggered = false;
      // Start the stopwatch
      final stopwatch = Stopwatch()..start();

      final response = ndk.metadata.loadMetadata("notExistingPubkey");

      // wait for completion
      await response;

      // Stop the stopwatch
      stopwatch.stop();

      expect(timeoutUserTriggered, isFalse);
      expect(timeoutTriggered, isFalse);

      expect(stopwatch.elapsedMilliseconds, lessThan(timoutMiliseconds));
    });
  });
}
