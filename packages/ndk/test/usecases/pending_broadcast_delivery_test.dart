import 'dart:async';

import 'package:ndk/data_layer/repositories/cache_manager/mem_cache_manager.dart';
import 'package:ndk/domain_layer/entities/broadcast_response.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/domain_layer/entities/event_cache_records.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/pending_signer_request.dart';
import 'package:ndk/domain_layer/entities/signer_request_rejected_exception.dart';
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
    late Accounts accounts;
    late Nip01Event event;
    late List<String> reconnectAttempts;

    setUp(() async {
      cacheManager = MemCacheManager();
      broadcast = RecordingBroadcastSender(cacheManager: cacheManager);
      accounts = Accounts(_DummySignerFactory());
      pendingDelivery = PendingBroadcastDelivery(
        cacheManager: cacheManager,
        broadcastSender: broadcast,
        accounts: accounts,
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

    tearDown(() async {
      await pendingDelivery.stop();
    });

    test('does not rebroadcast permanent failures during due flush', () async {
      await cacheManager.saveRelayDeliveryTarget(
        RelayDeliveryTarget(
          eventId: event.id,
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
          state: RelayDeliveryState.permanentFailure,
          attemptCount: 1,
          lastAttemptAt: 1700000001,
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
        RelayDeliveryTarget(
          eventId: event.id,
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
          state: RelayDeliveryState.authRequired,
          attemptCount: 1,
          lastAttemptAt: now,
          nextRetryAt: now + 60,
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
        RelayDeliveryTarget(
          eventId: event.id,
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
          state: RelayDeliveryState.authRequired,
          attemptCount: 1,
          lastAttemptAt: now - 60,
          nextRetryAt: now - 1,
        ),
      );

      await pendingDelivery.flushForRelay(
        'wss://relay.example',
        onlyDue: true,
      );

      expect(broadcast.broadcastedEvents.map((e) => e.id), [event.id]);
    });

    test(
        'periodic retry forces reconnect for disconnected relays with due targets',
        () async {
      final now = Nip01Event.secondsSinceEpoch();
      await cacheManager.saveRelayDeliveryTarget(
        RelayDeliveryTarget(
          eventId: event.id,
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
          state: RelayDeliveryState.pending,
          attemptCount: 0,
          lastAttemptAt: now - 60,
          nextRetryAt: now - 1,
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

    test('signs remote-signer events before broadcasting', () async {
      final unsignedEvent = Nip01Event(
        id: 'event-remote-sign',
        pubKey: 'remote-pubkey',
        createdAt: 1700000100,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'needs signing',
      );
      final signer = _RemoteTestSigner(
        pubKey: unsignedEvent.pubKey,
        onSign: (event) async => event.copyWith(sig: 'remote-sig'),
      );
      accounts.loginExternalSigner(signer: signer);

      await cacheManager.saveEvent(unsignedEvent);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: unsignedEvent.id,
          status: EventDeliveryStatus.pending,
          signingState: EventSigningState.pending,
          createdAt: unsignedEvent.createdAt,
          updatedAt: unsignedEvent.createdAt,
          requiresInteractiveSigning: true,
        ),
      );
      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-remote-sign',
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );

      await pendingDelivery.flushForRelay('wss://relay.example');

      final savedEvent = await cacheManager.loadEvent(unsignedEvent.id);
      final savedRecord =
          await cacheManager.loadEventDeliveryRecord(unsignedEvent.id);

      expect(savedEvent?.sig, 'remote-sig');
      expect(savedRecord?.signingState, EventSigningState.signed);
      expect(broadcast.broadcastedEvents.map((e) => e.id), [unsignedEvent.id]);
      expect(broadcast.broadcastedEvents.single.sig, 'remote-sig');
    });

    test('rejected remote signing becomes needsAction and does not broadcast',
        () async {
      final unsignedEvent = Nip01Event(
        id: 'event-remote-rejected',
        pubKey: 'remote-pubkey-rejected',
        createdAt: 1700000200,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'needs approval',
      );
      final signer = _RemoteTestSigner(
        pubKey: unsignedEvent.pubKey,
        onSign: (_) => Future.error(
          SignerRequestRejectedException(
            requestId: 'req-1',
            originalMessage: 'user rejected',
          ),
        ),
      );
      accounts.loginExternalSigner(signer: signer);

      await cacheManager.saveEvent(unsignedEvent);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: unsignedEvent.id,
          status: EventDeliveryStatus.pending,
          signingState: EventSigningState.pending,
          createdAt: unsignedEvent.createdAt,
          updatedAt: unsignedEvent.createdAt,
          requiresInteractiveSigning: true,
        ),
      );
      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-remote-rejected',
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );

      await pendingDelivery.flushForRelay('wss://relay.example');

      final savedEvent = await cacheManager.loadEvent(unsignedEvent.id);
      final savedRecord =
          await cacheManager.loadEventDeliveryRecord(unsignedEvent.id);

      expect(savedEvent?.sig, isNull);
      expect(savedRecord?.signingState, EventSigningState.needsAction);
      expect(savedRecord?.status, EventDeliveryStatus.needsAction);
      expect(broadcast.broadcastedEvents, isEmpty);
    });

    test(
        'timed out signing attempt does not block a later retry forever if the original future never completes',
        () async {
      await pendingDelivery.stop();
      pendingDelivery = PendingBroadcastDelivery(
        cacheManager: cacheManager,
        broadcastSender: broadcast,
        accounts: accounts,
        signAttemptTimeout: const Duration(milliseconds: 20),
      );

      final hangingCompleter = Completer<Nip01Event>();
      var signAttempts = 0;
      final unsignedEvent = Nip01Event(
        id: 'event-remote-timeout-stall',
        pubKey: 'remote-timeout-stall-pubkey',
        createdAt: 1700000250,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'first sign hangs forever',
      );
      final signer = _RemoteTestSigner(
        pubKey: unsignedEvent.pubKey,
        onSign: (event) {
          signAttempts += 1;
          if (signAttempts == 1) {
            return hangingCompleter.future;
          }
          return Future.value(event.copyWith(sig: 'signed-after-retry'));
        },
      );
      accounts.loginExternalSigner(signer: signer);

      await cacheManager.saveEvent(unsignedEvent);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: unsignedEvent.id,
          status: EventDeliveryStatus.pending,
          signingState: EventSigningState.pending,
          createdAt: unsignedEvent.createdAt,
          updatedAt: unsignedEvent.createdAt,
          requiresInteractiveSigning: true,
        ),
      );
      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-remote-timeout-stall',
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );

      await pendingDelivery.flushForRelay('wss://relay.example');

      final afterTimeoutRecord =
          await cacheManager.loadEventDeliveryRecord(unsignedEvent.id);
      expect(afterTimeoutRecord?.signingState, EventSigningState.transientFailure);
      expect(signer.signCallCount, 1);
      expect(broadcast.broadcastedEvents, isEmpty);

      await pendingDelivery.flushForRelay('wss://relay.example');

      final savedEvent = await cacheManager.loadEvent(unsignedEvent.id);
      final savedRecord =
          await cacheManager.loadEventDeliveryRecord(unsignedEvent.id);

      expect(signer.signCallCount, 2);
      expect(savedEvent?.sig, 'signed-after-retry');
      expect(savedRecord?.signingState, EventSigningState.signed);
      expect(
        broadcast.broadcastedEvents.map((e) => e.id),
        [unsignedEvent.id],
      );
    });

    test(
        'skips network signer attempt while signer transport relays are offline',
        () async {
      pendingDelivery.startPeriodicRetry(
        connectedRelayUrls: () => const <String>{'wss://target-relay.example'},
        reconnectRelay: (_) async => false,
        retryInterval: const Duration(hours: 1),
      );

      final unsignedEvent = Nip01Event(
        id: 'event-bunker-offline',
        pubKey: 'bunker-offline-pubkey',
        createdAt: 1700000300,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'offline bunker',
      );
      final signer = _RemoteTestSigner(
        pubKey: unsignedEvent.pubKey,
        requiresSignerNetwork: true,
        transportRelayUrls: const ['wss://bunker-relay.example'],
        onSign: (event) async => event.copyWith(sig: 'should-not-happen'),
      );
      accounts.loginExternalSigner(signer: signer);

      await cacheManager.saveEvent(unsignedEvent);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: unsignedEvent.id,
          status: EventDeliveryStatus.pending,
          signingState: EventSigningState.pending,
          createdAt: unsignedEvent.createdAt,
          updatedAt: unsignedEvent.createdAt,
          requiresInteractiveSigning: true,
        ),
      );
      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-bunker-offline',
          relayUrl: 'wss://target-relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );

      await pendingDelivery.flushForRelay('wss://target-relay.example');

      final savedEvent = await cacheManager.loadEvent(unsignedEvent.id);
      final savedRecord =
          await cacheManager.loadEventDeliveryRecord(unsignedEvent.id);

      expect(signer.signCallCount, 0);
      expect(savedEvent?.sig, isNull);
      expect(savedRecord?.signingState, EventSigningState.pending);
      expect(broadcast.broadcastedEvents, isEmpty);
    });

    test(
        'transport relay opening retries network signing and immediately flushes connected targets',
        () async {
      pendingDelivery.startPeriodicRetry(
        connectedRelayUrls: () => const <String>{
          'wss://bunker-relay.example',
          'wss://target-relay.example',
        },
        reconnectRelay: (_) async => false,
        retryInterval: const Duration(hours: 1),
      );

      final unsignedEvent = Nip01Event(
        id: 'event-bunker-online',
        pubKey: 'bunker-online-pubkey',
        createdAt: 1700000400,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'online bunker',
      );
      final signer = _RemoteTestSigner(
        pubKey: unsignedEvent.pubKey,
        requiresSignerNetwork: true,
        transportRelayUrls: const ['wss://bunker-relay.example'],
        onSign: (event) async => event.copyWith(sig: 'bunker-sig'),
      );
      accounts.loginExternalSigner(signer: signer);

      await cacheManager.saveEvent(unsignedEvent);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: unsignedEvent.id,
          status: EventDeliveryStatus.pending,
          signingState: EventSigningState.pending,
          createdAt: unsignedEvent.createdAt,
          updatedAt: unsignedEvent.createdAt,
          requiresInteractiveSigning: true,
        ),
      );
      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-bunker-online',
          relayUrl: 'wss://target-relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );

      await pendingDelivery.retryInteractiveSigningForTransportRelay(
        'wss://bunker-relay.example',
      );

      final savedEvent = await cacheManager.loadEvent(unsignedEvent.id);
      final savedRecord =
          await cacheManager.loadEventDeliveryRecord(unsignedEvent.id);

      expect(signer.signCallCount, 1);
      expect(savedEvent?.sig, 'bunker-sig');
      expect(savedRecord?.signingState, EventSigningState.signed);
      expect(broadcast.broadcastedEvents.map((e) => e.id), [unsignedEvent.id]);
      expect(broadcast.broadcastedEvents.single.sig, 'bunker-sig');
    });

    test('non-matching transport relay opening does not retry network signer',
        () async {
      pendingDelivery.startPeriodicRetry(
        connectedRelayUrls: () => const <String>{
          'wss://other-relay.example',
          'wss://target-relay.example',
        },
        reconnectRelay: (_) async => false,
        retryInterval: const Duration(hours: 1),
      );

      final unsignedEvent = Nip01Event(
        id: 'event-bunker-other-relay',
        pubKey: 'bunker-other-relay-pubkey',
        createdAt: 1700000500,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'wrong relay',
      );
      final signer = _RemoteTestSigner(
        pubKey: unsignedEvent.pubKey,
        requiresSignerNetwork: true,
        transportRelayUrls: const ['wss://bunker-relay.example'],
        onSign: (event) async => event.copyWith(sig: 'should-not-sign'),
      );
      accounts.loginExternalSigner(signer: signer);

      await cacheManager.saveEvent(unsignedEvent);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: unsignedEvent.id,
          status: EventDeliveryStatus.pending,
          signingState: EventSigningState.pending,
          createdAt: unsignedEvent.createdAt,
          updatedAt: unsignedEvent.createdAt,
          requiresInteractiveSigning: true,
        ),
      );
      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-bunker-other-relay',
          relayUrl: 'wss://target-relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );

      await pendingDelivery.retryInteractiveSigningForTransportRelay(
        'wss://other-relay.example',
      );

      final savedEvent = await cacheManager.loadEvent(unsignedEvent.id);
      expect(signer.signCallCount, 0);
      expect(savedEvent?.sig, isNull);
      expect(broadcast.broadcastedEvents, isEmpty);
    });

    test('network signer transient failure uses slower retry backoff',
        () async {
      pendingDelivery.startPeriodicRetry(
        connectedRelayUrls: () => const <String>{'wss://bunker-relay.example'},
        reconnectRelay: (_) async => false,
        retryInterval: const Duration(hours: 1),
      );

      final unsignedEvent = Nip01Event(
        id: 'event-bunker-backoff',
        pubKey: 'bunker-backoff-pubkey',
        createdAt: 1700000600,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'backoff bunker',
      );
      final signer = _RemoteTestSigner(
        pubKey: unsignedEvent.pubKey,
        requiresSignerNetwork: true,
        transportRelayUrls: const ['wss://bunker-relay.example'],
        onSign: (_) => Future.error(Exception('temporary outage')),
      );
      accounts.loginExternalSigner(signer: signer);

      await cacheManager.saveEvent(unsignedEvent);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: unsignedEvent.id,
          status: EventDeliveryStatus.pending,
          signingState: EventSigningState.pending,
          createdAt: unsignedEvent.createdAt,
          updatedAt: unsignedEvent.createdAt,
          requiresInteractiveSigning: true,
        ),
      );
      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-bunker-backoff',
          relayUrl: 'wss://target-relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );

      await pendingDelivery.retryInteractiveSigningForTransportRelay(
        'wss://bunker-relay.example',
      );

      final savedRecord =
          await cacheManager.loadEventDeliveryRecord(unsignedEvent.id);

      expect(savedRecord?.signingState, EventSigningState.transientFailure);
      expect(savedRecord, isNotNull);
      expect(savedRecord!.nextSignRetryAt, isNotNull);
      expect(savedRecord.nextSignRetryAt! - savedRecord.updatedAt, 15);
    });

    test(
        'non-network interactive signer transient failure uses faster retry backoff',
        () async {
      final unsignedEvent = Nip01Event(
        id: 'event-local-backoff',
        pubKey: 'local-backoff-pubkey',
        createdAt: 1700000700,
        kind: Nip01Event.kTextNodeKind,
        tags: const [],
        content: 'backoff local',
      );
      final signer = _RemoteTestSigner(
        pubKey: unsignedEvent.pubKey,
        requiresSignerNetwork: false,
        onSign: (_) => Future.error(Exception('temporary local failure')),
      );
      accounts.loginExternalSigner(signer: signer);

      await cacheManager.saveEvent(unsignedEvent);
      await cacheManager.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: unsignedEvent.id,
          status: EventDeliveryStatus.pending,
          signingState: EventSigningState.pending,
          createdAt: unsignedEvent.createdAt,
          updatedAt: unsignedEvent.createdAt,
          requiresInteractiveSigning: true,
        ),
      );
      await cacheManager.saveRelayDeliveryTarget(
        const RelayDeliveryTarget(
          eventId: 'event-local-backoff',
          relayUrl: 'wss://target-relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );

      await pendingDelivery.flushForRelay('wss://target-relay.example');

      final savedRecord =
          await cacheManager.loadEventDeliveryRecord(unsignedEvent.id);

      expect(savedRecord?.signingState, EventSigningState.transientFailure);
      expect(savedRecord, isNotNull);
      expect(savedRecord!.nextSignRetryAt, isNotNull);
      expect(savedRecord.nextSignRetryAt! - savedRecord.updatedAt, 5);
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
  bool get requiresInteractiveSigning => false;

  @override
  bool get requiresSignerNetwork => false;

  @override
  Iterable<String> get signerTransportRelayUrls => const <String>[];

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

class _RemoteTestSigner implements EventSigner {
  final String pubKey;
  final Future<Nip01Event> Function(Nip01Event event) onSign;
  final List<PendingSignerRequest> _pendingRequests;
  final bool _requiresSignerNetwork;
  final List<String> _transportRelayUrls;
  int signCallCount = 0;

  _RemoteTestSigner({
    required this.pubKey,
    required this.onSign,
    bool requiresSignerNetwork = false,
    List<String>? transportRelayUrls,
    List<PendingSignerRequest>? pendingRequests,
  })  : _pendingRequests = pendingRequests ?? [],
        _requiresSignerNetwork = requiresSignerNetwork,
        _transportRelayUrls = transportRelayUrls ?? const [];

  @override
  bool get requiresInteractiveSigning => true;

  @override
  bool get requiresSignerNetwork => _requiresSignerNetwork;

  @override
  Iterable<String> get signerTransportRelayUrls =>
      List<String>.unmodifiable(_transportRelayUrls);

  @override
  bool canSign() => true;

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
  List<PendingSignerRequest> get pendingRequests =>
      List<PendingSignerRequest>.unmodifiable(_pendingRequests);

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      Stream.value(pendingRequests);

  @override
  Future<Nip01Event> sign(Nip01Event event) {
    signCallCount += 1;
    return onSign(event);
  }
}
