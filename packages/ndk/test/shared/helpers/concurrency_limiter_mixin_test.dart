import 'dart:async';
import 'dart:math';

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

class _Limiter with ConcurrencyLimiterMixin {
  @override
  final int maxConcurrentRequests;
  _Limiter(this.maxConcurrentRequests)
      : assert(maxConcurrentRequests > 0, 'maxConcurrentRequests must be > 0');
}

/// Mimics the way a real signer (NIP-07, NIP-55, NIP-46) drives the mixin:
/// each operation is wrapped in `runThrottled`, and we observe the number
/// of operations that are *actually* executing at the same time.
class _PeakTrackingSigner with ConcurrencyLimiterMixin {
  @override
  final int maxConcurrentRequests;
  int _active = 0;
  int peakInFlight = 0;

  _PeakTrackingSigner(this.maxConcurrentRequests);

  Future<T> doWork<T>(Future<T> Function() op) {
    return runThrottled(() async {
      _active++;
      peakInFlight = max(peakInFlight, _active);
      try {
        return await op();
      } finally {
        _active--;
      }
    });
  }
}

void main() {
  group('ConcurrencyLimiterMixin', () {
    test('runs immediately when below the limit', () async {
      final limiter = _Limiter(3);
      final result = await limiter.runThrottled(() async => 42);
      expect(result, 42);
      expect(limiter.inFlightRequests, 0);
      expect(limiter.queuedRequests, 0);
    });

    test('queues operations beyond the limit and runs them in FIFO order',
        () async {
      final limiter = _Limiter(2);
      final gates = List.generate(4, (_) => Completer<void>());
      final completionOrder = <int>[];

      final futures = <Future<void>>[];
      for (var i = 0; i < 4; i++) {
        futures.add(limiter.runThrottled(() async {
          await gates[i].future;
          completionOrder.add(i);
        }));
      }

      // Let the event loop process the acquire calls.
      await Future<void>.delayed(Duration.zero);
      expect(limiter.inFlightRequests, 2);
      expect(limiter.queuedRequests, 2);

      // Finish #1 first; #2 should pick up the slot, not #3.
      gates[1].complete();
      await Future<void>.delayed(Duration.zero);
      expect(completionOrder, [1]);
      expect(limiter.inFlightRequests, 2);
      expect(limiter.queuedRequests, 1);

      gates[0].complete();
      gates[2].complete();
      gates[3].complete();
      await Future.wait(futures);

      expect(completionOrder, [1, 0, 2, 3]);
      expect(limiter.inFlightRequests, 0);
      expect(limiter.queuedRequests, 0);
    });

    test('releases the slot even when the task throws', () async {
      final limiter = _Limiter(1);
      await expectLater(
        limiter.runThrottled<void>(() async => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );
      expect(limiter.inFlightRequests, 0);

      final result = await limiter.runThrottled(() async => 'ok');
      expect(result, 'ok');
    });

    test('asserts maxConcurrentRequests > 0', () {
      expect(() => _Limiter(0), throwsA(isA<AssertionError>()));
      expect(() => _Limiter(-1), throwsA(isA<AssertionError>()));
    });

    test('peak in-flight never exceeds maxConcurrentRequests under load',
        () async {
      final signer = _PeakTrackingSigner(2);
      final completers = List.generate(10, (_) => Completer<void>());

      final futures = List.generate(
        10,
        (i) => signer.doWork(() => completers[i].future),
      );

      // Resolve the gates in shuffled order to mimic out-of-order responses
      // from a remote signer (e.g. bunker, browser extension).
      final order = [3, 0, 7, 1, 9, 4, 2, 8, 5, 6];
      for (final i in order) {
        completers[i].complete();
        // Yield so the mixin can release the slot and start the next waiter
        // before we resolve the following gate.
        await Future<void>.delayed(Duration.zero);
      }

      await Future.wait(futures);

      expect(signer.peakInFlight, 2,
          reason: 'no more than 2 operations should ever run in parallel');
      expect(signer.inFlightRequests, 0);
      expect(signer.queuedRequests, 0);
    });

    test('a queued task that detects cancellation can skip its work entirely',
        () async {
      // Mirrors the pattern each remote signer uses: the lambda passed to
      // runThrottled checks shared state when it gets a slot and bails out
      // before touching the network if the caller no longer wants the call.
      final limiter = _Limiter(1);
      final cancelled = <int>{};
      final executed = <int>[];

      final blocker = Completer<void>();
      final inFlight = limiter.runThrottled(() async {
        executed.add(0);
        await blocker.future;
      });

      await Future<void>.delayed(Duration.zero);

      final queued = limiter.runThrottled(() async {
        if (cancelled.contains(1)) {
          throw StateError('cancelled before execution');
        }
        executed.add(1);
      });

      await Future<void>.delayed(Duration.zero);
      cancelled.add(1);
      blocker.complete();

      await expectLater(queued, throwsA(isA<StateError>()));
      await inFlight;

      expect(executed, [0],
          reason: 'cancelled task must not run when its slot frees');
      expect(limiter.inFlightRequests, 0);
    });

    test('cancelAllQueued rejects pending waiters but spares in-flight tasks',
        () async {
      final limiter = _Limiter(1);
      final running = Completer<void>();
      final inFlight = limiter.runThrottled(() async {
        await running.future;
        return 'done';
      });

      await Future<void>.delayed(Duration.zero);

      final queued1 = limiter.runThrottled(() async => 'never');
      final queued2 = limiter.runThrottled(() async => 'never');

      await Future<void>.delayed(Duration.zero);
      expect(limiter.queuedRequests, 2);

      limiter.cancelAllQueued();

      await expectLater(queued1, throwsA(isA<StateError>()));
      await expectLater(queued2, throwsA(isA<StateError>()));
      expect(limiter.queuedRequests, 0);

      running.complete();
      expect(await inFlight, 'done');
    });
  });
}
