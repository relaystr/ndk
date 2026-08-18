import 'dart:async';

import 'nip_01_event.dart';
import 'relay_request_outcome.dart';

// coverage:ignore-start

/// Represents a response from a Nostr Development Kit (NDK) request.
class NdkResponse {
  /// The unique identifier for the request that generated this response.
  String requestId;

  /// A stream of [Nip01Event] objects returned by the request.
  ///
  /// This stream can be listened to for real-time processing of events
  /// as they arrive from the nostr request.
  final Stream<Nip01Event> stream;

  final Map<String, RelayRequestOutcome> Function() _relayOutcomes;

  final Future<Map<String, RelayRequestOutcome>> _relayOutcomesDone;

  /// A future that resolves to a list of all [Nip01Event] objects
  /// once the request is complete (EOSE rcv).
  Future<List<Nip01Event>> get future => stream.toList();

  /// What the request ended with on each relay it was sent to, as it stands
  /// now, keyed by relay url.
  ///
  /// Reading it tells an exhausted relay from a silent one: a relay that has
  /// not answered yet is [RelayRequestOutcomeType.pending], which is what a
  /// live subscription shows for as long as it runs.
  Map<String, RelayRequestOutcome> get relayOutcomes => _relayOutcomes();

  /// [relayOutcomes] once the request is over, either because every relay
  /// ended it or because it ran into its timeout.
  ///
  /// A subscription is only over once it is closed, so this resolves on
  /// `closeSubscription` for one.
  Future<Map<String, RelayRequestOutcome>> get relayOutcomesDone =>
      _relayOutcomesDone;

  /// Creates a new [NdkResponse] instance.
  NdkResponse(
    this.requestId,
    this.stream, {
    Map<String, RelayRequestOutcome> Function()? relayOutcomes,
    Future<Map<String, RelayRequestOutcome>>? relayOutcomesDone,
  }) : _relayOutcomes = relayOutcomes ?? _noOutcomes,
       _relayOutcomesDone =
           relayOutcomesDone ??
           Future.value(const <String, RelayRequestOutcome>{});

  static Map<String, RelayRequestOutcome> _noOutcomes() =>
      const <String, RelayRequestOutcome>{};
}

// coverage:ignore-end
