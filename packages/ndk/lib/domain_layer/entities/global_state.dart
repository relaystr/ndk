import 'broadcast_state.dart';
import 'relay_connectivity.dart';
import 'request_state.dart';

class GlobalState {
  /// used by concurrency check
  final Map<String, RequestState> inFlightRequests = {};

  ///todo: WIP

  /// todo: discuss what active means or if the same as inFlight (requestState.controller.done => request is done?)
  /// key: request Id
  final Map<String, RequestState> activeRequests = {};

  /// hold state information for a broadcast
  /// key: event Id
  final Map<String, BroadcastState> activeBroadcasts = {};

  /// touched relays by ndk - connected, connecting, disconnected
  /// key: relay url/identifier
  /// value: relay connectivity
  Map<String, RelayConnectivity> relays = {};

  /// urls of relays that are blocked
  Set<String> blockedRelays = {};
}
