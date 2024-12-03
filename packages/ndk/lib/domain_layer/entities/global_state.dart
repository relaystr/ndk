import 'relay_connectivity.dart';
import 'request_state.dart';

class GlobalState {
  /// used by concurrency check
  final Map<String, RequestState> inFlightRequests = {};

  ///todo: WIP

  /// touched relays by ndk - connected, connecting, disconnected
  /// key: relay url/identifier
  /// value: relay connectivity
  Map<String, RelayConnectivity> relays = {};

  /// urls of relays that are blocked
  Set<String> blockedRelays = {};
}
