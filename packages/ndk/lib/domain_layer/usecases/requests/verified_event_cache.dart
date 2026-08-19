import 'dart:collection';

/// Bounded, in-memory record of event ids whose signature was already
/// checked, so relay re-deliveries and repeat requests skip the verifier.
class VerifiedEventMemCache {
  final int maxSize;
  final LinkedHashSet<String> _ids = LinkedHashSet<String>();

  VerifiedEventMemCache({this.maxSize = 20000});

  /// touches [id] to the front, marking it recently used
  bool contains(String id) {
    final found = _ids.remove(id);
    if (found) {
      _ids.add(id);
    }
    return found;
  }

  void markVerified(String id) {
    _ids.remove(id);
    _ids.add(id);
    while (_ids.length > maxSize) {
      _ids.remove(_ids.first);
    }
  }

  /// reverts an optimistic [markVerified] once verification actually fails
  void unmark(String id) => _ids.remove(id);
}
