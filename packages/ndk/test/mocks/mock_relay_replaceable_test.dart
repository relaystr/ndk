import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import 'mock_event_verifier.dart';
import 'mock_relay.dart';

void main() {
  group('MockRelay replacement semantics', () {
    late MockRelay mockRelay;

    setUp(() async {
      mockRelay = MockRelay(
        name: 'replaceable-test-relay',
        explicitPort: 4060,
      );
      await mockRelay.startServer();
    });

    tearDown(() async {
      await mockRelay.stopServer();
    });

    test(
        'replaceable events (kind 10002) should be replaced by newer version from same author',
        () async {
      final keyPair = Bip340.generatePrivateKey();

      final ndkWriter = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Older version
      final oldEvent = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 10002,
        tags: [
          ['r', 'wss://old.example.com'],
        ],
        content: '',
        createdAt: now - 100,
      );
      final signedOld = Nip01Utils.signWithPrivateKey(
        event: oldEvent,
        privateKey: keyPair.privateKey!,
      );
      await ndkWriter.broadcast.broadcast(
        nostrEvent: signedOld,
        specificRelays: [mockRelay.url],
      ).broadcastDoneFuture;

      // Newer version (same author, same kind)
      final newEvent = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 10002,
        tags: [
          ['r', 'wss://new.example.com'],
        ],
        content: '',
        createdAt: now,
      );
      final signedNew = Nip01Utils.signWithPrivateKey(
        event: newEvent,
        privateKey: keyPair.privateKey!,
      );
      await ndkWriter.broadcast.broadcast(
        nostrEvent: signedNew,
        specificRelays: [mockRelay.url],
      ).broadcastDoneFuture;

      // Query from a fresh client to bypass any local cache
      final ndkReader = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final received = <Nip01Event>[];
      final response = ndkReader.requests.query(
        filter: Filter(
          kinds: [10002],
          authors: [keyPair.publicKey],
        ),
      );
      await for (final event in response.stream) {
        received.add(event);
      }

      expect(
        received.length,
        equals(1),
        reason:
            'NIP-01 replaceable events should keep only the latest (pubkey, kind); '
            'mock currently returns every version ever sent.',
      );
      expect(
        received.first.getFirstTag('r'),
        equals('wss://new.example.com'),
        reason: 'The retained event should be the newer one.',
      );

      await ndkWriter.destroy();
      await ndkReader.destroy();
    });

    test(
        'addressable events (kind 30023) should be replaced by newer version with same d-tag',
        () async {
      final keyPair = Bip340.generatePrivateKey();

      final ndkWriter = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const dTag = 'my-article';

      // Older version with d-tag
      final oldEvent = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 30023,
        tags: [
          ['d', dTag],
        ],
        content: 'first draft',
        createdAt: now - 100,
      );
      final signedOld = Nip01Utils.signWithPrivateKey(
        event: oldEvent,
        privateKey: keyPair.privateKey!,
      );
      await ndkWriter.broadcast.broadcast(
        nostrEvent: signedOld,
        specificRelays: [mockRelay.url],
      ).broadcastDoneFuture;

      // Newer version with same d-tag
      final newEvent = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 30023,
        tags: [
          ['d', dTag],
        ],
        content: 'final version',
        createdAt: now,
      );
      final signedNew = Nip01Utils.signWithPrivateKey(
        event: newEvent,
        privateKey: keyPair.privateKey!,
      );
      await ndkWriter.broadcast.broadcast(
        nostrEvent: signedNew,
        specificRelays: [mockRelay.url],
      ).broadcastDoneFuture;

      final ndkReader = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final received = <Nip01Event>[];
      final response = ndkReader.requests.query(
        filter: Filter(
          kinds: [30023],
          authors: [keyPair.publicKey],
          dTags: [dTag],
        ),
      );
      await for (final event in response.stream) {
        received.add(event);
      }

      expect(
        received.length,
        equals(1),
        reason:
            'NIP-01 addressable events should keep only the latest '
            '(pubkey, kind, d-tag); mock currently returns every version sent.',
      );
      expect(
        received.first.content,
        equals('final version'),
        reason: 'The retained event should be the newer one.',
      );

      await ndkWriter.destroy();
      await ndkReader.destroy();
    });
  });
}
