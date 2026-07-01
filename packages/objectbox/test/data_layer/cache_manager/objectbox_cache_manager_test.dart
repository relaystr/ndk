// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';

void main() async {
  // Run shared test suite for comprehensive coverage
  late Directory sharedTempDir;

  runCacheManagerTestSuite(
    name: 'ObjectBoxCacheManager (Shared Suite)',
    createCacheManager: () async {
      sharedTempDir =
          await Directory.systemTemp.createTemp('objectbox_shared_test');
      final cacheManager = DbObjectBox(directory: sharedTempDir.path);
      await cacheManager.dbRdy;
      return cacheManager;
    },
    cleanUp: (cacheManager) async {
      await cacheManager.close();
      try {
        await sharedTempDir.delete(recursive: true);
      } catch (_) {}
    },
  );

  test('saveProofs and getProofs', () async {
    sharedTempDir =
        await Directory.systemTemp.createTemp('objectbox_shared_test');
    final cacheManager = DbObjectBox(directory: sharedTempDir.path);
    await cacheManager.dbRdy;

    final proof = CashuProof(
      keysetId: 'test_keyset',
      amount: 10,
      secret: 'test_secret',
      unblindedSig: 'test_sig',
      state: CashuProofState.unspend,
    );

    final cashuKeyset = CahsuKeyset(
      id: 'test_keyset',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
      mintUrl: 'https://test.mint.com',
      unit: 'sat',
    );
    cacheManager.saveKeyset(cashuKeyset);

    await cacheManager
        .saveProofs(proofs: [proof], mintUrl: 'https://test.mint.com');
    final loadedProofs = await cacheManager.getProofs(
      mintUrl: 'https://test.mint.com',
      state: CashuProofState.unspend,
    );

    expect(loadedProofs.length, equals(1));
    expect(loadedProofs[0].keysetId, equals(proof.keysetId));
    expect(loadedProofs[0].amount, equals(proof.amount));
  });

  test('reopen persists event sidecar records', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'objectbox_restart_test',
    );

    try {
      final first = DbObjectBox(directory: tempDir.path);
      await first.dbRdy;

      const deliveryRecord = EventDeliveryRecord(
        eventId: 'event-1',
        status: EventDeliveryStatus.inProgress,
        signingState: EventSigningState.pending,
        createdAt: 1700000000,
        updatedAt: 1700000100,
        serializedEventJson: '{"id":"event-1"}',
        requiresInteractiveSigning: true,
        signAttemptCount: 2,
        lastSignAttemptAt: 1700000090,
        nextSignRetryAt: 1700000400,
        lastSignError: 'signer unavailable',
      );
      const relayTarget = RelayDeliveryTarget(
        eventId: 'event-1',
        relayUrl: 'wss://relay.example',
        reason: RelayDeliveryReason.explicit,
        state: RelayDeliveryState.permanentFailure,
        attemptCount: 3,
        lastAttemptAt: 1700000091,
        nextRetryAt: 1700000500,
        lastError: 'timeout',
      );
      const decryptedRecord = DecryptedEventPayloadRecord(
        eventId: 'event-1',
        viewerPubKey: 'viewer-1',
        scheme: DecryptedPayloadScheme.nip04,
        status: DecryptedPayloadStatus.ready,
        plaintextContent: 'hello',
        createdAt: 1700000000,
        updatedAt: 1700000100,
        decryptedAt: 1700000101,
        sourceEventPubKey: 'author-1',
        sourceEventKind: 4,
      );

      await first.addEventSources(
        eventId: 'event-1',
        relayUrls: const ['wss://relay-a.example', 'wss://relay-b.example'],
      );
      await first.saveEventDeliveryRecord(deliveryRecord);
      await first.saveRelayDeliveryTarget(relayTarget);
      await first.saveDecryptedEventPayloadRecord(decryptedRecord);
      await first.close();

      final reopened = DbObjectBox(directory: tempDir.path);
      await reopened.dbRdy;

      expect(
        await reopened.loadEventSources('event-1'),
        unorderedEquals(['wss://relay-a.example', 'wss://relay-b.example']),
      );
      expect(
        await reopened.loadEventDeliveryRecord('event-1'),
        isNotNull,
      );
      expect(
        await reopened.loadRelayDeliveryTarget(
          eventId: 'event-1',
          relayUrl: 'wss://relay.example',
        ),
        isNotNull,
      );
      expect(
        await reopened.loadDecryptedEventPayloadRecord(
          eventId: 'event-1',
          viewerPubKey: 'viewer-1',
        ),
        isNotNull,
      );

      await reopened.close();
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test('reopen keeps expired event locked by persisted delivery record',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'objectbox_evict_restart_test',
    );

    try {
      final first = DbObjectBox(directory: tempDir.path);
      await first.dbRdy;

      final expiredEvent = Nip01Event(
        pubKey: 'locked_after_restart_delivery',
        kind: 1,
        tags: const [
          ['expiration', '1'],
        ],
        content: 'expired but queued',
        createdAt: 11,
      );

      await first.saveEvent(expiredEvent);
      await first.saveEventDeliveryRecord(
        EventDeliveryRecord(
          eventId: expiredEvent.id,
          createdAt: 11,
          updatedAt: 11,
        ),
      );
      await first.close();

      final reopened = DbObjectBox(directory: tempDir.path);
      await reopened.dbRdy;

      final result = await reopened.evict(const EvictionPolicy.safeSweep());

      expect(result.removedEvents, equals(0));
      expect(result.keptDueToDeliveryState, equals(1));
      expect(await reopened.loadEvent(expiredEvent.id), isNotNull);

      await reopened.close();
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test('reopen keeps expired event locked by persisted relay target', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'objectbox_evict_restart_test',
    );

    try {
      final first = DbObjectBox(directory: tempDir.path);
      await first.dbRdy;

      final expiredEvent = Nip01Event(
        pubKey: 'locked_after_restart_target',
        kind: 1,
        tags: const [
          ['expiration', '1'],
        ],
        content: 'expired but waiting for relay',
        createdAt: 12,
      );

      await first.saveEvent(expiredEvent);
      await first.saveRelayDeliveryTarget(
        RelayDeliveryTarget(
          eventId: expiredEvent.id,
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.explicit,
        ),
      );
      await first.close();

      final reopened = DbObjectBox(directory: tempDir.path);
      await reopened.dbRdy;

      final result = await reopened.evict(const EvictionPolicy.safeSweep());

      expect(result.removedEvents, equals(0));
      expect(result.keptDueToDeliveryState, equals(1));
      expect(await reopened.loadEvent(expiredEvent.id), isNotNull);

      await reopened.close();
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });
}
