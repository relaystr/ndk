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
    final buffer = <Future<Nip01Event?>>[];

    await for (final event in unverifiedStreamInput) {
      // Start verification without waiting
      final future = _verifyEvent(event);
      buffer.add(future);

      // Once we hit max concurrent, wait for the first one to complete
      if (buffer.length >= maxConcurrent) {
        final verified = await buffer.first;
        buffer.removeAt(0);

        if (verified != null && verified.validSig == true) {
          yield verified;
        }
      }
    }

    // Process remaining events in buffer
    final remaining = await Future.wait(buffer);
    for (final event in remaining) {
      if (event != null && event.validSig == true) {
        yield event;
      }
    }
  }

  Future<Nip01Event?> _verifyEvent(Nip01Event data) async {
    final valid = await eventVerifier.verify(data);
    data.validSig = valid;

    if (!valid) {
      Logger.log.w('WARNING: Event with id ${data.id} has invalid signature');
    }

    return data;
  }
}
