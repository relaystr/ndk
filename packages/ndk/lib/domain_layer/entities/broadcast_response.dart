import 'dart:async';

import 'broadcast_state.dart';
import 'nip_01_event.dart';

/// the response to a low level broadcast request
class NdkBroadcastResponse {
  /// the event that is being published
  final Nip01Event publishEvent;

  final Stream<List<RelayBroadcastResponse>> _broadcastDoneStream;

  /// completes when all relays have responded or timed out
  Future<List<RelayBroadcastResponse>> get broadcastDoneFuture =>
      _broadcastDoneStream.last;

  /// stream of state updates \
  Stream<List<RelayBroadcastResponse>> get broadcastDone =>
      _broadcastDoneStream;

  /// creates a new [NdkBroadcastResponse] instance
  NdkBroadcastResponse({
    required this.publishEvent,
    required Stream<List<RelayBroadcastResponse>> broadcastDoneStream,
  }) : _broadcastDoneStream = broadcastDoneStream;
}
