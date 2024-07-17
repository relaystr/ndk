import 'request_state.dart';

class GlobalState {
  final Map<String, RequestState> inFlightRequests = {};
}
