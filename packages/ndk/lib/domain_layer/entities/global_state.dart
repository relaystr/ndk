import 'broadcast_state.dart';
import 'nip77_state.dart';
import 'relay_connectivity.dart';
import 'request_state.dart';

/// Global state of the NDK
/// as a user you should not need to interact with this class \
/// you should use the NDK API and keep the global state in memory
class GlobalState {
  /// holds the state of all in flight requests
  /// key: request Id
  /// used by concurrency check, and relay manager
  final Map<String, RequestState> inFlightRequests = {};

  /// hold state information for a broadcast
  /// key: event Id
  final Map<String, BroadcastState> inFlightBroadcasts = {};

  /// touched relays by ndk - connected, connecting, disconnected
  /// key: relay url/identifier
  /// value: relay connectivity
  Map<String, RelayConnectivity> relays = {};

  /// clean urls of relays that are blocked
  Set<String> blockedRelays = {};

  /// holds the state of all in-flight NIP-77 negentropy reconciliations
  /// key: subscription Id
  final Map<String, Nip77State> inFlightNegotiations = {};
}
