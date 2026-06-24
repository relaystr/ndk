import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import 'mock_event_verifier.dart';
import 'mock_relay.dart';

void main() {
  group('MockRelay live subscriptions', () {
    late MockRelay mockRelay;

    setUp(() async {
      mockRelay = MockRelay(
        name: 'live-subscription-test-relay',
        explicitPort: 4070,
      );
      await mockRelay.startServer();
    });

    tearDown(() async {
      await mockRelay.stopServer();
    });

    test('NDK A receives matching event broadcast by NDK B', () async {
      final keyPair = Bip340.generatePrivateKey();

      final ndkA = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );
      addTearDown(ndkA.destroy);

      final ndkB = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );
      addTearDown(ndkB.destroy);

      final receivedEvent = Completer<Nip01Event>();
      final subscription = ndkA.requests.subscription(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [keyPair.publicKey],
        ),
      );

      subscription.stream.listen((event) {
        if (!receivedEvent.isCompleted) {
          receivedEvent.complete(event);
        }
      });

      await Future.delayed(Duration(milliseconds: 200));

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: [],
        content: 'live subscription event',
      );
      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: keyPair.privateKey!,
      );

      final broadcast = ndkB.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: [mockRelay.url],
      );
      await broadcast.broadcastDoneFuture;

      final eventFromSubscription = await receivedEvent.future.timeout(
        Duration(seconds: 2),
        onTimeout: () => throw TimeoutException(
          'NDK A did not receive the matching event broadcast by NDK B.',
        ),
      );

      expect(eventFromSubscription.id, equals(signedEvent.id));
      expect(eventFromSubscription.content, equals('live subscription event'));
    });

    test('stale replaceable events are not broadcast to subscriptions',
        () async {
      final keyPair = Bip340.generatePrivateKey();

      final ndkA = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );
      addTearDown(ndkA.destroy);

      final ndkB = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );
      addTearDown(ndkB.destroy);

      final receivedEvents = <Nip01Event>[];
      final firstEventReceived = Completer<Nip01Event>();
      final unexpectedSecondEvent = Completer<Nip01Event>();
      final subscription = ndkA.requests.subscription(
        filter: Filter(
          kinds: [10000],
          authors: [keyPair.publicKey],
        ),
      );

      subscription.stream.listen((event) {
        receivedEvents.add(event);
        if (!firstEventReceived.isCompleted) {
          firstEventReceived.complete(event);
        } else if (!unexpectedSecondEvent.isCompleted) {
          unexpectedSecondEvent.complete(event);
        }
      });

      await Future.delayed(Duration(milliseconds: 200));

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final currentEvent = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 10000,
        tags: [],
        content: 'current replaceable event',
        createdAt: now,
      );
      final signedCurrentEvent = Nip01Utils.signWithPrivateKey(
        event: currentEvent,
        privateKey: keyPair.privateKey!,
      );

      await ndkB.broadcast.broadcast(
        nostrEvent: signedCurrentEvent,
        specificRelays: [mockRelay.url],
      ).broadcastDoneFuture;

      final firstEventFromSubscription =
          await firstEventReceived.future.timeout(
        Duration(seconds: 2),
        onTimeout: () => throw TimeoutException(
          'NDK A did not receive the current replaceable event.',
        ),
      );

      final staleEvent = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 10000,
        tags: [],
        content: 'stale replaceable event',
        createdAt: now - 100,
      );
      final signedStaleEvent = Nip01Utils.signWithPrivateKey(
        event: staleEvent,
        privateKey: keyPair.privateKey!,
      );

      await ndkB.broadcast.broadcast(
        nostrEvent: signedStaleEvent,
        specificRelays: [mockRelay.url],
      ).broadcastDoneFuture;

      final staleEventWasBroadcast = await unexpectedSecondEvent.future
          .then((_) => true)
          .timeout(Duration(milliseconds: 300), onTimeout: () => false);

      expect(firstEventFromSubscription.id, equals(signedCurrentEvent.id));
      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.single.id, equals(signedCurrentEvent.id));
      expect(
        staleEventWasBroadcast,
        isFalse,
        reason: 'Stale replaceable events should not be broadcast live.',
      );
    });
  });
}
