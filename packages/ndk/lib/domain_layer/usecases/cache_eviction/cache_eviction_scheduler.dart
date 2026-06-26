import 'dart:async';

import '../../../shared/logger/logger.dart';
import '../../entities/cache_eviction.dart';
import '../../repositories/cache_manager.dart';

/// Background scheduler that periodically runs [CacheManager.evict].
///
/// This intentionally does only scheduling and overlap protection. The actual
/// eviction logic stays inside cache backends and [EvictionPolicy].
class CacheEvictionScheduler {
  final CacheManager _cacheManager;
  final EvictionPolicy _policy;
  final Duration _startupDelay;
  final Duration _interval;
  final bool _runOnStartup;
  final void Function(EvictionResult result)? _onRunCompleted;

  Timer? _startupTimer;
  Timer? _intervalTimer;
  Future<void>? _runInFlight;

  CacheEvictionScheduler({
    required CacheManager cacheManager,
    required EvictionPolicy policy,
    required Duration startupDelay,
    required Duration interval,
    required bool runOnStartup,
    void Function(EvictionResult result)? onRunCompleted,
  })  : _cacheManager = cacheManager,
        _policy = policy,
        _startupDelay = startupDelay,
        _interval = interval,
        _runOnStartup = runOnStartup,
        _onRunCompleted = onRunCompleted;

  /// Starts startup and periodic timers.
  void start() {
    _startupTimer?.cancel();
    _intervalTimer?.cancel();

    if (_runOnStartup) {
      if (_startupDelay <= Duration.zero) {
        unawaited(runNow(reason: 'startup'));
      } else {
        _startupTimer = Timer(
          _startupDelay,
          () => unawaited(runNow(reason: 'startup')),
        );
      }
    }

    if (_interval > Duration.zero) {
      _intervalTimer = Timer.periodic(
        _interval,
        (_) => unawaited(runNow(reason: 'interval')),
      );
    }
  }

  /// Stops timers and waits for any in-flight run to finish.
  Future<void> stop() async {
    _startupTimer?.cancel();
    _startupTimer = null;
    _intervalTimer?.cancel();
    _intervalTimer = null;

    final inFlight = _runInFlight;
    if (inFlight != null) {
      await inFlight;
    }
  }

  /// Triggers an immediate run unless another run is already active.
  Future<void> runNow({String reason = 'manual'}) {
    final inFlight = _runInFlight;
    if (inFlight != null) {
      Logger.log.t(
        () => 'skip cache eviction run ($reason) because another run is active',
      );
      return inFlight;
    }

    final future = _run(reason: reason);
    _runInFlight = future;
    return future;
  }

  Future<void> _run({required String reason}) async {
    try {
      Logger.log.d(() => 'running cache eviction ($reason)');
      final result = await _cacheManager.evict(_policy);
      _onRunCompleted?.call(result);
      Logger.log.d(
        () =>
            'cache eviction finished ($reason): removed=${result.removedEvents}, '
            'expired=${result.removedExpired}, deleted=${result.removedDeleted}, '
            'superseded=${result.removedSuperseded}, capped=${result.removedByKindCap}',
      );
    } catch (e, st) {
      Logger.log.e(
        () => 'cache eviction failed ($reason): $e',
        error: e,
        stackTrace: st,
      );
    } finally {
      _runInFlight = null;
    }
  }
}
