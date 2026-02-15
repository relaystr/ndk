import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import 'mock_event_verifier.dart';
import 'mock_relay.dart';

void main() {
  group('MockRelay ephemeral events (kinds 20000-29999)', () {
    late MockRelay mockRelay;

    setUp(() async {
      mockRelay = MockRelay(
        name: 'ephemeral-test-relay',
        explicitPort: 4050,
      );
      await mockRelay.startServer();
    });

    tearDown(() async {
      await mockRelay.stopServer();
    });

    test('ephemeral events should be broadcast to matching subscriptions',
        () async {
      final keyPair1 = Bip340.generatePrivateKey();
      final keyPair2 = Bip340.generatePrivateKey();

      // Create two NDK clients
      final ndk1 = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final ndk2 = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      // Client 2 subscribes to ephemeral events (kind 21133) tagged with their pubkey
      final receivedEvents = <Nip01Event>[];
      final completer = Completer<void>();

      final subscription = ndk2.requests.subscription(
        filter: Filter(
          kinds: [21133],
          pTags: [keyPair2.publicKey],
        ),
      );

      subscription.stream.listen((event) {
        receivedEvents.add(event);
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Wait for subscription to be established
      await Future.delayed(Duration(milliseconds: 200));

      // Client 1 sends an ephemeral event (kind 21133 - NIP-46)
      final ephemeralEvent = Nip01Event(
        pubKey: keyPair1.publicKey,
        kind: 21133,
        tags: [
          ['p', keyPair2.publicKey]
        ],
        content: 'test ephemeral content',
      );
      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: ephemeralEvent,
        privateKey: keyPair1.privateKey!,
      );

      final broadcast = ndk1.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: [mockRelay.url],
      );
      await broadcast.broadcastDoneFuture;

      // Wait for event to be broadcast (with timeout)
      await completer.future.timeout(
        Duration(seconds: 2),
        onTimeout: () => null,
      );

      // Verify client2 received the ephemeral event
      expect(receivedEvents.length, equals(1),
          reason:
              'Ephemeral events should be broadcast to matching subscriptions',);
      expect(receivedEvents.first.kind, equals(21133));
      expect(receivedEvents.first.content, equals('test ephemeral content'));

      // Cleanup
      await ndk1.destroy();
      await ndk2.destroy();
    });

    test('ephemeral events should NOT be stored for later retrieval', () async {
      final keyPair1 = Bip340.generatePrivateKey();
      final keyPair2 = Bip340.generatePrivateKey();

      final ndk1 = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      // Send an ephemeral event first
      final ephemeralEvent = Nip01Event(
        pubKey: keyPair1.publicKey,
        kind: 21133,
        tags: [
          ['p', keyPair2.publicKey]
        ],
        content: 'ephemeral content',
      );
      final signedEvent = Nip01Utils.signWithPrivateKey(
        event: ephemeralEvent,
        privateKey: keyPair1.privateKey!,
      );

      final broadcast = ndk1.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: [mockRelay.url],
      );
      await broadcast.broadcastDoneFuture;

      // Wait for event to be processed
      await Future.delayed(Duration(milliseconds: 200));

      // Create a new client and try to retrieve the ephemeral event
      final ndk2 = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final receivedEvents = <Nip01Event>[];

      final response = ndk2.requests.query(
        filter: Filter(
          kinds: [21133],
          authors: [keyPair1.publicKey],
        ),
      );

      await for (final event in response.stream) {
        receivedEvents.add(event);
      }

      // Ephemeral events should NOT be returned in historical queries
      expect(receivedEvents.length, equals(0),
          reason: 'Ephemeral events should not be stored for later retrieval');

      // Cleanup
      await ndk1.destroy();
      await ndk2.destroy();
    });
  });
}
