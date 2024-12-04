import 'dart:async';

import 'nip_01_event.dart';

/// the response to a low level broadcast request
class NdkBroadcastResponse {
  final Nip01Event publishedEvent;
  final Future<Map<String, String>> _publishDoneFuture;

  /// completes when all relays have responded or timed out \
  /// key is the relay url, value is the response [] on success
  Future<Map<String, String>> get publishDone => _publishDoneFuture;

  /// creates a new [NdkBroadcastResponse] instance
  NdkBroadcastResponse({
    required this.publishedEvent,
    required Future<Map<String, String>> publishDoneFuture,
  }) : _publishDoneFuture = publishDoneFuture;
}
