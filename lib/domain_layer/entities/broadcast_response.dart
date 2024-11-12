import 'dart:async';

import 'nip_01_event.dart';

/// the response to a low level broadcast request
class NdkBroadcastResponse {
  final Nip01Event publishedEvent;

  final Completer<bool> _publishCompleter = Completer();

  /// completes when all relays have responded
  /// TODO
  // Future<bool> get publishDone => _publishCompleter.future;

  /// a map of relays publishing to
  /// [String] is the relayUrl/identifier
  /// [Future<String>] is the relay response e.g. OK, err reason
  // Map<String, Completer<String>> _publishingRelays = {};

  NdkBroadcastResponse({
    required this.publishedEvent,
  });

  addPublishingRelay({required String url}) {}
}
