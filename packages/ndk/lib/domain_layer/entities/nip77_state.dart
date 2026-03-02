import 'dart:async';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';

import '../../shared/nips/nip77/negentropy.dart';

/// State of a NIP-77 negentropy reconciliation session
class Nip77State {
  /// Unique subscription ID for this session
  final String subscriptionId;

  /// Relay URL this session is connected to
  final String relayUrl;

  /// Local items for reconciliation
  final List<NegentropyItem> localItems;

  /// Stream controller for IDs we need from the relay
  final _needController = BehaviorSubject<String>();

  /// Stream controller for IDs we have that the relay doesn't
  final _haveController = BehaviorSubject<String>();

  /// All need IDs accumulated
  final List<String> needIds = [];

  /// All have IDs accumulated
  final List<String> haveIds = [];

  /// Completer for session completion
  final Completer<Nip77Result> _completer = Completer<Nip77Result>();

  /// Whether the session has completed
  bool _isCompleted = false;

  /// Error if any
  String? error;

  Nip77State({
    required this.subscriptionId,
    required this.relayUrl,
    required this.localItems,
  });

  /// Stream of IDs we need from the relay
  Stream<String> get needStream => _needController.stream;

  /// Stream of IDs we have that relay doesn't
  Stream<String> get haveStream => _haveController.stream;

  /// Future that completes when reconciliation is done
  Future<Nip77Result> get future => _completer.future;

  /// Whether the session is completed
  bool get isCompleted => _isCompleted;

  /// Process an incoming NEG-MSG from relay
  /// Returns the response message bytes to send back, or null if done
  Uint8List? processMessage(Uint8List messageBytes) {
    try {
      final (response, newNeedIds, newHaveIds) =
          Negentropy.reconcile(messageBytes, localItems);

      // Add newly discovered IDs
      for (final id in newNeedIds) {
        needIds.add(id);
        _needController.add(id);
      }
      for (final id in newHaveIds) {
        haveIds.add(id);
        _haveController.add(id);
      }

      // Check if we're done (response only has version byte)
      if (response.length <= 1) {
        return null;
      }

      return response;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  /// Complete the session successfully
  void complete() {
    if (_isCompleted) return;
    _isCompleted = true;
    _needController.close();
    _haveController.close();
    _completer.complete(Nip77Result(
      needIds: List.unmodifiable(needIds),
      haveIds: List.unmodifiable(haveIds),
    ));
  }

  /// Complete the session with an error
  void completeWithError(Object error) {
    if (_isCompleted) return;
    _isCompleted = true;
    this.error = error.toString();
    _needController.close();
    _haveController.close();
    _completer.completeError(error);
  }

  /// Close the session without completing
  void close() {
    if (_isCompleted) return;
    _isCompleted = true;
    _needController.close();
    _haveController.close();
    if (!_completer.isCompleted) {
      _completer.complete(Nip77Result(
        needIds: List.unmodifiable(needIds),
        haveIds: List.unmodifiable(haveIds),
      ));
    }
  }
}

/// Result of a NIP-77 negentropy reconciliation
class Nip77Result {
  /// IDs that we need to fetch from the relay
  final List<String> needIds;

  /// IDs that we have that the relay doesn't
  final List<String> haveIds;

  Nip77Result({
    required this.needIds,
    required this.haveIds,
  });

  @override
  String toString() =>
      'Nip77Result(need: ${needIds.length}, have: ${haveIds.length})';
}
