import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_verifier.dart';

class VerifyEventStream {
  final Stream<Nip01Event> unverifiedStreamInput;
  final EventVerifier eventVerifier;
  VerifyEventStream({
    required this.unverifiedStreamInput,
    required this.eventVerifier,
  });

  Stream<Nip01Event> call() {
    return unverifiedStreamInput
        .asyncMap<Nip01Event>((data) async {
          final valid = await eventVerifier.verify(data);
          if (valid) {
            data.validSig = true;
            return data;
          } else {
            Logger.log.w("🔑⛔ Invalid signature on event: $data");
            data.validSig = false;
            return data;
          }
        })
        .where((event) => event.validSig == true) // Filter out invalid events
        .asBroadcastStream();
  }
}
