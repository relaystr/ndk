import 'dart:async';

import 'package:ndk/data_layer/repositories/cache_manager/mem_cache_manager.dart';
import 'package:ndk/domain_layer/entities/cache_eviction.dart';
import 'package:ndk/domain_layer/usecases/cache_eviction/cache_eviction_scheduler.dart';
import 'package:test/test.dart';

void main() {
  group('CacheEvictionScheduler', () {
    test('runs once after startup delay and then periodically', () async {
      final cacheManager = _RecordingMemCacheManager();
      final scheduler = CacheEvictionScheduler(
        cacheManager: cacheManager,
        policy: const EvictionPolicy(),
        startupDelay: const Duration(milliseconds: 20),
        interval: const Duration(milliseconds: 30),
        runOnStartup: true,
      );

      scheduler.start();
      addTearDown(() => scheduler.stop());

      await _waitUntil(() => cacheManager.evictCallCount >= 1);
      await _waitUntil(() => cacheManager.evictCallCount >= 2);
    });

    test('can disable startup run and keep only periodic scheduling', () async {
      final cacheManager = _RecordingMemCacheManager();
      final scheduler = CacheEvictionScheduler(
        cacheManager: cacheManager,
        policy: const EvictionPolicy(),
        startupDelay: Duration.zero,
        interval: const Duration(milliseconds: 25),
        runOnStartup: false,
      );

      scheduler.start();
      addTearDown(() => scheduler.stop());

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cacheManager.evictCallCount, 0);

      await _waitUntil(() => cacheManager.evictCallCount >= 1);
      expect(cacheManager.evictCallCount, 1);
    });

    test('does not overlap long-running eviction executions', () async {
      final blocker = Completer<void>();
      final cacheManager = _RecordingMemCacheManager(
        onEvict: () => blocker.future,
      );
      final scheduler = CacheEvictionScheduler(
        cacheManager: cacheManager,
        policy: const EvictionPolicy(),
        startupDelay: Duration.zero,
        interval: const Duration(milliseconds: 15),
        runOnStartup: true,
      );

      scheduler.start();

      await _waitUntil(() => cacheManager.evictCallCount >= 1);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(cacheManager.evictCallCount, 1);

      blocker.complete();
      await _waitUntil(() => cacheManager.evictCallCount >= 2);

      await scheduler.stop();
    });
  });
}

class _RecordingMemCacheManager extends MemCacheManager {
  _RecordingMemCacheManager({
    this.onEvict,
  });

  int evictCallCount = 0;
  final Future<void> Function()? onEvict;

  @override
  Future<EvictionResult> evict(EvictionPolicy policy) async {
    evictCallCount += 1;
    await onEvict?.call();
    return EvictionResult.empty;
  }
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
