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

    Future<void> waitForSubscriptionRegistration() async {
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (DateTime.now().isBefore(deadline)) {
        if (mockRelay.activeSubscriptionCount > 0) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 25));
      }
      throw TimeoutException('MockRelay did not register the subscription.');
    }

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

      await waitForSubscriptionRegistration();

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

      await waitForSubscriptionRegistration();

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

    test('live subscription resumes after relay closes the socket', () async {
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

      final eventAfterReconnect = Completer<Nip01Event>();
      final subscription = ndkA.requests.subscription(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [keyPair.publicKey],
        ),
      );

      subscription.stream.listen((event) {
        if (!eventAfterReconnect.isCompleted) {
          eventAfterReconnect.complete(event);
        }
      });

      await waitForSubscriptionRegistration();

      // Backdate the last connect attempt so the reconnect-on-close path is
      // not suppressed by the FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS throttle.
      ndkA.relays.globalState.relays[mockRelay.url]!.relay.lastConnectTry = 0;

      // Relay-side disconnect: the server stays up, only the sockets die.
      await mockRelay.closeClientSockets();

      // NDK A must reconnect and re-send its in-flight REQ on its own.
      await waitForSubscriptionRegistration();

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: [],
        content: 'event after reconnect',
      );
      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: event,
        privateKey: keyPair.privateKey!,
      );

      await ndkB.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: [mockRelay.url],
      ).broadcastDoneFuture;

      final received = await eventAfterReconnect.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
          'NDK A did not receive events after the relay closed the socket.',
        ),
      );

      expect(received.id, equals(signedEvent.id));
      expect(received.content, equals('event after reconnect'));
    });
  });
}
