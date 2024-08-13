import 'package:dart_ndk/config/request_defaults.dart';
import 'package:dart_ndk/presentation_layer/request_state.dart';

import '../domain_layer/entities/filter.dart';

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
