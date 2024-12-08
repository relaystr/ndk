import 'dart:async';

import 'nip_01_event.dart';

/// the response to a low level broadcast request
class NdkBroadcastResponse {
  /// the event that is being published
  final Nip01Event publishEvent;

  final Future<List<RelayBroadcastResponse>> _publishDoneFuture;

  /// completes when all relays have responded or timed out \
  /// key is the relay url, value is the response [] on success
  Future<List<RelayBroadcastResponse>> get publishDone => _publishDoneFuture;

  /// creates a new [NdkBroadcastResponse] instance
  NdkBroadcastResponse({
    required this.publishEvent,
    required Future<List<RelayBroadcastResponse>> publishDoneFuture,
  }) : _publishDoneFuture = publishDoneFuture;
}

/// individual response from a relay
class RelayBroadcastResponse {
  /// the relay url
  final String relayUrl;

  /// true if publishing was successful
  final bool success;

  /// the response message usually an error message
  final String msg;

  /// creates a new [RelayBroadcastResponse] instance
  RelayBroadcastResponse({
    required this.relayUrl,
    required this.success,
    required this.msg,
  });
}
