import 'package:ndk/entities.dart';
import 'package:ndk/shared/nips/nip25/reactions.dart';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() async {
  group('broadcast', () {
    KeyPair key0 = Bip340.generatePrivateKey();

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5098);
      await relay0.startServer(nip65s: {
        key0: Nip65(
            pubKey: key0.publicKey,
            relays: {relay0.url: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000)
      });

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay0.url],
        ignoreRelays: [],
      );

      ndk = Ndk(config);

      cache.saveUserRelayList(UserRelayList.fromNip65(Nip65(
          pubKey: key0.publicKey,
          relays: {relay0.url: ReadWriteMarker.readWrite},
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000)));
      await ndk.relays.seedRelaysConnected;
    });

    tearDown(() async {
      await ndk.destroy();
      await relay0.stopServer();
    });

    test('broadcast 2 events', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "");

      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: key0.privateKey!,
      );
      await ndk.broadcast
          .broadcast(nostrEvent: signedEvent)
          .broadcastDoneFuture;

      List<Nip01Event> result = await ndk.requests
          .query(
            filter: Filter(
              authors: [key0.publicKey],
              kinds: [Nip01Event.kTextNodeKind],
            ),
          )
          .future;
      expect(result.length, 1);

      final event2 = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "my content");

      final signedEvent2 = Nip01Utils.signWithPrivateKey(
        event: event2,
        privateKey: key0.privateKey!,
      );
      await ndk.broadcast
          .broadcast(nostrEvent: signedEvent2)
          .broadcastDoneFuture;

      result = await ndk.requests
          .query(
            filter: Filter(
              authors: [key0.publicKey],
              kinds: [Nip01Event.kTextNodeKind],
            ),
          )
          .future;
      expect(result.length, 2);
    });

    test('broadcast deletion', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "");

      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: key0.privateKey!,
      );
      NdkBroadcastResponse response =
          ndk.broadcast.broadcast(nostrEvent: signedEvent);
      await response.broadcastDoneFuture;

      List<Nip01Event> list = await ndk.requests
          .query(
            filter: Filter(
              authors: [signedEvent.pubKey],
              kinds: [Nip01Event.kTextNodeKind],
            ),
          )
          .future;
      expect(list.first, signedEvent);

      response = ndk.broadcast.broadcastDeletion(eventId: signedEvent.id);
      await response.broadcastDoneFuture;

      list = await ndk.requests
          .query(
            filter: Filter(
              authors: [signedEvent.pubKey],
              kinds: [Nip01Event.kTextNodeKind],
            ),
          )
          .future;
      expect(list, isEmpty);
    });

    test('broadcast deletion 2', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event1 = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "1");

      final signedEvent1 = Nip01Utils.signWithPrivateKey(
        event: event1,
        privateKey: key0.privateKey!,
      );
      Nip01Event event2 = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "2");

      final signedEvent2 = Nip01Utils.signWithPrivateKey(
        event: event2,
        privateKey: key0.privateKey!,
      );
      NdkBroadcastResponse response1 =
          ndk.broadcast.broadcast(nostrEvent: signedEvent1);
      await response1.broadcastDoneFuture;
      NdkBroadcastResponse response2 =
          ndk.broadcast.broadcast(nostrEvent: signedEvent2);
      await response2.broadcastDoneFuture;

      List<Nip01Event> list = await ndk.requests
          .query(
              filter: Filter(
            authors: [signedEvent1.pubKey],
            kinds: [Nip01Event.kTextNodeKind],
          ))
          .future;

      response1 = ndk.broadcast
          .broadcastDeletion(eventIds: [signedEvent1.id, signedEvent2.id]);
      await response1.broadcastDoneFuture;

      list = await ndk.requests
          .query(
            filter: Filter(
              authors: [signedEvent1.pubKey],
              kinds: [Nip01Event.kTextNodeKind],
            ),
          )
          .future;
      expect(list, isEmpty);
    });

    test('broadcast reaction', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      Nip01Event event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "");

      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: key0.privateKey!,
      );

      NdkBroadcastResponse response =
          ndk.broadcast.broadcast(nostrEvent: signedEvent);
      await response.broadcastDoneFuture;

      List<Nip01Event> list = await ndk.requests
          .query(
            filter: Filter(
              authors: [signedEvent.pubKey],
              kinds: [Nip01Event.kTextNodeKind],
            ),
          )
          .future;
      expect(list.first, signedEvent);

      final reaction = "♡";
      response = ndk.broadcast
          .broadcastReaction(eventId: signedEvent.id, reaction: reaction);
      await response.broadcastDoneFuture;

      list = await ndk.requests
          .query(
            filter: Filter(
              authors: [signedEvent.pubKey],
              kinds: [Reaction.kKind],
            ),
          )
          .future;
      expect(list.first.content, reaction);
    });

    test('broadcast deletion with empty eventIds throws ArgumentError',
        () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      expect(
        () => ndk.broadcast.broadcastDeletion(eventIds: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('broadcast respects timeout parameter', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);

      // Create a slow relay that won't respond in time
      MockRelay slowRelay = MockRelay(name: "slow relay", explicitPort: 5099);
      await slowRelay.startServer(
        nip65s: {
          key0: Nip65(
              pubKey: key0.publicKey,
              relays: {slowRelay.url: ReadWriteMarker.readWrite},
              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000)
        },
        delayResponse:
            const Duration(seconds: 2), // Add delay to simulate slow relay
      );

      try {
        // Create and broadcast an event with a short timeout
        Nip01Event event = Nip01Event(
            pubKey: key0.publicKey,
            kind: Nip01Event.kTextNodeKind,
            tags: [],
            content: "testing timeout");

        final signedEvent = Nip01Utils.signWithPrivateKey(
          event: event,
          privateKey: key0.privateKey!,
        );

        final startTime = DateTime.now();
        final customTimeout = const Duration(milliseconds: 500);

        NdkBroadcastResponse response = ndk.broadcast.broadcast(
            nostrEvent: signedEvent,
            timeout: customTimeout,
            specificRelays: [slowRelay.url, relay0.url],
            considerDonePercent: 1);

        await response.broadcastDoneFuture;
        final endTime = DateTime.now();

        // Verify that the broadcast completed within the timeout period (with some margin)
        final duration = endTime.difference(startTime);
        expect(
            duration,
            lessThanOrEqualTo(
                customTimeout + const Duration(milliseconds: 600)));

        // Verify the event was published to at least one relay (the fast one)
        List<Nip01Event> result = await ndk.requests
            .query(
              filter: Filter(
                authors: [key0.publicKey],
                kinds: [Nip01Event.kTextNodeKind],
                search: "testing timeout",
              ),
            )
            .future;
        expect(result.length, 1);
      } finally {
        await slowRelay.stopServer();
      }
    });

    test('broadcast respects considerDonePercent parameter', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);

      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5099);
      MockRelay relay2 = MockRelay(name: "relay 2", explicitPort: 5100);

      await relay1.startServer(nip65s: {
        key0: Nip65(
            pubKey: key0.publicKey,
            relays: {relay1.url: ReadWriteMarker.readWrite},
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000)
      });

      await relay2.startServer(
        nip65s: {
          key0: Nip65(
              pubKey: key0.publicKey,
              relays: {relay2.url: ReadWriteMarker.readWrite},
              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000)
        },
        delayResponse: const Duration(seconds: 2), // Add delay to the second
      );

      try {
        // Create and broadcast an event with considerDonePercent set to 66%
        // This means it should complete after 2 of the 3 relays receive the event
        Nip01Event event = Nip01Event(
            pubKey: key0.publicKey,
            kind: Nip01Event.kTextNodeKind,
            tags: [],
            content: "testing considerDonePercent");

        final signedEvent = Nip01Utils.signWithPrivateKey(
          event: event,
          privateKey: key0.privateKey!,
        );

        final startTime = DateTime.now();

        NdkBroadcastResponse response = ndk.broadcast.broadcast(
            nostrEvent: signedEvent,
            considerDonePercent: 0.66, // 66% = 2 out of 3 relays
            timeout: const Duration(
                seconds: 5), // Long timeout to ensure it's not timing out
            specificRelays: [relay0.url, relay1.url, relay2.url]);

        await response.broadcastDoneFuture;
        final endTime = DateTime.now();

        // Verify that the broadcast completed after 2 relays received it but before the slow relay finished
        // It should take less than 2 seconds (the delay of the slow relay)
        final duration = endTime.difference(startTime);
        expect(duration, lessThan(const Duration(seconds: 2)));

        final myResponse = await response.broadcastDoneFuture;

        final successRate = myResponse
            .map((e) => e.broadcastSuccessful)
            .toList()
            .where((e) => e == true);

        // Verify the success rate in the response
        expect(successRate.length / 3, closeTo(0.66, 0.01));

        // Verify the event was published to at least the two fast relays
        await Future.delayed(const Duration(
            milliseconds: 100)); // Small delay to ensure events are indexed
      } finally {
        await relay1.stopServer();
        await relay2.stopServer();
      }
    });

    test('broadcast saves event to cache by default', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);

      Nip01Event event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "test cache save");

      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: key0.privateKey!,
      );

      await ndk.broadcast
          .broadcast(nostrEvent: signedEvent)
          .broadcastDoneFuture;

      // Verify event is saved in cache
      final cachedEvent = await ndk.config.cache.loadEvent(signedEvent.id);
      expect(cachedEvent, isNotNull);
      expect(cachedEvent!.id, signedEvent.id);
      expect(cachedEvent.content, "test cache save");
    });

    test('broadcast does not save to cache when saveToCache is false',
        () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);

      Nip01Event event = Nip01Event(
          pubKey: key0.publicKey,
          kind: Nip01Event.kTextNodeKind,
          tags: [],
          content: "test no cache save");

      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: key0.privateKey!,
      );

      await ndk.broadcast
          .broadcast(nostrEvent: signedEvent, saveToCache: false)
          .broadcastDoneFuture;

      // Verify event is NOT saved in cache
      final cachedEvent = await ndk.config.cache.loadEvent(signedEvent.id);
      expect(cachedEvent, isNull);
    });

    // NIP-09 Compliance Tests

    test('broadcastDeletion with event generates e and k tags (NIP-09)',
        () async {
      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );

      Nip01Event textNote = Nip01Event(
        pubKey: key0.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: [],
        content: "test event for NIP-09 deletion",
      );

      await ndk.broadcast
          .broadcastDeletion(event: textNote)
          .broadcastDoneFuture;

      List<Nip01Event> deletionEvents = await ndk.config.cache
          .loadEvents(kinds: [5], pubKeys: [key0.publicKey]);

      expect(deletionEvents.length, 1);
      final deletionEvent = deletionEvents.first;

      final eTags =
          deletionEvent.tags.where((t) => t.length >= 2 && t[0] == 'e');
      expect(eTags.length, 1);
      expect(eTags.first[1], textNote.id);

      final kTags =
          deletionEvent.tags.where((t) => t.length >= 2 && t[0] == 'k');
      expect(kTags.length, 1);
      expect(kTags.first[1], Nip01Event.kTextNodeKind.toString());
    });

    test(
        'broadcastDeletion with eventAndAllVersions generates e, a, and k tags',
        () async {
      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );

      const articleKind = 30023;
      Nip01Event article = Nip01Event(
        pubKey: key0.publicKey,
        kind: articleKind,
        tags: [
          ["d", "my-article-identifier"]
        ],
        content: "article content",
      );

      await ndk.broadcast
          .broadcastDeletion(eventAndAllVersions: article)
          .broadcastDoneFuture;

      List<Nip01Event> deletionEvents = await ndk.config.cache
          .loadEvents(kinds: [5], pubKeys: [key0.publicKey]);

      expect(deletionEvents.length, 1);
      final deletionEvent = deletionEvents.first;

      final eTags =
          deletionEvent.tags.where((t) => t.length >= 2 && t[0] == 'e');
      expect(eTags.length, 1);
      expect(eTags.first[1], article.id);

      final aTags =
          deletionEvent.tags.where((t) => t.length >= 2 && t[0] == 'a');
      expect(aTags.length, 1);
      expect(aTags.first[1],
          "$articleKind:${key0.publicKey}:my-article-identifier");

      final kTags =
          deletionEvent.tags.where((t) => t.length >= 2 && t[0] == 'k');
      expect(kTags.length, 1);
      expect(kTags.first[1], articleKind.toString());
    });

    test('broadcastDeletion with eventId generates only e tag', () async {
      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );

      await ndk.broadcast
          .broadcastDeletion(eventId: "abc123")
          .broadcastDoneFuture;

      List<Nip01Event> deletionEvents = await ndk.config.cache
          .loadEvents(kinds: [5], pubKeys: [key0.publicKey]);

      expect(deletionEvents.length, 1);
      final deletionEvent = deletionEvents.first;

      final eTags =
          deletionEvent.tags.where((t) => t.length >= 2 && t[0] == 'e');
      expect(eTags.length, 1);
      expect(eTags.first[1], "abc123");

      final kTags =
          deletionEvent.tags.where((t) => t.length >= 2 && t[0] == 'k');
      expect(kTags.length, 0);
    });

    test(
        'broadcastDeletion with eventAndAllVersions removes all versions from cache',
        () async {
      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );

      const articleKind = 30023;
      final dTag = "my-article-${DateTime.now().millisecondsSinceEpoch}";

      // Create multiple versions of the same replaceable event
      Nip01Event version1 = Nip01Event(
        pubKey: key0.publicKey,
        kind: articleKind,
        tags: [
          ["d", dTag]
        ],
        content: "version 1",
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 100,
      );

      Nip01Event version2 = Nip01Event(
        pubKey: key0.publicKey,
        kind: articleKind,
        tags: [
          ["d", dTag]
        ],
        content: "version 2",
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 50,
      );

      Nip01Event version3 = Nip01Event(
        pubKey: key0.publicKey,
        kind: articleKind,
        tags: [
          ["d", dTag]
        ],
        content: "version 3",
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      // Save all versions to cache
      await ndk.config.cache.saveEvent(version1);
      await ndk.config.cache.saveEvent(version2);
      await ndk.config.cache.saveEvent(version3);

      // Verify all versions are in cache
      List<Nip01Event> cachedBefore = await ndk.config.cache.loadEvents(
        kinds: [articleKind],
        pubKeys: [key0.publicKey],
        tags: {
          'd': [dTag]
        },
      );
      expect(cachedBefore.length, 3);

      // Delete using eventAndAllVersions
      await ndk.broadcast
          .broadcastDeletion(eventAndAllVersions: version3)
          .broadcastDoneFuture;

      // Wait for cache removal (fire and forget async operation)
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify ALL versions are removed from cache
      List<Nip01Event> cachedAfter = await ndk.config.cache.loadEvents(
        kinds: [articleKind],
        pubKeys: [key0.publicKey],
        tags: {
          'd': [dTag]
        },
      );
      expect(cachedAfter.length, 0);
    });

    test('broadcastDeletion with multiple events generates correct tags',
        () async {
      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );

      Nip01Event textNote = Nip01Event(
        pubKey: key0.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: [],
        content: "text note",
      );

      Nip01Event repost = Nip01Event(
        pubKey: key0.publicKey,
        kind: 6,
        tags: [],
        content: "repost",
      );

      await ndk.broadcast
          .broadcastDeletion(events: [textNote, repost]).broadcastDoneFuture;

      List<Nip01Event> deletionEvents = await ndk.config.cache
          .loadEvents(kinds: [5], pubKeys: [key0.publicKey]);

      expect(deletionEvents.length, 1);
      final deletionEvent = deletionEvents.first;

      final eTags = deletionEvent.tags
          .where((t) => t.length >= 2 && t[0] == 'e')
          .toList();
      expect(eTags.length, 2);
      expect(eTags.map((t) => t[1]).toSet(), {textNote.id, repost.id});

      final kTags = deletionEvent.tags
          .where((t) => t.length >= 2 && t[0] == 'k')
          .toList();
      expect(kTags.length, 2);
      expect(kTags.map((t) => t[1]).toSet(), {'1', '6'});
    });
  });
}
