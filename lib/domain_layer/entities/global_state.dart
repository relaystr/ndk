import '../usecases/relay_jit_manager/relay_jit.dart';
import 'request_state.dart';

class GlobalState {
  /// used by concurrency check
  final Map<String, RequestState> inFlightRequests = {};

  /// used by RelayJitManager
  // TODO this class should not hold anything JIT specific
  List<RelayJit> connectedRelays = [];
}
