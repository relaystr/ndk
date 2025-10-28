import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_verifier.dart';

class VerifyEventStream {
  final Stream<Nip01Event> unverifiedStreamInput;
  final EventVerifier eventVerifier;
  final int maxConcurrent;

  VerifyEventStream({
    required this.unverifiedStreamInput,
    required this.eventVerifier,
    this.maxConcurrent = 100,
  });

  Stream<Nip01Event> call() {
    return _verifyInParallel().asBroadcastStream();
  }

  Stream<Nip01Event> _verifyInParallel() async* {
    final activeFutures = <Future<Nip01Event?>>[];
    var inputClosed = false;

    // Listen to the input stream
    final inputSubscription = unverifiedStreamInput.listen(
      (event) {
        // Start verification without waiting
        final future = _verifyEvent(event);
        activeFutures.add(future);
      },
      onDone: () {
        inputClosed = true;
      },
    );

    try {
      // Continuously process completed futures
      while (!inputClosed || activeFutures.isNotEmpty) {
        if (activeFutures.isEmpty) {
          // Wait a bit for new events if input is still open
          if (!inputClosed) {
            await Future.delayed(Duration(milliseconds: 10));
            continue;
          } else {
            break;
          }
        }

        // Wait for any future to complete
        final completedIndex = await _waitForAnyToComplete(activeFutures);
        final completed = activeFutures.removeAt(completedIndex);
        final verified = await completed;

        // Yield the verified event if valid
        if (verified != null && verified.validSig == true) {
          yield verified;
        }

        // If we're at max capacity and input is still open, wait for more to complete
        while (activeFutures.length >= maxConcurrent && !inputClosed) {
          final nextCompletedIndex = await _waitForAnyToComplete(activeFutures);
          final nextCompleted = activeFutures.removeAt(nextCompletedIndex);
          final nextVerified = await nextCompleted;

          if (nextVerified != null && nextVerified.validSig == true) {
            yield nextVerified;
          }
        }
      }
    } finally {
      await inputSubscription.cancel();
    }
  }

  /// Wait for any future in the list to complete and return its index
  Future<int> _waitForAnyToComplete(List<Future<Nip01Event?>> futures) async {
    if (futures.isEmpty) {
      throw StateError('Cannot wait for completion on empty futures list');
    }

    // Use Future.any with indexed futures to find which one completed
    final indexedFutures = futures
        .asMap()
        .entries
        .map((entry) => entry.value.then((_) => entry.key));

    return await Future.any(indexedFutures);
  }

  Future<Nip01Event?> _verifyEvent(Nip01Event data) async {
    final valid = await eventVerifier.verify(data);
    data.validSig = valid;

    if (!valid) {
      Logger.log.w('WARNING: Event with id ${data.id} has invalid signature');
      return null;
    }

    return data;
  }
}
