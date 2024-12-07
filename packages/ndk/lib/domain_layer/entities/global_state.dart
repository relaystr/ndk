import 'broadcast_state.dart';
import 'relay_connectivity.dart';
import 'request_state.dart';

class GlobalState {
  /// used by concurrency check, and relay manager
  /// key: request Id
  final Map<String, RequestState> inFlightRequests = {};

  ///todo: WIP

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
