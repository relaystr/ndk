import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';

import '../../../shared/helpers/relay_helper.dart';
import '../../../shared/nips/nip77/negentropy.dart' as neg;
import '../../entities/connection_source.dart';
import '../../entities/global_state.dart';
import '../../entities/nip77_state.dart';
import '../../entities/relay_connectivity.dart';
import '../relay_manager.dart';

part 'nip77_internal.dart';

/// Exception thrown when a relay doesn't support NIP-77
class Nip77NotSupportedException implements Exception {
  final String relayUrl;
  final String? message;

  Nip77NotSupportedException(this.relayUrl, [this.message]);

  @override
  String toString() =>
      'Nip77NotSupportedException: Relay $relayUrl does not support NIP-77${message != null ? ': $message' : ''}';
}

/// Exception thrown when no connection can carry the reconciliation, because
/// the identity it requires cannot sign. Falling back to the anonymous
/// connection is exactly what [RelayAuth.require] ruled out.
class Nip77AuthUnavailableException implements Exception {
  /// relay the reconciliation was meant for
  final String relayUrl;

  /// identity that was required
  final String pubkey;

  /// no connection can carry the reconciliation
  Nip77AuthUnavailableException(this.relayUrl, this.pubkey);

  @override
  String toString() =>
      'Nip77AuthUnavailableException: $pubkey cannot sign, so no connection to '
      '$relayUrl can carry this reconciliation';
}

/// Exception thrown when a relay refuses the negotiation without an identity
/// and the auth policy leaves nobody to authenticate as.
class Nip77AuthRequiredException implements Exception {
  /// relay that refused
  final String relayUrl;

  /// raw refusal from the relay
  final String message;

  /// the relay asked for an identity this reconciliation may not reveal
  Nip77AuthRequiredException(this.relayUrl, this.message);

  @override
  String toString() =>
      'Nip77AuthRequiredException: $relayUrl requires an identity this '
      'reconciliation may not authenticate as: $message';
}

/// Exception thrown when NIP-77 reconciliation times out
class Nip77TimeoutException implements Exception {
  final String relayUrl;
  final Duration timeout;

  Nip77TimeoutException(this.relayUrl, this.timeout);

  @override
  String toString() =>
      'Nip77TimeoutException: Reconciliation with $relayUrl timed out after ${timeout.inSeconds}s';
}

/// Response from a NIP-77 reconciliation request
class Nip77Response {
  final Nip77State _state;

  Nip77Response(this._state);

  /// Stream of event IDs we need to fetch from the relay
  Stream<String> get needStream => _state.needStream;

  /// Stream of event IDs we have that the relay doesn't
  Stream<String> get haveStream => _state.haveStream;

  /// Future that completes with the final result
  Future<Nip77Result> get future => _state.future;

  /// The subscription ID for this session
  String get subscriptionId => _state.subscriptionId;

  /// The relay URL for this session
  String get relayUrl => _state.relayUrl;
}

/// Public API for NIP-77 Negentropy sync
class Nip77 {
  final _Nip77Internal _internal;

  Nip77({
    required GlobalState globalState,
    required RelayManager relayManager,
    required CacheManager cacheManager,
  }) : _internal = _Nip77Internal(
          globalState: globalState,
          relayManager: relayManager,
          cacheManager: cacheManager,
        );

  /// Default timeout for reconciliation
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Process incoming NEG-MSG from a relay
  void processNegMsg(
    String subscriptionId,
    RelayConnectionKey key,
    String payload,
  ) {
    _internal.processNegMsg(subscriptionId, key, payload);
  }

  /// Process incoming NEG-ERR from a relay
  void processNegErr(
    String subscriptionId,
    RelayConnectionKey key,
    String errorMsg,
  ) {
    _internal.processNegErr(subscriptionId, key, errorMsg);
  }

  /// Process a CLOSED that ends a negotiation, which is how some relays refuse
  /// a NEG-OPEN instead of answering NEG-ERR
  void processNegClosed(
    String subscriptionId,
    RelayConnectionKey key,
    String? message,
  ) {
    _internal.processNegClosed(subscriptionId, key, message);
  }

  /// Close a specific NIP-77 negotiation
  void close(String subscriptionId) {
    _internal.close(subscriptionId);
  }

  /// Close all active NIP-77 negotiations
  void closeAll() {
    _internal.closeAll();
  }

  /// Start a negentropy reconciliation with a relay
  ///
  /// [relayUrl] - The relay to reconcile with
  /// [filter] - Filter to determine which events to sync
  /// [timeout] - How long to wait before timing out (default: 30s)
  /// [localIds] - Optional pre-computed list of local event IDs to use.
  ///              If not provided, will query the cache using the filter.
  /// [auth] - which identity this reconciliation may be attributed to, see
  ///          [RelayAuth]. Without it, a relay that refuses the negotiation
  ///          without an identity is answered as the logged-in account.
  ///
  /// Returns a [Nip77Response] with streams for real-time updates and
  /// a future that completes with the final result.
  ///
  /// Throws [Nip77NotSupportedException] if the relay doesn't support NIP-77.
  /// Throws [Nip77TimeoutException] if reconciliation times out.
  /// Throws [Nip77AuthUnavailableException] if [auth] requires an identity that
  /// cannot sign, and [Nip77AuthRequiredException] if the relay asks for an
  /// identity [auth] rules out.
  Nip77Response reconcile({
    required String relayUrl,
    required Filter filter,
    Duration timeout = defaultTimeout,
    List<String>? localIds,
    RelayAuth? auth,
  }) {
    return _internal.reconcile(
      relayUrl: relayUrl,
      filter: filter,
      timeout: timeout,
      localIds: localIds,
      auth: auth,
    );
  }
}
