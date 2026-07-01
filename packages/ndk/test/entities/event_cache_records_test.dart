import 'package:ndk/entities.dart';
import 'package:test/test.dart';

void main() {
  group('EventCacheStateRecord', () {
    test('derives coordinate and expiration fields for addressable events', () {
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
      );

      final record = EventCacheStateRecord.buildForEvents(
        [event],
        now: 1700000100,
      ).single;

      expect(record.eventId, event.id);
      expect(record.coordinateKey, '30023:pubkey-1:article-1');
      expect(record.expirationAt, 1700009999);
      expect(record.isCurrent, isTrue);
      expect(record.deletedByEventId, isNull);
    });

    test('round trips through json', () {
      const original = EventCacheStateRecord(
        eventId: 'event-2',
        pubKey: 'pubkey-2',
        kind: 1,
        createdAt: 1700000001,
        coordinateKey: null,
        isCurrent: false,
        expirationAt: 1700009999,
        deletedByEventId: 'delete-1',
      );

      final restored = EventCacheStateRecord.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
      expect(restored.isDeleted, isTrue);
    });

    test('uses lower event id as tie breaker for addressable winners', () {
      final records = EventCacheStateRecord.buildForEvents([
        Nip01Event(
          id: 'bbbb',
          pubKey: 'pubkey-3',
          createdAt: 1700000002,
          kind: 30023,
          tags: const [
            ['d', 'article-1'],
          ],
          content: 'older',
          sig: 'sig-3',
        ),
        Nip01Event(
          id: 'aaaa',
          pubKey: 'pubkey-3',
          createdAt: 1700000002,
          kind: 30023,
          tags: const [
            ['d', 'article-1'],
          ],
          content: 'newer',
          sig: 'sig-4',
        ),
      ]);

      final byId = {for (final record in records) record.eventId: record};
      expect(byId['aaaa']!.isCurrent, isTrue);
      expect(byId['bbbb']!.isCurrent, isFalse);
    });
  });

  group('EventDeliveryRecord', () {
    test('round trips through json', () {
      final original = EventDeliveryRecord(
        eventId: 'event-3',
        status: EventDeliveryStatus.partiallyDelivered,
        signingState: EventSigningState.transientFailure,
        createdAt: 1700001000,
        updatedAt: 1700001010,
        signedAt: 1700001005,
        completedAt: 1700001020,
        requiresInteractiveSigning: true,
        signAttemptCount: 2,
        lastSignAttemptAt: 1700001008,
        nextSignRetryAt: 1700001100,
        lastSignError: 'timed out',
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
