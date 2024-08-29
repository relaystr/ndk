import 'package:ndk/config/request_defaults.dart';

import 'filter.dart';
import 'relay_set.dart';
import 'request_state.dart';

class NdkRequest {
  /// nostr id
  String id;
  bool closeOnEOSE;
  int? timeout;
  Function(RequestState)? onTimeout;
  final int desiredCoverage;
  List<Filter> filters;
  RelaySet? relaySet;
  List<String>? relays;
  bool cacheRead;
  bool cacheWrite;

  NdkRequest.query(
    this.id, {
    required this.filters,
    this.desiredCoverage = 2,
    this.closeOnEOSE = true,
    this.relaySet,
    this.relays,
    this.cacheRead = true,
    this.cacheWrite = true,
    this.timeout = RequestDefaults.DEFAULT_STREAM_IDLE_TIMEOUT + 1,
    this.onTimeout,
  });

  NdkRequest.subscription(
    this.id, {
    required this.filters,
    this.desiredCoverage = 2,
    this.closeOnEOSE = false,
    this.relaySet,
    this.relays,
    this.cacheRead = true,
    this.cacheWrite = true,
  });
}
