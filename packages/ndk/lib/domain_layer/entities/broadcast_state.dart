import 'dart:async';

import 'package:ndk/domain_layer/entities/tuple.dart';

import 'broadcast_response.dart';

// todo: turn into streams

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
  Future<List<RelayBroadcastResponse>> get publishDone =>
      _publishCompleter.future;

  final Completer<List<RelayBroadcastResponse>> _publishCompleter = Completer();

  /// tuple marks success, and string is the msg (usually an error message)\
  /// ["OK", "b1a649ebe8...", true, "duplicate: already have this event"]
  /// ["OK", "b1a649ebe8...", false, "pow: difficulty 26 is less than 30"]
  Map<String, Completer<Tuple<bool, String>>> _publishingRelays = {};

  /// add a relay to the publishing list
  addPublishingRelay({required String url}) {
    _publishingRelays[url] = Completer<Tuple<bool, String>>();
  }

  /// complete the relay
  completePublishingRelay(
      {required String url, required bool success, required String response}) {
    if (_publishingRelays.containsKey(url)) {
      _publishingRelays[url]!.complete(Tuple(success, response));
    }
    _completeBroadcast();
  }

  /// check if all relays have responded
  _completeBroadcast() {
    if (_publishingRelays.values.every((element) => element.isCompleted)) {
      List<RelayBroadcastResponse> responses = [];
      _publishingRelays.forEach((key, value) {
        responses.add(RelayBroadcastResponse(
          relayUrl: key,
          success: value.isCompleted,
          msg: value.future.toString(),
        ));
      });

      _publishCompleter.complete(responses);
    }
  }
}
