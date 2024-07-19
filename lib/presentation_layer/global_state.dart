import 'request_state.dart';

class GlobalState {
  /// used by concurrency check
  final Map<String, RequestState> inFlightRequests = {};
}
