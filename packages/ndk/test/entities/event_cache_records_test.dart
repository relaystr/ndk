import 'package:ndk/entities.dart';
import 'package:test/test.dart';

void main() {
  group('CachedEventRecord', () {
    test('derives replaceable coordinate and expiration fields', () {
      final event = Nip01Event(
        id: 'event-1',
        pubKey: 'pubkey-1',
        createdAt: 1700000000,
        kind: 30023,
        tags: const [
          ['d', 'article-1'],
          ['expiration', '1700009999'],
        ],
        content: 'hello',
        sig: 'sig-1',
        sources: ['wss://b', 'wss://a'],
      );

      final record = CachedEventRecord.fromEvent(
        event,
        seenAt: 1700000100,
      );

      expect(record.eventId, event.id);
      expect(record.dTag, 'article-1');
      expect(record.coordinateKey, '30023:pubkey-1:article-1');
      expect(record.isReplaceable, isTrue);
      expect(record.isAddressable, isTrue);
      expect(record.expirationAt, 1700009999);
      expect(record.sourceRelays, ['wss://a', 'wss://b']);
      expect(record.firstSeenAt, 1700000100);
      expect(record.lastSeenAt, 1700000100);
    });

    test('round trips through json', () {
      final event = Nip01Event(
        id: 'event-2',
        pubKey: 'pubkey-2',
        createdAt: 1700000001,
        kind: 1,
        tags: const [],
        content: 'hi',
        sig: 'sig-2',
      );

      final original = CachedEventRecord.fromEvent(
        event,
        sourceRelays: const ['wss://relay.example'],
        seenAt: 1700000200,
        localOrigin: true,
        localCreatedAt: 1700000190,
      ).copyWith(
        deletedByEventId: 'delete-1',
        deletedAt: 1700000300,
      );

      final restored = CachedEventRecord.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
      expect(restored.isDeleted, isTrue);
    });

    test('uses lower event id as tie breaker for replaceable events', () {
      final older = CachedEventRecord.fromEvent(
        Nip01Event(
          id: 'bbbb',
          pubKey: 'pubkey-3',
          createdAt: 1700000002,
          kind: 10002,
          tags: const [],
          content: 'older',
          sig: 'sig-3',
        ),
      );

      final newer = CachedEventRecord.fromEvent(
        Nip01Event(
          id: 'aaaa',
          pubKey: 'pubkey-3',
          createdAt: 1700000002,
          kind: 10002,
          tags: const [],
          content: 'newer',
          sig: 'sig-4',
        ),
      );

      expect(CachedEventRecord.isMoreRecentThan(newer, older), isTrue);
      expect(CachedEventRecord.isMoreRecentThan(older, newer), isFalse);
    });

  });

  group('EventDeliveryRecord', () {
    test('round trips through json', () {
      final original = EventDeliveryRecord(
        eventId: 'event-3',
        status: EventDeliveryStatus.partiallyDelivered,
        createdAt: 1700001000,
        updatedAt: 1700001010,
        signedAt: 1700001005,
        requiresNetworkSigner: true,
      );

      final restored = EventDeliveryRecord.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
      expect(restored.isComplete, isFalse);
    });
  });

  group('RelayDeliveryTarget', () {
    test('round trips through json', () {
      const original = RelayDeliveryTarget(
        eventId: 'event-4',
        relayUrl: 'wss://relay.two',
        reason: RelayDeliveryReason.explicit,
        state: RelayDeliveryState.transientFailure,
        attemptCount: 2,
        nextRetryAt: 1700003000,
        lastError: 'timeout',
      );

      final restored = RelayDeliveryTarget.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
      expect(restored.key, 'event-4|wss://relay.two');
    });

    test('copyWith can clear nullable retry metadata fields', () {
      const original = RelayDeliveryTarget(
        eventId: 'event-4',
        relayUrl: 'wss://relay.two',
        reason: RelayDeliveryReason.explicit,
        state: RelayDeliveryState.transientFailure,
        attemptCount: 2,
        lastAttemptAt: 1700002000,
        nextRetryAt: 1700003000,
        lastError: 'timeout',
        lastOkMessage: 'ok',
      );

      final cleared = original.copyWith(
        nextRetryAt: null,
        lastError: null,
        lastOkMessage: null,
      );

      expect(cleared.nextRetryAt, isNull);
      expect(cleared.lastError, isNull);
      expect(cleared.lastOkMessage, isNull);
      expect(cleared.lastAttemptAt, original.lastAttemptAt);
    });
  });
}
