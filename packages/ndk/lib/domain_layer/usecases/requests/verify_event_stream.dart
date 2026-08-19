import 'package:rxdart/rxdart.dart';

import 'verified_event_cache.dart';
import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_01_utils.dart';
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

  Future<Nip01Event?> _verifyEventDeduped(Nip01Event data) async {
    // Never reuse verification state for an id that does not match the
    // incoming payload. This is intentionally done before signature lookup.
    if (!Nip01Utils.isIdValid(data)) {
      Logger.log.w(
        () => 'WARNING: Event with id ${data.id} has invalid event id',
      );
      return null;
    }

    // validSig is trusted internal provenance, but still seed the exact
    // id/signature pair so later network copies can be compared safely.
    if (data.validSig == true) {
      _cache.markVerified(data.id, data.sig);
      return data;
    }

    if (_cache.hasVerifiedSignature(data.id, data.sig)) {
      return data.copyWith(validSig: true);
    }

    final valid = await _cache.verifyOnce(data, eventVerifier);

    if (!valid) {
      Logger.log.w(
        () => 'WARNING: Event with id ${data.id} has invalid signature',
      );
      return null;
    }

    return data.copyWith(validSig: valid);
  }
}
