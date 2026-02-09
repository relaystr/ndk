import 'package:rxdart/rxdart.dart';
import '../../../shared/logger/logger.dart';
import '../../../simple_profiler.dart';
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

  final profiler = SimpleProfiler('VerifyEventStream');

  Stream<Nip01Event> call() {
    profiler.checkpoint('Starting to process unverified event stream');
    return unverifiedStreamInput
        .flatMap(
          (event) => Stream.fromFuture(_verifyEvent(event)),
          maxConcurrent: maxConcurrent,
        )
        .where((event) => event?.validSig == true)
        .whereType<Nip01Event>() // filter nulls
        .shareReplay(maxSize: 1);
  }

  Future<Nip01Event?> _verifyEvent(Nip01Event data) async {
    profiler.checkpoint('Verifying event with id ${data.id}');
    final valid = await eventVerifier.verify(data);

    if (!valid) {
      Logger.log.w('WARNING: Event with id ${data.id} has invalid signature');
      return null;
    }
    profiler.checkpoint('Event with id ${data.id} has valid signature');

    final checkedEvent = data.copyWith(validSig: valid);

    profiler.checkpoint('Finished copyWith event with id ${data.id}');

    return checkedEvent;
  }
}
