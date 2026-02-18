import 'package:ndk/entities.dart';
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

  group('low level - network faster then timeout', () {
    KeyPair key1 = Bip340.generatePrivateKey();
    MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 8221);
    MockRelay relay2 = MockRelay(name: "relay 2", explicitPort: 8222);

    Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};

    const timoutMiliseconds = 10000;

    // startup and teardown
    setUp(() async {
      await relay1.startServer(textNotes: key1TextNotes);
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
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay1.url, relay2.url],
        logLevel: Logger.logLevels.error,
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
      final responseData = await response.future;

      // Stop the stopwatch
      stopwatch.stop();

      expect(responseData, isNotEmpty);

      expect(timeoutUserTriggered, isFalse);
      expect(timeoutTriggered, isFalse);

      expect(stopwatch.elapsedMilliseconds, lessThan(timoutMiliseconds));

      // ignore: avoid_print
      print(
          'low level - network faster then timeout Query took: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('query - one dead seed relay', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        bootstrapRelays: [
          relay1.url,
          relay2.url,
          'wss://dead-relay.example.com'
        ],
        logLevel: Logger.logLevels.all,
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
      final responseData = await response.future;

      // Stop the stopwatch
      stopwatch.stop();

      expect(responseData, isNotEmpty);

      expect(timeoutUserTriggered, isFalse);
      expect(timeoutTriggered, isFalse);

      expect(stopwatch.elapsedMilliseconds, lessThan(timoutMiliseconds));

      // ignore: avoid_print
      print('low level - dead relay took: ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('high level - network faster then timeout', () {
    KeyPair key1 = Bip340.generatePrivateKey();

    MockRelay relay3 = MockRelay(name: "relay 3", explicitPort: 8203);
    MockRelay relay4 = MockRelay(name: "relay 4", explicitPort: 8204);

    MockRelay relay5 = MockRelay(name: "relay 3", explicitPort: 8205);
    MockRelay relay6 = MockRelay(name: "relay 4", explicitPort: 8206);

    Nip65 nip65ForKey1 = Nip65.fromMap(key1.publicKey, {
      relay3.url: ReadWriteMarker.readWrite,
      relay5.url: ReadWriteMarker.readWrite,
      "dead-gossip-relay1.example.com": ReadWriteMarker.readWrite,
      "dead-gossip-relay2.example.com": ReadWriteMarker.readWrite,
    });

    Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};

    Map<KeyPair, Nip65> nip65s = {
      key1: nip65ForKey1,
    };

    const timoutMiliseconds = 5000;

    // startup and teardown
    setUp(() async {
      await relay3.startServer(textNotes: key1TextNotes);
      await relay4.startServer(nip65s: nip65s);
      await relay5.startServer(textNotes: key1TextNotes);
      await relay6.startServer(nip65s: nip65s);
    });

    tearDown(() async {
      await relay3.server!.close(force: true);
      await relay4.server!.close(force: true);
      await relay5.server!.close(force: true);
      await relay6.server!.close(force: true);
    });

    test('query - nip65', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay3.url, relay4.url],
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
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay3.url, relay4.url],
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
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay3.url, relay4.url],
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

    test('query - repeated - nip65 data with dead relays', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay6.url],
        logLevel: Logger.logLevels.all,
      );

      final ndk = Ndk(config);
      await ndk.relays.seedRelaysConnected;
      bool timeoutTriggered = false;
      bool timeoutUserTriggered = false;
      // Start the stopwatch
      final stopwatch = Stopwatch()..start();

      final response1 =
          ndk.userRelayLists.getSingleUserRelayList(key1.publicKey);

      // wait for completion
      final response1Data = await response1;

      expect(response1Data, isNotNull);

      final response2 = ndk.requests.query(filters: [
        Filter(
          authors: [key1.publicKey],
          kinds: [Nip01Event.kTextNodeKind],
        )
      ]);

      final responseData = await response2.future;
      expect(responseData, isNotEmpty);

      // Stop the stopwatch
      stopwatch.stop();

      expect(timeoutUserTriggered, isFalse);
      expect(timeoutTriggered, isFalse);

      expect(stopwatch.elapsedMilliseconds, lessThan(timoutMiliseconds));
    });
  });

  test('request fails fast when relay is offline', () async {
    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [],
        defaultQueryTimeout: Duration(hours: 1),
      ),
    );

    final events = await ndk.requests.query(
      filter: Filter(kinds: [1]),
      explicitRelays: ['ws://127.0.0.1:59999'],
    ).future;

    expect(events, isEmpty);
  });
}
