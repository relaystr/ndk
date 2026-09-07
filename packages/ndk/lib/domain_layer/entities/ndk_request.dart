import 'account.dart';
import 'filter.dart';
import 'relay_auth.dart';
import 'relay_set.dart';

// coverage:ignore-start
/// Ndk request
class NdkRequest {
  /// nostr id
  String id;

  /// request name (for better debugging / logging
  String? name;

  /// should it close on receiving EOSE?
  bool closeOnEOSE;

  /// timeout duration, closes all streams
  Duration? timeoutDuration;

  /// define a callback that gets called when the timeout is triggered \
  /// mostly used for internal err handling (e.g. other usecases)
  Function()? timeoutCallback;

  /// user facing timeout callback \
  /// do not touch only pass it through
  Function()? timeoutCallbackUserFacing;

  /// desired coverage
  final int desiredCoverage;

  /// filters
  List<Filter> filters;

  /// optional [RelaySet] for outbox/inbox pre-calculated
  RelaySet? relaySet;

  /// when specified only these relays are used and inbox/outbox get ignored
  Iterable<String>? explicitRelays;

  /// use cache for read?
  bool cacheRead;

  /// use cache for write
  bool cacheWrite;

  /// which identity this request may be attributed to on the relays (NIP-42)
  final RelayAuth? auth;

  /// query
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
    RelayAuth? auth,
    @Deprecated(
      'Use auth: RelayAuth.allow(account) instead. authenticateAs will be removed in a future version.',
    )
    List<Account>? authenticateAs,
  }) : auth = auth ?? RelayAuth.fromDeprecatedAccounts(authenticateAs);

  /// subscription
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
    RelayAuth? auth,
    @Deprecated(
      'Use auth: RelayAuth.allow(account) instead. authenticateAs will be removed in a future version.',
    )
    List<Account>? authenticateAs,
  }) : auth = auth ?? RelayAuth.fromDeprecatedAccounts(authenticateAs);
}

// coverage:ignore-end
