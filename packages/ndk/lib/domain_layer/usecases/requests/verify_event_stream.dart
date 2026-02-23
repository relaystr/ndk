import 'package:rxdart/rxdart.dart';
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
    final valid = await eventVerifier.verify(data);

    if (!valid) {
      Logger.log
          .w(() => 'WARNING: Event with id ${data.id} has invalid signature');
      return null;
    }

    final checkedEvent = data.copyWith(validSig: valid);

    return checkedEvent;
  }
}
