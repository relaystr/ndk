import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip09/deletion.dart';
import 'package:test/test.dart';

import 'mock_event_verifier.dart';
import 'mock_relay.dart';

void main() {
  group('MockRelay deletion (kind 5) persistence', () {
    late MockRelay mockRelay;

    setUp(() async {
      mockRelay = MockRelay(
        name: 'deletion-test-relay',
        explicitPort: 4061,
      );
      await mockRelay.startServer();
    });

    tearDown(() async {
      await mockRelay.stopServer();
    });

    test('deletion events (kind 5) should be stored and queryable', () async {
      final keyPair = Bip340.generatePrivateKey();

      final ndkWriter = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [mockRelay.url],
        ),
      );

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final deletion = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: Deletion.kKind,
        tags: [
          [
            'e',
            '6629547c8d890b7b6940247a8cc1baf4f1d231ebfd9a618d95fa4476d85d90ff'
          ],
        ],
        content: 'deleted',
        createdAt: now,
      );
      final signedDeletion = Nip01Utils.signWithPrivateKey(
        event: deletion,
        privateKey: keyPair.privateKey!,
      );
      await ndkWriter.broadcast.broadcast(
        nostrEvent: signedDeletion,
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

      final response = ndkReader.requests.query(
        filter: Filter(
          kinds: [Deletion.kKind],
          authors: [keyPair.publicKey],
        ),
      );
      final received = await response.future;

      expect(
        received.length,
        equals(1),
        reason: 'NIP-09 deletion events are regular persistent events; the '
            'relay should keep the kind 5 event so it can be queried back.',
      );
      expect(received.first.id, equals(signedDeletion.id));

      await ndkWriter.destroy();
      await ndkReader.destroy();
    });
  });
}
