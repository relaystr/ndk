import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

/// Tests for the ephemeral-event cache policy.
///
/// Ephemeral events (NIP-01 kinds 20000-29999) are non-persistent by
/// definition. NDK enforces an asymmetric cache policy:
///
/// - **Write (inbound from relays):** disabled. Events received via queries or
///   subscriptions flow through to the caller but are never persisted to cache.
///   This prevents unbounded memory growth when processing high-volume
///   ephemeral traffic (e.g. NIP-46 bunker sessions).
///
/// - **Read:** enabled. Locally-stored ephemeral events (own broadcasts and
///   pending-delivery queue) remain discoverable by subsequent queries —
///   local-first.
///
/// - **Broadcast / pending delivery:** unchanged. The user's own ephemeral
///   events ARE saved to cache so the retry mechanism can redeliver them when
///   connectivity is restored.
void main() {
  const ephemeralKind = 21133; // NIP-46 request

  group('ephemeral cache policy', () {
    test('inbound ephemeral event via subscription is NOT written to cache '
        'even when cacheWrite is true', () async {
      final mockRelay = MockRelay(name: 'ephemeral-cache-test');
      await mockRelay.startServer();
      addTearDown(() => mockRelay.stopServer());

      final authorKey = Bip340.generatePrivateKey();
      final subscriberKey = Bip340.generatePrivateKey();
      final cache = MemCacheManager();

      final subscriberNdk = Ndk(
        NdkConfig(
          cache: cache,
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final broadcasterNdk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final receivedEvents = <Nip01Event>[];
      final completer = Completer<void>();

      // Subscribe with cacheWrite explicitly true — subscriptions default to
      // cacheWrite: false in the Requests facade, so we must opt in.
      final subscription = subscriberNdk.requests.subscription(
        filter: Filter(
          kinds: [ephemeralKind],
          pTags: [subscriberKey.publicKey],
        ),
        cacheWrite: true,
      );

      subscription.stream.listen((event) {
        receivedEvents.add(event);
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await _waitForSubscriptionCount(mockRelay, 1);

      // Broadcast a signed ephemeral event from the other client.
      final ephemeralEvent = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: ephemeralKind,
        tags: [
          ['p', subscriberKey.publicKey],
        ],
        content: 'inbound ephemeral — should not be cached',
      );
      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: ephemeralEvent,
        privateKey: authorKey.privateKey!,
      );

      await broadcasterNdk.broadcast
          .broadcast(nostrEvent: signedEvent, specificRelays: [mockRelay.url])
          .broadcastDoneFuture;

      await completer.future.timeout(const Duration(seconds: 5));

      // The subscriber received the event live.
      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.kind, equals(ephemeralKind));

      // Give cache write a moment to settle.
      await Future.delayed(const Duration(milliseconds: 200));

      // The cache must NOT contain the ephemeral event.
      final cached = cache.events.values.where((e) => e.kind == ephemeralKind);
      expect(
        cached,
        isEmpty,
        reason:
            'Inbound ephemeral events must not be persisted to cache even when '
            'cacheWrite is true.',
      );

      await subscriberNdk.destroy();
      await broadcasterNdk.destroy();
    });

    test('locally-stored ephemeral event IS returned by a query '
        '(cache read stays enabled)', () async {
      final mockRelay = MockRelay(name: 'ephemeral-read-test');
      await mockRelay.startServer();
      addTearDown(() => mockRelay.stopServer());

      final authorKey = Bip340.generatePrivateKey();
      final cache = MemCacheManager();

      final ndk = Ndk(
        NdkConfig(
          cache: cache,
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      // Manually save an ephemeral event to cache — simulates a broadcast or
      // pending-delivery event that the local-first path stored.
      final ephemeralEvent = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: ephemeralKind,
        tags: const [],
        content: 'locally stored ephemeral',
        createdAt: Nip01Event.secondsSinceEpoch(),
      );
      await cache.saveEvent(ephemeralEvent);

      // Query with cacheRead: true, cacheWrite: false.
      // The relay has no matching stored events (ephemerals are not stored by
      // relays), so the only possible source is the cache.
      final response = ndk.requests.query(
        filter: Filter(kinds: [ephemeralKind], authors: [authorKey.publicKey]),
        cacheRead: true,
        cacheWrite: false,
        explicitRelays: [mockRelay.url],
        timeout: const Duration(seconds: 3),
      );

      final results = await response.future;

      // The locally-stored ephemeral event must be returned.
      expect(
        results.map((e) => e.id),
        contains(ephemeralEvent.id),
        reason:
            'Cache read must stay enabled for ephemeral kinds so that '
            'locally-stored events (broadcasts, pending deliveries) remain '
            'discoverable by queries.',
      );

      await ndk.destroy();
    });

    test('broadcasting an ephemeral event purges it from cache once delivery '
        'is terminal (ephemeral cache is transient)', () async {
      final mockRelay = MockRelay(name: 'ephemeral-broadcast-test');
      await mockRelay.startServer();
      addTearDown(() => mockRelay.stopServer());

      final authorKey = Bip340.generatePrivateKey();
      final cache = MemCacheManager();

      final ndk = Ndk(
        NdkConfig(
          cache: cache,
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      ndk.accounts.loginPrivateKey(
        pubkey: authorKey.publicKey,
        privkey: authorKey.privateKey!,
      );

      final ephemeralEvent = Nip01Event(
        pubKey: authorKey.publicKey,
        kind: ephemeralKind,
        tags: const [],
        content: 'outgoing ephemeral — transient in cache',
      );

      // saveToCache persists the event immediately so the local-first path can
      // deliver (and retry) it while the outcome is still pending.
      await ndk.broadcast
          .broadcast(
            nostrEvent: ephemeralEvent,
            specificRelays: [mockRelay.url],
            saveToCache: true,
          )
          .broadcastDoneFuture;

      // Give the async purge a moment to settle.
      await Future.delayed(const Duration(milliseconds: 200));

      // Ephemeral events use a doNotRetry delivery policy: once a relay has
      // responded (here: acked -> delivered) there is nothing left to retry.
      // The local-first cache copy and its delivery record are dropped
      // immediately instead of lingering until a background eviction pass.
      final cached = cache.events.values.where((e) => e.kind == ephemeralKind);
      expect(
        cached,
        isEmpty,
        reason:
            'Delivered ephemeral events must be purged; relays do not persist '
            'them and doNotRetry means nothing will re-broadcast them.',
      );
      expect(await cache.loadEventDeliveryRecord(ephemeralEvent.id), isNull);

      await ndk.destroy();
    });

    test('non-ephemeral events ARE cached normally on inbound query '
        '(regression guard)', () async {
      final key = Bip340.generatePrivateKey();

      final textNote = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key.publicKey,
        content: 'regular text note — must be cached',
        tags: [],
        createdAt: Nip01Event.secondsSinceEpoch(),
      );

      final mockRelay = MockRelay(name: 'non-ephemeral-test');
      await mockRelay.startServer(textNotes: {key: textNote});
      addTearDown(() => mockRelay.stopServer());

      final cache = MemCacheManager();

      final ndk = Ndk(
        NdkConfig(
          cache: cache,
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final response = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key.publicKey],
        ),
        cacheRead: true,
        cacheWrite: true,
      );

      final results = await response.future;
      expect(results.map((e) => e.id), contains(textNote.id));

      await Future.delayed(const Duration(milliseconds: 200));

      // Non-ephemeral event must be in cache.
      expect(
        cache.events[textNote.id],
        isNotNull,
        reason: 'Non-ephemeral events must be cached normally.',
      );

      await ndk.destroy();
    });

    test('mixed ephemeral + non-ephemeral kinds: only ephemeral skipped '
        '(per-event filtering)', () async {
      final key = Bip340.generatePrivateKey();

      final mockRelay = MockRelay(name: 'mixed-kinds-test');
      await mockRelay.startServer();
      addTearDown(() => mockRelay.stopServer());

      final cache = MemCacheManager();

      final subscriberNdk = Ndk(
        NdkConfig(
          cache: cache,
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final broadcasterNdk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      // Subscribe to BOTH text notes and ephemeral events.
      final textNoteReceived = Completer<void>();
      final ephemeralReceived = Completer<void>();

      final subscription = subscriberNdk.requests.subscription(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind, ephemeralKind],
          authors: [key.publicKey],
        ),
        cacheWrite: true,
      );

      Nip01Event? receivedTextNote;
      Nip01Event? receivedEphemeral;

      subscription.stream.listen((event) {
        if (event.kind == Nip01Event.kTextNodeKind &&
            !textNoteReceived.isCompleted) {
          receivedTextNote = event;
          textNoteReceived.complete();
        }
        if (event.kind == ephemeralKind && !ephemeralReceived.isCompleted) {
          receivedEphemeral = event;
          ephemeralReceived.complete();
        }
      });

      await _waitForSubscriptionCount(mockRelay, 1);

      // Broadcast a non-ephemeral text note from a separate NDK instance.
      final textNote = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          kind: Nip01Event.kTextNodeKind,
          pubKey: key.publicKey,
          content: 'text note in a mixed request',
          tags: [],
          createdAt: Nip01Event.secondsSinceEpoch(),
        ),
        privateKey: key.privateKey!,
      );
      await broadcasterNdk.broadcast
          .broadcast(nostrEvent: textNote, specificRelays: [mockRelay.url])
          .broadcastDoneFuture;

      await textNoteReceived.future.timeout(const Duration(seconds: 5));

      // Broadcast an ephemeral event from the same separate instance.
      final ephemeralEvent = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          pubKey: key.publicKey,
          kind: ephemeralKind,
          tags: const [],
          content: 'ephemeral in a mixed request',
        ),
        privateKey: key.privateKey!,
      );
      await broadcasterNdk.broadcast
          .broadcast(
            nostrEvent: ephemeralEvent,
            specificRelays: [mockRelay.url],
          )
          .broadcastDoneFuture;

      await ephemeralReceived.future.timeout(const Duration(seconds: 5));

      await Future.delayed(const Duration(milliseconds: 300));

      // Both events were received by the subscriber.
      expect(receivedTextNote, isNotNull);
      expect(receivedEphemeral, isNotNull);

      // Text note (non-ephemeral) must be cached.
      expect(
        cache.events[receivedTextNote!.id],
        isNotNull,
        reason: 'Non-ephemeral events in a mixed-kinds request must be cached.',
      );

      // Ephemeral event must NOT be cached.
      expect(
        cache.events[receivedEphemeral!.id],
        isNull,
        reason: 'Ephemeral events in a mixed-kinds request must not be cached.',
      );

      await subscriberNdk.destroy();
      await broadcasterNdk.destroy();
    });
  });
}

/// Polls the mock relay until [expectedCount] active subscriptions exist.
Future<void> _waitForSubscriptionCount(
  MockRelay relay,
  int expectedCount, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (relay.activeSubscriptionCount >= expectedCount) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 25));
  }
  throw TimeoutException(
    'MockRelay did not reach $expectedCount active subscriptions.',
  );
}
