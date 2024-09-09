import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../entities/filter.dart';
import '../../entities/global_state.dart';
import '../../entities/request_state.dart';

class ConcurrencyCheck {
  GlobalState globalState;

  ConcurrencyCheck(this.globalState);

  /// checks if the request is already served (based on filters) and if so adds the stream.
  /// returns true if the response stream got replaced
  bool check(RequestState requestState) {
    final hash = _hashFilters(requestState.request.filters);

    // check if its not already served
    if (!globalState.inFlightRequests.containsKey(hash)) {
      // add to running requests
      globalState.inFlightRequests[hash] = requestState;

      // register listener so inFlight entry gets removed
      requestState.controller.done.then(
        (value) => globalState.inFlightRequests.remove(hash),
      );

      return false;
    }

    // add already running stream to duplicate request
    requestState.controller
        .addStream(globalState.inFlightRequests[hash]!.stream);

    return true;
  }

  String _hashFilters(List<Filter> filters) {
    final jsonString = json.encode(filters);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
