import 'dart:async';

import 'broadcast_state.dart';
import 'nip_01_event.dart';

/// the response to a low level broadcast request
class NdkBroadcastResponse {
  /// the event that is being published
  final Nip01Event publishEvent;

  final Stream<List<RelayBroadcastResponse>> _broadcastDoneStream;
  final Future<List<RelayBroadcastResponse>> _broadcastDoneFuture;

  /// completes when all relays have responded or timed out
  Future<List<RelayBroadcastResponse>> get broadcastDoneFuture =>
      _broadcastDoneFuture;

  /// stream of state updates \
  Stream<List<RelayBroadcastResponse>> get broadcastDone =>
      _broadcastDoneStream;

  /// creates a new [NdkBroadcastResponse] instance
  NdkBroadcastResponse({
    required this.publishEvent,
    required Stream<List<RelayBroadcastResponse>> broadcastDoneStream,
    Future<List<RelayBroadcastResponse>>? broadcastDoneFuture,
  })  : _broadcastDoneStream = broadcastDoneStream,
        _broadcastDoneFuture = broadcastDoneFuture ?? broadcastDoneStream.last;
}
