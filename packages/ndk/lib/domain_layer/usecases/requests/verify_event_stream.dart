import 'package:rxdart/rxdart.dart';

import 'verified_event_cache.dart';
import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_verifier.dart';

class VerifyEventStream {
  final Stream<Nip01Event> unverifiedStreamInput;
  final EventVerifier eventVerifier;
  final int maxConcurrent;

  /// ids already checked. Defaults to a stream-local cache so duplicates
  /// delivered within this stream are deduped even without a shared one.
  final VerifiedEventMemCache _cache;

  VerifyEventStream({
    required this.unverifiedStreamInput,
    required this.eventVerifier,
    this.maxConcurrent = 100,
    VerifiedEventMemCache? verifiedEventCache,
  }) : _cache = verifiedEventCache ?? VerifiedEventMemCache();

  Stream<Nip01Event> call() {
    return unverifiedStreamInput
        .flatMap(
          (event) => Stream.fromFuture(_verifyEventDeduped(event)),
          maxConcurrent: maxConcurrent,
        )
        .where((event) => event?.validSig == true)
        .whereType<Nip01Event>() // filter nulls
        .shareReplay(maxSize: 1);
  }

  Future<Nip01Event?> _verifyEventDeduped(Nip01Event data) {
    // signature already checked, either on this object or a previous delivery
    if (data.validSig == true) {
      return Future.value(data);
    }
    if (_cache.contains(data.id)) {
      return Future.value(data.copyWith(validSig: true));
    }

    // mark eagerly (before awaiting) so duplicates delivered concurrently
    // with this one also skip the verifier instead of racing it (the actual event is not!! marked verified == true)
    _cache.markVerified(data.id);

    return _verifyEvent(data);
  }

  Future<Nip01Event?> _verifyEvent(Nip01Event data) async {
    final valid = await eventVerifier.verify(data);

    if (!valid) {
      _cache.unmark(data.id);
      Logger.log.w(
        () => 'WARNING: Event with id ${data.id} has invalid signature',
      );
      return null;
    }

    return data.copyWith(validSig: valid);
  }
}
