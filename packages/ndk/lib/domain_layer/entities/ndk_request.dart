import 'filter.dart';
import 'relay_set.dart';

// coverage:ignore-start
class NdkRequest {
  /// nostr id
  String id;
  String? name;
  bool closeOnEOSE;

  /// timeout duration, closes all streams
  Duration? timeoutDuration;

  /// define a callback that gets called when the timeout is triggered \
  /// mostly used for internal err handling (e.g. other usecases)
  Function()? timeoutCallback;

  /// user facing timeout callback \
  /// do not touch only pass it through
  Function()? timeoutCallbackUserFacing;

  final int desiredCoverage;
  List<Filter> filters;
  RelaySet? relaySet;

  /// when specified only these relays are used and inbox/outbox get ignored
  Iterable<String>? explicitRelays;
  bool cacheRead;
  bool cacheWrite;

  NdkRequest.query(
    this.id, {
    this.name,
    required this.timeoutDuration,
    this.timeoutCallback,
    this.timeoutCallbackUserFacing,
    required this.filters,
    this.desiredCoverage = 2,
    this.closeOnEOSE = true,
    this.relaySet,
    this.explicitRelays,
    this.cacheRead = true,
    this.cacheWrite = true,
  });

  NdkRequest.subscription(
    this.id, {
    this.name,
    required this.filters,
    this.desiredCoverage = 2,
    this.closeOnEOSE = false,
    this.relaySet,
    this.explicitRelays,
    this.cacheRead = true,
    this.cacheWrite = true,
  });
}
// coverage:ignore-end
