import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('delivery inspection', () {
    test('loads pending local-first deliveries with relay-specific outcomes', () async {
      final cache = MemCacheManager();
      final ndk = Ndk(
        NdkConfig(
          cache: cache,
          eventVerifier: Bip340EventVerifier(),
          bootstrapRelays: const [],
        ),
      );

      final pendingEvent = Nip01Event(
        pubKey: 'pubkey-pending',
        createdAt: 1_700_000_000,
        kind: 1,
        tags: const [],
        content: 'pending note',
      );
      final deliveredEvent = Nip01Event(
        pubKey: 'pubkey-delivered',
        createdAt: 1_700_000_001,
        kind: 1,
        tags: const [],
        content: 'delivered note',
      );

      await cache.saveEvents([pendingEvent, deliveredEvent]);

      await cache.saveEventDeliveryRecords([
        EventDeliveryRecord(
          eventId: pendingEvent.id,
          status: EventDeliveryStatus.partiallyDelivered,
          createdAt: pendingEvent.createdAt,
          updatedAt: pendingEvent.createdAt + 10,
        ),
        EventDeliveryRecord(
          eventId: deliveredEvent.id,
          status: EventDeliveryStatus.delivered,
          createdAt: deliveredEvent.createdAt,
          updatedAt: deliveredEvent.createdAt + 10,
          completedAt: deliveredEvent.createdAt + 10,
        ),
      ]);

      await cache.saveRelayDeliveryTargets([
        RelayDeliveryTarget(
          eventId: pendingEvent.id,
          relayUrl: 'wss://relay-a.example.com',
          reason: RelayDeliveryReason.explicit,
          state: RelayDeliveryState.acked,
          attemptCount: 1,
          lastOkMessage: 'ok',
        ),
        RelayDeliveryTarget(
          eventId: pendingEvent.id,
          relayUrl: 'wss://relay-b.example.com',
          reason: RelayDeliveryReason.explicit,
          state: RelayDeliveryState.transientFailure,
          attemptCount: 2,
          lastError: 'rate-limited: retry later',
          nextRetryAt: pendingEvent.createdAt + 30,
        ),
        RelayDeliveryTarget(
          eventId: deliveredEvent.id,
          relayUrl: 'wss://relay-c.example.com',
          reason: RelayDeliveryReason.explicit,
          state: RelayDeliveryState.acked,
          attemptCount: 1,
          lastOkMessage: 'ok',
        ),
      ]);

      final pending = await ndk.broadcast.loadPendingDeliveries();

      expect(pending, hasLength(1));
      expect(pending.single.event?.id, pendingEvent.id);
      expect(pending.single.record.status, EventDeliveryStatus.partiallyDelivered);
      expect(pending.single.isPendingDelivery, isTrue);
      expect(pending.single.isOnlyLocal, isTrue);
      expect(
        pending.single.relayTargets.map((target) => target.relayUrl).toList(),
        [
          'wss://relay-a.example.com',
          'wss://relay-b.example.com',
        ],
      );
      expect(
        pending.single.relayTargets
            .firstWhere((target) => target.relayUrl == 'wss://relay-b.example.com')
            .lastError,
        'rate-limited: retry later',
      );

      final delivered = await ndk.broadcast.loadDeliveries(
        pendingOnly: false,
        status: EventDeliveryStatus.delivered,
      );
      expect(delivered, hasLength(1));
      expect(delivered.single.event?.id, deliveredEvent.id);

      final byId = await ndk.broadcast.loadEventDelivery(pendingEvent.id);
      expect(byId, isNotNull);
      expect(byId!.relayTargets, hasLength(2));

      await ndk.destroy();
    });
  });
}
