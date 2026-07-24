import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/domain_layer/entities/event_cache_records.dart';
import 'package:ndk_drift/ndk_drift.dart';
import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';

void main() {
  test('persists full event delivery record state', () async {
    final db = NdkCacheDatabase.forTesting(NativeDatabase.memory());
    final cacheManager = DriftCacheManager(db);

    final original = EventDeliveryRecord(
      eventId: 'event-1',
      status: EventDeliveryStatus.needsAction,
      signingState: EventSigningState.transientFailure,
      createdAt: 1700000000,
      updatedAt: 1700000100,
      serializedEventJson: '{"id":"event-1"}',
      signedAt: 1700000050,
      completedAt: 1700000200,
      requiresInteractiveSigning: true,
      signAttemptCount: 3,
      lastSignAttemptAt: 1700000090,
      nextSignRetryAt: 1700000400,
      lastSignError: 'timed out waiting for signer',
    );

    await cacheManager.saveEventDeliveryRecord(original);
    final restored = await cacheManager.loadEventDeliveryRecord(
      original.eventId,
    );

    expect(restored, isNotNull);
    expect(restored!.status, original.status);
    expect(restored.signingState, original.signingState);
    expect(restored.createdAt, original.createdAt);
    expect(restored.updatedAt, original.updatedAt);
    expect(restored.serializedEventJson, original.serializedEventJson);
    expect(restored.signedAt, original.signedAt);
    expect(restored.completedAt, original.completedAt);
    expect(
      restored.requiresInteractiveSigning,
      original.requiresInteractiveSigning,
    );
    expect(restored.signAttemptCount, original.signAttemptCount);
    expect(restored.lastSignAttemptAt, original.lastSignAttemptAt);
    expect(restored.nextSignRetryAt, original.nextSignRetryAt);
    expect(restored.lastSignError, original.lastSignError);

    await cacheManager.close();
  });

  runCacheManagerTestSuite(
    name: 'DriftCacheManager',
    createCacheManager: () async {
      final db = NdkCacheDatabase.forTesting(NativeDatabase.memory());
      return DriftCacheManager(db);
    },
    cleanUp: (cm) async {
      await cm.close();
    },
  );
}
