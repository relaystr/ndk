// ignore_for_file: avoid_print

import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/usecases/cache_read/cache_read.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/presentation_layer/init.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
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

  Map<KeyPair, Nip01Event> textNotes = {
    key1: textNote(key1),
    key2: textNote(key2)
  };

  group('Requests', () {
    test('Request text note', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);
      await relay1.startServer(textNotes: textNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final filter =
          Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey]);

      final query = ndk.requests.query(filters: [filter]);

      await expectLater(
          query.stream, emitsInAnyOrder([textNotes.values.first]));

      await ndk.destroy();
      expect(ndk.relays.globalState.inFlightRequests.isEmpty, true);
      await relay1.stopServer();
    });

    test('Request multiple filters text note', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);
      await relay1.startServer(textNotes: textNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final query = ndk.requests.query(
          // explicitRelays: [relay1.url],
          filters: [
            Filter(
                kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey]),
            Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key2.publicKey])
          ]);

      await expectLater(query.stream, emitsInAnyOrder(textNotes.values));

      // await for (final event in query.stream) {
      //   print(event);
      // }

      await ndk.destroy();
      expect(ndk.relays.globalState.inFlightRequests.isEmpty, true);
      await relay1.stopServer();
    });
    test('Request multiple filters text note JIT', skip: true, () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);
      await relay1.startServer(textNotes: textNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay1.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final query = ndk.requests.query(
          // explicitRelays: [relay1.url],
          filters: [
            Filter(
                kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey]),
            Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key2.publicKey])
          ]);

      await expectLater(query.stream, emitsInAnyOrder(textNotes.values));

      // await for (final event in query.stream) {
      //   print(event);
      // }

      await ndk.destroy();
      expect(ndk.relays.globalState.inFlightRequests.isEmpty, true);
      await relay1.stopServer();
    });

    test('Subscription processes events immediately without stream closing',
        () async {
      // This test would FAIL with the previous VerifyEventStream implementation
      // because events would remain stuck in buffer until stream closes
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);
      await relay1.startServer(textNotes: textNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final filter =
          Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey]);

      // Use subscription instead of query - this creates a long-lived stream
      final subscription = ndk.requests.subscription(filters: [filter]);

      final receivedEvents = <Nip01Event>[];
      final streamSubscription = subscription.stream.listen((event) {
        receivedEvents.add(event);
      });

      // Wait for initial events to be processed
      // Previous implementation would not yield these events from subscription
      await Future.delayed(Duration(milliseconds: 200));

      expect(receivedEvents.length, equals(1),
          reason:
              'Subscription should process events immediately without waiting for stream to close');
      expect(receivedEvents[0].content, contains('key1'));

      // Clean up
      await streamSubscription.cancel();
      await ndk.requests.closeSubscription(subscription.requestId);
      await ndk.destroy();
      expect(ndk.relays.globalState.inFlightRequests.isEmpty, true);
      await relay1.stopServer();
    });

    test('Subscription handles continuous events from non-closing stream',
        () async {
      // This test simulates a real-world scenario where a subscription
      // receives events continuously without the stream ever closing
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);

      // Start with multiple events to test continuous processing
      final multipleEvents = {
        key1: textNote(key1),
        key2: textNote(key2),
        key3: textNote(key3),
        key4: textNote(key4),
      };
      await relay1.startServer(textNotes: multipleEvents);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final filter = Filter(kinds: [
        Nip01Event.kTextNodeKind
      ], authors: [
        key1.publicKey,
        key2.publicKey,
        key3.publicKey,
        key4.publicKey
      ]);

      final subscription = ndk.requests.subscription(filters: [filter]);

      final receivedEvents = <Nip01Event>[];
      final streamSubscription = subscription.stream.listen((event) {
        receivedEvents.add(event);
      });

      // Wait for events to be processed
      // Previous implementation would fail to process events from subscription
      // because they would get stuck in the verification buffer
      await Future.delayed(Duration(milliseconds: 300));

      expect(receivedEvents.length, equals(4),
          reason:
              'Subscription should process all matching events immediately');

      // Verify we got events from different authors (showing parallel processing worked)
      final uniqueAuthors = receivedEvents.map((e) => e.pubKey).toSet();
      expect(uniqueAuthors.length, greaterThan(1),
          reason: 'Should receive events from multiple authors');

      // Clean up
      await streamSubscription.cancel();
      await ndk.requests.closeSubscription(subscription.requestId);
      await ndk.destroy();
      expect(ndk.relays.globalState.inFlightRequests.isEmpty, true);
      await relay1.stopServer();
    });
  });

  group('immutable filters', () {
    test('Filters are cloned and immutable in query method', () {
      final cache = MemCacheManager();
      final eventVerifier = MockEventVerifier();
      final globalState = GlobalState();
      final init = Initialization(
        globalState: globalState,
        ndkConfig: NdkConfig(
          eventVerifier: eventVerifier,
          cache: cache,
        ),
      );

      // Create a Requests instance
      final requests = Requests(
        defaultQueryTimeout: Duration(seconds: 10),
        globalState: globalState,
        cacheRead: MockCacheRead(cache),
        cacheWrite: init.cacheWrite,
        networkEngine: init.engine,
        relayManager: init.relayManager,
        eventVerifier: eventVerifier,
        eventOutFilters: [],
      );

      // Create an initial filter
      final originalFilter = Filter(
        kinds: [1],
        authors: ['author1'],
      );
      final originalFilterSub = Filter(
        kinds: [1],
        authors: ['author1Sub'],
      );

      //   query
      requests.query(filters: [originalFilter]);

      expect(originalFilter.authors!.length, equals(1));

      //   subscription
      requests.subscription(filters: [originalFilterSub], cacheRead: true);
      expect(originalFilterSub.authors!.length, equals(1));
    });
  });

  test('Response with FormatException', () async {
    final mockRelay = MockRelay(
      name: 'test-relay-format-exception',
      explicitPort: 6062,
      allwaysSendBadJson: true,
    );
    await mockRelay.startServer();

    final ndk = Ndk.defaultConfig();

    final query = ndk.requests.query(
      filters: [
        Filter(kinds: [1], limit: 1),
      ],
      explicitRelays: [mockRelay.url],
    );

    final events = await query.future;
    expect(events, isEmpty);

    await mockRelay.stopServer();
  });
}

class MockCacheRead extends CacheRead {
  MockCacheRead(super.cacheManager);

  @override
  Future<void> resolveUnresolvedFilters({
    required RequestState requestState,
    required StreamController<Nip01Event> outController,
  }) async {
    for (var filter in requestState.unresolvedFilters) {
      filter.authors = [];
    }
  }
}
