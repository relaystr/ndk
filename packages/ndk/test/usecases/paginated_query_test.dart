// ignore_for_file: avoid_print

import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() async {
  late KeyPair key1;
  late MockRelay relay1;
  late Ndk ndk;
  late Bip340EventSigner signer;

  setUp(() async {
    key1 = Bip340.generatePrivateKey();

    signer = Bip340EventSigner(
      privateKey: key1.privateKey,
      publicKey: key1.publicKey,
    );

    relay1 = MockRelay(
      name: "relay 1",
      explicitPort: 6070,
      maxEventsPerRequest: 2,
    );

    await relay1.startServer();

    ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay1.url],
      logLevel: LogLevel.off,
    ));

    ndk.accounts.loginExternalSigner(signer: signer);
  });

  tearDown(() async {
    await ndk.destroy();
    await relay1.stopServer();
  });

  group('Paginated Query', () {
    test('fetches all events across multiple pages', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Create 5 events spread across time
      final timestamps = [
        now - 4000,
        now - 3000,
        now - 2000,
        now - 1000,
        now,
      ];

      // Publish events to the relay
      for (final ts in timestamps) {
        final event = Nip01Event(
          kind: Nip01Event.kTextNodeKind,
          pubKey: key1.publicKey,
          content: "Event at $ts",
          tags: [],
          createdAt: ts,
        );
        final response = ndk.broadcast.broadcast(
          nostrEvent: event,
        );
        await response.broadcastDoneFuture;
      }

      await ndk.config.cache.clearAll();

      final query = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
        paginate: true,
      );

      final events = await query.future;

      expect(events.length, equals(5));
    });

    test('respects since parameter', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timestamps = [
        now - 5000,
        now - 4000,
        now - 3000,
        now - 2000,
        now - 1000,
      ];

      // Publish events
      for (final ts in timestamps) {
        final event = Nip01Event(
          kind: Nip01Event.kTextNodeKind,
          pubKey: key1.publicKey,
          content: "Event at $ts",
          tags: [],
          createdAt: ts,
        );
        final response = ndk.broadcast.broadcast(
          nostrEvent: event,
        );
        await response.broadcastDoneFuture;
      }

      await ndk.config.cache.clearAll();

      // Query with since that excludes older events
      final query = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
          since: now - 3500, // Should only get events from -3000, -2000, -1000
        ),
        paginate: true,
      );

      final events = await query.future;
      // Should return only 3 events (those after since)
      expect(events.length, equals(3));

      // Verify all events are after 'since'
      for (final event in events) {
        expect(event.createdAt, greaterThanOrEqualTo(now - 3500));
      }
    });

    test('respects until parameter', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timestamps = [
        now - 5000,
        now - 4000,
        now - 3000,
        now - 2000,
        now - 1000,
      ];

      // Publish events
      for (final ts in timestamps) {
        final event = Nip01Event(
          kind: Nip01Event.kTextNodeKind,
          pubKey: key1.publicKey,
          content: "Event at $ts",
          tags: [],
          createdAt: ts,
        );
        final response = ndk.broadcast.broadcast(
          nostrEvent: event,
        );
        await response.broadcastDoneFuture;
      }

      await ndk.config.cache.clearAll();

      // Query with until that excludes recent events
      final query = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
          until: now - 2500, // Should only get events from -5000, -4000, -3000
        ),
        paginate: true,
      );

      final events = await query.future;
      // Should return only 3 events (those before until)
      expect(events.length, equals(3));

      // Verify all events are before 'until'
      for (final event in events) {
        expect(event.createdAt, lessThanOrEqualTo(now - 2500));
      }
    });

    test('handles events with same timestamp', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final sameTimestamp = now - 2000;

      final timestamps = [
        now - 4000,
        sameTimestamp, // same
        sameTimestamp, // same
        sameTimestamp, // same
        now - 1000,
      ];

      // Publish events
      for (int i = 0; i < timestamps.length; i++) {
        final event = Nip01Event(
          kind: Nip01Event.kTextNodeKind,
          pubKey: key1.publicKey,
          content: "Event $i at ${timestamps[i]}",
          tags: [],
          createdAt: timestamps[i],
        );
        final response = ndk.broadcast.broadcast(
          nostrEvent: event,
        );
        await response.broadcastDoneFuture;
      }

      await ndk.config.cache.clearAll();

      final query = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
        paginate: true,
      );

      final events = await query.future;

      expect(events.length, equals(3));

      // Verify no duplicates
      final ids = events.map((e) => e.id).toSet();
      expect(ids.length, equals(3));
    });

    test('paginates correctly across multiple relays', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final firstEvent = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key1.publicKey,
        content: "Event at $now",
        tags: [],
        createdAt: now,
      );
      final firstEventSigned = await signer.sign(firstEvent);

      final relay1EventTimeStamp = now - 3000;
      final relay1Event = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key1.publicKey,
        content: "Event at $relay1EventTimeStamp",
        tags: [],
        createdAt: relay1EventTimeStamp,
      );
      final relay1EventSigned = await signer.sign(relay1Event);

      final middleEventTimeStamp = now - 5000;
      final middleEvent = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key1.publicKey,
        content: "Event at $middleEventTimeStamp",
        tags: [],
        createdAt: middleEventTimeStamp,
      );
      final middleEventSigned = await signer.sign(middleEvent);

      final relay2EventTimeStamp = now - 7000;
      final relay2Event = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key1.publicKey,
        content: "Event at $relay2EventTimeStamp",
        tags: [],
        createdAt: relay2EventTimeStamp,
      );
      final relay2EventSigned = await signer.sign(relay2Event);

      final lastEventTimeStamp = now - 10000;
      final lastEvent = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key1.publicKey,
        content: "Event at $lastEventTimeStamp",
        tags: [],
        createdAt: lastEventTimeStamp,
      );
      final lastEventSigned = await signer.sign(lastEvent);

      final relay1Events = [
        firstEventSigned,
        relay1EventSigned,
        middleEventSigned,
        lastEventSigned
      ];
      final relay2Events = [
        firstEventSigned,
        relay2EventSigned,
        lastEventSigned
      ];

      // Create a second relay
      final relay2 = MockRelay(
        name: "relay 2",
        explicitPort: 6071,
      );
      await relay2.startServer();

      try {
        for (final event in relay1Events) {
          final response = ndk.broadcast.broadcast(
            nostrEvent: event,
            specificRelays: [relay1.url],
          );
          await response.broadcastDoneFuture;
        }

        for (final event in relay2Events) {
          final response = ndk.broadcast.broadcast(
            nostrEvent: event,
            specificRelays: [relay2.url],
          );
          await response.broadcastDoneFuture;
        }
      } finally {}

      await ndk.config.cache.clearAll();

      // Query both relays with pagination
      final query = ndk.requests.query(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
        explicitRelays: [relay1.url, relay2.url],
        paginate: true,
      );

      final events = await query.future;

      expect(events.length, equals(5));

      await relay2.stopServer();
    });
  });
}
