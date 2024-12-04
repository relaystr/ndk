import 'dart:async';

/// hold state information for a broadcast
class BroadcastState {
  /// creates a new [BroadcastState] instance
  BroadcastState() {
    Future.delayed(Duration(seconds: 10), () {
      _publishCompleter.completeError("timeout");
    });
  }

  /// completes when all relays have responded or timed out
  /// first string is the relay url, second is the response
  Future<Map<String, String>> get publishDone => _publishCompleter.future;

  final Completer<Map<String, String>> _publishCompleter = Completer();

  Map<String, Completer<String>> _publishingRelays = {};

  /// add a relay to the publishing list
  addPublishingRelay({required String url}) {
    _publishingRelays[url] = Completer<String>();
  }

  /// complete the relay
  completePublishingRelay({required String url, required String response}) {
    if (_publishingRelays.containsKey(url)) {
      _publishingRelays[url]!.complete(response);
    }
    _completeBroadcast();
  }

  /// check if all relays have responded
  _completeBroadcast() {
    if (_publishingRelays.values.every((element) => element.isCompleted)) {
      Map<String, String> responses = {};
      _publishingRelays.forEach((key, value) {
        responses[key] = value.future.toString();
      });
      _publishCompleter.complete(responses);
    }
  }
}
