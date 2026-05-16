import 'dart:async';
import 'dart:collection';

/// Limits how many operations can be in flight at once.
///
/// Wrap each operation with [runThrottled]: up to [maxConcurrentRequests]
/// run in parallel, the rest queue FIFO and start as slots free up.
mixin ConcurrencyLimiterMixin {
  /// Maximum number of operations that can be in flight simultaneously.
  /// Implementers typically expose this via their constructor.
  int get maxConcurrentRequests;

  int _inFlight = 0;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  /// Operations currently running [runThrottled]'s task.
  int get inFlightRequests => _inFlight;

  /// Operations waiting for a free slot.
  int get queuedRequests => _waitQueue.length;

  /// Acquires a slot, runs [task], releases the slot.
  ///
  /// If the limit is reached, [task] is queued and started once a slot frees.
  /// Errors thrown by [task] still release the slot.
  Future<T> runThrottled<T>(Future<T> Function() task) async {
    await _acquireSlot();
    try {
      return await task();
    } finally {
      _releaseSlot();
    }
  }

  Future<void> _acquireSlot() {
    if (_inFlight < maxConcurrentRequests) {
      _inFlight++;
      return Future.value();
    }
    final waiter = Completer<void>();
    _waitQueue.add(waiter);
    return waiter.future;
  }

  void _releaseSlot() {
    if (_waitQueue.isNotEmpty) {
      // Hand the slot directly to the next waiter — counter stays the same.
      _waitQueue.removeFirst().complete();
    } else {
      _inFlight--;
    }
  }

  /// Rejects every queued (not-yet-started) operation. In-flight tasks
  /// keep running. Call from `dispose()` to drain pending work.
  void cancelAllQueued([Object? error]) {
    final reason =
        error ?? StateError('This instance is no longer accepting requests');
    while (_waitQueue.isNotEmpty) {
      final waiter = _waitQueue.removeFirst();
      if (!waiter.isCompleted) {
        waiter.completeError(reason);
      }
    }
  }
}
