import 'dart:async';
import 'dart:collection';

class MutexSimple {
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();
  bool _isLocked = false;

  Future<T> synchronized<T>(Future<T> Function() operation) async {
    await _acquireLock();

    try {
      return await operation();
    } finally {
      _releaseLock();
    }
  }

  Future<void> _acquireLock() async {
    if (!_isLocked) {
      _isLocked = true;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
  }

  void _releaseLock() {
    if (_waitQueue.isNotEmpty) {
      final nextCompleter = _waitQueue.removeFirst();
      nextCompleter.complete();
    } else {
      _isLocked = false;
    }
  }
}
