import 'dart:async';

import 'package:ndk/data_layer/repositories/cache_manager/mem_cache_manager.dart';
import 'package:ndk/domain_layer/entities/broadcast_response.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/domain_layer/entities/event_cache_records.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/pending_signer_request.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';
import 'package:ndk/domain_layer/usecases/accounts/accounts.dart';
import 'package:ndk/domain_layer/usecases/broadcast/broadcast_sender.dart';
import 'package:ndk/domain_layer/usecases/broadcast/pending_broadcast_delivery.dart';
import 'package:ndk/domain_layer/usecases/engines/network_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PendingBroadcastDelivery', () {
    late MemCacheManager cacheManager;
    late RecordingBroadcastSender broadcast;
    late PendingBroadcastDelivery pendingDelivery;
    late Nip01Event event;
    late List<String> reconnectAttempts;

    setUp(() async {
      cacheManager = MemCacheManager();
      broadcast = RecordingBroadcastSender(cacheManager: cacheManager);
      pendingDelivery = PendingBroadcastDelivery(
        cacheManager: cacheManager,
        broadcastSender: broadcast,
      );
      reconnectAttempts = [];
      event = Nip01Event(
        id: 'event-1',
        pubKey: 'pubkey',
        createdAt: 1700000000,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'note',
        sig: 'sig',
      );

      await cacheManager.saveEvent(event);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: event.id,
          status: EventDeliveryStatus.pending,
          createdAt: event.createdAt,
          updatedAt: event.createdAt,
        ),
      );
    });

    test('does not rebroadcast permanent failures during due flush', () async {
      await cacheManager.saveRelayDeliveryTarget(
        RelayDeliveryTargetRecord(
          eventId: event.id,
          target: RelayDeliveryTarget(
            relayUrl: 'wss://relay.example',
            reason: RelayDeliveryReason.explicit,
            state: RelayDeliveryState.permanentFailure,
            attemptCount: 1,
            lastAttemptAt: 1700000001,
          ),
        ),
      );

      await pendingDelivery.flushForRelay(
        'wss://relay.example',
        onlyDue: true,
      );

      expect(broadcast.broadcastedEvents, isEmpty);
    });

    test('does not rebroadcast auth-required targets before next retry time',
        () async {
      final now = Nip01Event.secondsSinceEpoch();
      await cacheManager.saveRelayDeliveryTarget(
        RelayDeliveryTargetRecord(
          eventId: event.id,
          target: RelayDeliveryTarget(
            relayUrl: 'wss://relay.example',
            reason: RelayDeliveryReason.explicit,
            state: RelayDeliveryState.authRequired,
            attemptCount: 1,
            lastAttemptAt: now,
            nextRetryAt: now + 60,
          ),
        ),
      );

      await pendingDelivery.flushForRelay(
        'wss://relay.example',
        onlyDue: true,
      );

      expect(broadcast.broadcastedEvents, isEmpty);
    });

    test('rebroadcasts auth-required targets once they are due', () async {
      final now = Nip01Event.secondsSinceEpoch();
      await cacheManager.saveRelayDeliveryTarget(
        RelayDeliveryTargetRecord(
          eventId: event.id,
          target: RelayDeliveryTarget(
            relayUrl: 'wss://relay.example',
            reason: RelayDeliveryReason.explicit,
            state: RelayDeliveryState.authRequired,
            attemptCount: 1,
            lastAttemptAt: now - 60,
            nextRetryAt: now - 1,
          ),
        ),
      );

      await pendingDelivery.flushForRelay(
        'wss://relay.example',
        onlyDue: true,
      );

      expect(broadcast.broadcastedEvents.map((e) => e.id), [event.id]);
    });

    test('periodic retry forces reconnect for disconnected relays with due targets',
        () async {
      final now = Nip01Event.secondsSinceEpoch();
      await cacheManager.saveRelayDeliveryTarget(
        RelayDeliveryTargetRecord(
          eventId: event.id,
          target: RelayDeliveryTarget(
            relayUrl: 'wss://relay.example',
            reason: RelayDeliveryReason.explicit,
            state: RelayDeliveryState.pending,
            attemptCount: 0,
            lastAttemptAt: now - 60,
            nextRetryAt: now - 1,
          ),
        ),
      );

      await pendingDelivery.retryDueDeliveries(
        connectedRelayUrls: () => const <String>[],
        reconnectRelay: (relayUrl) async {
          reconnectAttempts.add(relayUrl);
          return true;
        },
      );

      expect(reconnectAttempts, ['wss://relay.example']);
      expect(broadcast.broadcastedEvents.map((e) => e.id), [event.id]);
    });
  });
}

class RecordingBroadcastSender extends BroadcastSender {
  final List<Nip01Event> broadcastedEvents = [];

  RecordingBroadcastSender({required MemCacheManager cacheManager})
      : super(
          globalState: GlobalState(),
          cacheManager: cacheManager,
          networkEngine: _ThrowingNetworkEngine(),
          accounts: Accounts(_DummySignerFactory()),
          considerDonePercent: 1,
          timeout: const Duration(seconds: 1),
          saveToCache: true,
        );

  @override
  NdkBroadcastResponse broadcast({
    required Nip01Event nostrEvent,
    Iterable<String>? specificRelays,
    EventSigner? customSigner,
    double? considerDonePercent,
    Duration? timeout,
    bool? saveToCache,
  }) {
    broadcastedEvents.add(nostrEvent);
    return NdkBroadcastResponse(
      publishEvent: nostrEvent,
      broadcastDoneStream: Stream.value(const <RelayBroadcastResponse>[]),
    );
  }
}

class _ThrowingNetworkEngine implements NetworkEngine {
  @override
  void handleRequest(requestState) {
    throw UnimplementedError();
  }

  @override
  NdkBroadcastResponse handleEventBroadcast({
    required Nip01Event nostrEvent,
    required EventSigner? signer,
    required BroadcastState broadcastState,
    Iterable<String>? specificRelays,
  }) {
    throw UnimplementedError();
  }
}

class _DummySignerFactory implements LocalEventSignerFactory {
  @override
  EventSigner create({String? privateKey, String? publicKey}) {
    return _DummySigner(publicKey ?? 'dummy');
  }

  @override
  EventSigner createWithNewKeyPair() => _DummySigner('dummy-public');

  @override
  String derivePublicKey(String privateKey) => 'dummy';

  @override
  (String privateKey, String publicKey) generateKeyPair() =>
      ('dummy-private', 'dummy-public');
}

class _DummySigner implements EventSigner {
  final String pubKey;

  _DummySigner(this.pubKey);

  @override
  bool canSign() => false;

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async =>
      null;

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async =>
      null;

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async =>
      null;

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async =>
      null;

  @override
  String getPublicKey() => pubKey;

  @override
  List<PendingSignerRequest> get pendingRequests => const [];

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      const Stream.empty();

  @override
  Future<Nip01Event> sign(Nip01Event event) async => event;
}
