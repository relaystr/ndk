import 'package:dart_ndk/config/request_defaults.dart';

import '../domain_layer/entities/filter.dart';
import '../domain_layer/repositories/event_verifier_repository.dart';

/// proposal for a request_config used by the user
///

class RequestConfig {
  /// nostr id
  String id;
  bool closeOnEOSE;
  int? timeout;
  Function()? onTimeout;
  final int desiredCoverage;

  EventVerifierRepository eventVerifier;
  List<Filter> filters;

  RequestConfig.query(
    this.id, {
    required this.filters,
    required this.eventVerifier,
    this.desiredCoverage = 2,
    this.closeOnEOSE = true,
    this.timeout = RequestDefaults.DEFAULT_STREAM_IDLE_TIMEOUT + 1,
    this.onTimeout,
  });

  RequestConfig.subscription(
    this.id, {
    required this.filters,
    required this.eventVerifier,
    this.desiredCoverage = 2,
    this.closeOnEOSE = false,
  });
}
