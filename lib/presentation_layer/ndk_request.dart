import 'package:dart_ndk/config/request_defaults.dart';
import 'package:dart_ndk/domain_layer/entities/request_state.dart';

import '../domain_layer/entities/filter.dart';
import '../domain_layer/entities/relay_set.dart';

/// proposal for a request_config used by the user
///
///? before request_config
///

class NdkRequest {
  /// nostr id
  String id;
  bool closeOnEOSE;
  int? timeout;
  Function(RequestState)? onTimeout;
  final int desiredCoverage;
  List<Filter> filters;
  RelaySet? relaySet;

  NdkRequest.query(
    this.id, {
    required this.filters,
    this.desiredCoverage = 2,
    this.closeOnEOSE = true,
    this.timeout = RequestDefaults.DEFAULT_STREAM_IDLE_TIMEOUT + 1,
    this.onTimeout,
  });

  NdkRequest.subscription(
    this.id, {
    required this.filters,
    this.desiredCoverage = 2,
    this.closeOnEOSE = false,
  });
}
