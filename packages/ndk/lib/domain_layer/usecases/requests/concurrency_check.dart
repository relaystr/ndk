import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../entities/filter.dart';
import '../../entities/global_state.dart';
import '../../entities/ndk_request.dart';
import '../../entities/request_state.dart';

class ConcurrencyCheck {
  final GlobalState _globalState;

  ConcurrencyCheck(this._globalState);

  /// checks if the request is already served (based on filters) and if so adds the stream.
  /// returns true if the response stream got replaced
  bool check(RequestState requestState) {
    final hash = _hashRequest(requestState.request);

    // check if its not already served
    if (!_globalState.inFlightRequests.containsKey(hash)) {
      // add to running requests
      _globalState.inFlightRequests[hash] = requestState;

      // register listener so inFlight entry gets removed
      requestState.controller.done.then(
        (value) => _globalState.inFlightRequests.remove(hash),
      );

      return false;
    }

    // add already running stream to duplicate request
    // When original stream ends, close the duplicate's controller
    requestState.controller
        .addStream(_globalState.inFlightRequests[hash]!.stream)
        .then((_) => requestState.controller.close());

    return true;
  }

  /// Two requests are only interchangeable when they also target the same
  /// relays, share the same lifetime and may be attributed to the same
  /// identity. Merging a subscription with a query kills one of them: the
  /// subscription would close on EOSE, or the query would await a stream that
  /// never ends. Merging across identities answers a request that asked to stay
  /// unattributable with what an authenticated one obtained.
  String _hashRequest(NdkRequest request) {
    final jsonString = json.encode({
      'filters': _canonicalFilters(request.filters),
      'closeOnEOSE': request.closeOnEOSE,
      'explicitRelays': _sorted(request.explicitRelays),
      'auth': request.auth?.canonical,
      'relaySet': request.relaySet == null
          ? null
          : {
              'id': request.relaySet!.id,
              'urls': _sorted(request.relaySet!.urls),
            },
    });
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  List<String>? _sorted(Iterable<String>? values) {
    if (values == null) return null;
    return values.toList()..sort();
  }

  /// Filters and their values are sets: `authors: [a, b]` and `authors: [b, a]`
  /// ask the same question, so they have to hash the same.
  List<String> _canonicalFilters(List<Filter> filters) {
    return filters
        .map((filter) => json.encode(_canonical(filter.toMap())))
        .toList()
      ..sort();
  }

  Map<String, dynamic> _canonical(Map<String, dynamic> map) {
    final keys = map.keys.toList()..sort();
    return {
      for (final key in keys)
        key: map[key] is List
            ? (List<dynamic>.from(map[key] as List)
              ..sort((a, b) => (a as Comparable).compareTo(b)))
            : map[key],
    };
  }
}
