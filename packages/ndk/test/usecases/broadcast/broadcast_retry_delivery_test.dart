import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  group('broadcast retryDelivery', () {
    late MockRelay relay;
    late MemCacheManager cache;
    late Ndk ndk;
    late Nip01Event event;

    setUp(() async {
      relay = MockRelay(name: 'refusing relay', rejectFirstEventPublishes: 1);
      await relay.startServer();

      cache = MemCacheManager();
      ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: cache,
          bootstrapRelays: [relay.url],
          defaultBroadcastTimeout: const Duration(seconds: 2),
          // the background timer would retry behind the assertions
          pendingDeliveryRetriesEnabled: false,
        ),
      );

      final key = Bip340.generatePrivateKey();
      ndk.accounts.loginPrivateKey(
        privkey: key.privateKey!,
        pubkey: key.publicKey,
      );

      event = Nip01Event(
        pubKey: key.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'note',
        createdAt: 1700000000,
      );
    });

    tearDown(() async {
      await ndk.destroy();
      await relay.stopServer();
    });

    test('a refused broadcast is enrolled for retry by default', () async {
      await ndk.broadcast.broadcast(
          nostrEvent: event, specificRelays: [relay.url]).broadcastDoneFuture;

      expect(await cache.loadEventDeliveryRecord(event.id), isNotNull);
      final targets = await cache.loadRelayDeliveryTargets(eventId: event.id);
      expect(targets.single.state, RelayDeliveryState.transientFailure);
    });

    test('retryDelivery false leaves nothing to retry', () async {
      await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: [relay.url],
            retryDelivery: false,
          )
          .broadcastDoneFuture;

      expect(await cache.loadEventDeliveryRecord(event.id), isNull);
      expect(
        await cache.loadRelayDeliveryTargets(eventId: event.id),
        isEmpty,
      );
      expect(await cache.loadEvent(event.id), isNotNull);
    });
  });
}
