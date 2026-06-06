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
  });
}
