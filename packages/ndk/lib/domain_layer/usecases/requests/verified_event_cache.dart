import 'dart:async';
import 'dart:collection';

import '../../entities/nip_01_event.dart';
import '../../repositories/event_verifier.dart';

typedef _VerificationKey = ({String id, String? signature});

/// Bounded, in-memory LRU record of verified event id/signature pairs.
///
/// A matching id alone is not sufficient for reuse because an event id does
/// not commit to its signature. Callers must validate the incoming event id
/// from its payload before consulting [hasVerifiedSignature].
class VerifiedEventMemCache {
  final int maxSize;
  final LinkedHashSet<_VerificationKey> _verified =
      LinkedHashSet<_VerificationKey>();
  final Map<_VerificationKey, Future<bool>> _verificationInFlight =
      HashMap<_VerificationKey, Future<bool>>();
  int _generation = 0;

  VerifiedEventMemCache({this.maxSize = 5000});

  bool hasVerifiedSignature(String id, String? signature) {
    final key = (id: id, signature: signature);
    final found = _verified.remove(key);
    if (found) {
      _verified.add(key);
    }
    return found;
  }

  void markVerified(String id, String? signature) {
    final key = (id: id, signature: signature);
    _verified.remove(key);
    _verified.add(key);
    _evictOverflow();
  }

  /// Runs at most one verification for the same validated id and signature.
  Future<bool> verifyOnce(
    Nip01Event event,
    EventVerifier verifier,
  ) {
    final key = (id: event.id, signature: event.sig);
    final existing = _verificationInFlight[key];
    if (existing != null) {
      return existing;
    }

    final generation = _generation;
    late final Future<bool> future;
    future = Future<bool>.sync(() => verifier.verify(event)).then((valid) {
      if (valid && generation == _generation) {
        markVerified(event.id, event.sig);
      }
      return valid;
    }).whenComplete(() {
      if (identical(_verificationInFlight[key], future)) {
        _verificationInFlight.remove(key);
      }
    });
    _verificationInFlight[key] = future;
    return future;
  }

  /// Removes all verification state.
  ///
  /// Verifications started before this call may still complete for their
  /// existing listeners, but cannot repopulate this cache.
  void clear() {
    _generation++;
    _verified.clear();
    _verificationInFlight.clear();
  }

  void _evictOverflow() {
    while (_verified.length > maxSize) {
      _verified.remove(_verified.first);
    }
  }
}
