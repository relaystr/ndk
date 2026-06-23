import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/domain_layer/entities/event_cache_records.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/usecases/broadcast/delivery_policy.dart';
import 'package:test/test.dart';

void main() {
  group('DeliveryPolicy', () {
    test('uses latest-state-only policy for replaceable events', () {
      final event = Nip01Event(
        id: 'replaceable-1',
        pubKey: 'pubkey',
        createdAt: 1700000000,
        kind: 30023,
        tags: const [
          ['d', 'article-1'],
        ],
        content: 'article',
        sig: 'sig',
      );

      final policy = DeliveryPolicy.forEvent(event);

      expect(policy.kind, DeliveryPolicyKind.latestStateOnly);
      expect(policy.retainsOnlyLatest, isTrue);
    });

    test('uses latest-state-only policy for regular replaceable events too',
        () {
      final event = Nip01Event(
        id: 'replaceable-2',
        pubKey: 'pubkey',
        createdAt: 1700000000,
        kind: 10002,
        tags: const [],
        content: 'relay list',
        sig: 'sig',
      );

      final policy = DeliveryPolicy.forEvent(event);

      expect(policy.kind, DeliveryPolicyKind.latestStateOnly);
      expect(policy.retainsOnlyLatest, isTrue);
    });

    test('uses do-not-retry policy for ephemeral events', () {
      final event = Nip01Event(
        id: 'ephemeral-1',
        pubKey: 'pubkey',
        createdAt: 1700000001,
        kind: 24133,
        tags: const [],
        content: 'ephemeral',
        sig: 'sig',
      );

      final policy = DeliveryPolicy.forEvent(event);

      expect(policy.kind, DeliveryPolicyKind.doNotRetry);
      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'rate-limited: retry later',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
    });

    test('classifies auth-required separately from permanent failures', () {
      final event = Nip01Event(
        id: 'event-1',
        pubKey: 'pubkey',
        createdAt: 1700000002,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'text',
        sig: 'sig',
      );

      final policy = DeliveryPolicy.forEvent(event);

      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'auth-required: please authenticate',
          ),
        ),
        RelayDeliveryState.authRequired,
      );
      expect(policy.shouldRetryState(RelayDeliveryState.authRequired), isTrue);
      expect(
        policy.retryDelayFor(
          state: RelayDeliveryState.authRequired,
          attemptCount: 1,
        ),
        const Duration(minutes: 1),
      );
      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'invalid signature',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
      expect(
        policy.shouldRetryState(RelayDeliveryState.permanentFailure),
        isFalse,
      );
      expect(
        policy.retryDelayFor(
          state: RelayDeliveryState.permanentFailure,
          attemptCount: 1,
        ),
        Duration.zero,
      );
    });

    test('treats duplicate and policy violations as permanent failures', () {
      final event = Nip01Event(
        id: 'event-2',
        pubKey: 'pubkey',
        createdAt: 1700000002,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'text',
        sig: 'sig',
      );

      final policy = DeliveryPolicy.forEvent(event);

      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'duplicate: already have this event',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'policy violation: forbidden kind',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'restricted: not allowed to write',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'invalid: event creation date is too far off',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
    });

    test('keeps rate-limited and error prefixes retryable', () {
      final event = Nip01Event(
        id: 'event-3',
        pubKey: 'pubkey',
        createdAt: 1700000003,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'text',
        sig: 'sig',
      );

      final policy = DeliveryPolicy.forEvent(event);

      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'rate-limited: slow down',
          ),
        ),
        RelayDeliveryState.transientFailure,
      );
      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'error: backend unavailable',
          ),
        ),
        RelayDeliveryState.transientFailure,
      );
    });

    test('treats common raw strfry validation failures as permanent', () {
      final event = Nip01Event(
        id: 'event-4',
        pubKey: 'pubkey',
        createdAt: 1700000004,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'text',
        sig: 'sig',
      );

      final policy = DeliveryPolicy.forEvent(event);

      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'bad signature',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'too many tags: 1200',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
      expect(
        policy.resolveNextState(
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.example',
            okReceived: false,
            broadcastSuccessful: false,
            msg: 'event too large: 999999',
          ),
        ),
        RelayDeliveryState.permanentFailure,
      );
    });

    test('uses faster backoff for deletion events', () {
      final deletionEvent = Nip01Event(
        id: 'delete-1',
        pubKey: 'pubkey',
        createdAt: 1700000003,
        kind: 5,
        tags: const [
          ['e', 'target'],
        ],
        content: 'delete',
        sig: 'sig',
      );
      final noteEvent = Nip01Event(
        id: 'note-1',
        pubKey: 'pubkey',
        createdAt: 1700000004,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'note',
        sig: 'sig',
      );

      final deletionPolicy = DeliveryPolicy.forEvent(deletionEvent);
      final notePolicy = DeliveryPolicy.forEvent(noteEvent);

      expect(
        deletionPolicy.retryDelayFor(
          state: RelayDeliveryState.transientFailure,
          attemptCount: 1,
        ),
        lessThan(
          notePolicy.retryDelayFor(
            state: RelayDeliveryState.transientFailure,
            attemptCount: 1,
          ),
        ),
      );
    });
  });
}
