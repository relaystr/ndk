import '../usecases/relay_jit_manager/relay_jit.dart';
import 'relay_connectivity.dart';
import 'request_state.dart';

class GlobalState {
  /// used by concurrency check
  final Map<String, RequestState> inFlightRequests = {};

  /// used by RelayJitManager
  // TODO this class should not hold anything JIT specific
  List<RelayJit> connectedRelays = [];

  ///todo: WIP

  /// touched relays by ndk - connected, connecting, disconnected
  /// key: relay url/identifier
  /// value: relay connectivity
  Map<String, RelayConnectivity> relays = {};

  /// urls of relays that are blocked
  Set<String> blockedRelays = {};
}
