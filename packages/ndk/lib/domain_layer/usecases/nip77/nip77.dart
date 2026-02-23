import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';

import '../../../shared/helpers/relay_helper.dart';
import '../../../shared/nips/nip77/negentropy.dart' as neg;
import '../../entities/connection_source.dart';
import '../../entities/global_state.dart';
import '../../entities/nip77_state.dart';
import '../relay_manager.dart';

/// Exception thrown when a relay doesn't support NIP-77
class Nip77NotSupportedException implements Exception {
  final String relayUrl;
  final String? message;

  Nip77NotSupportedException(this.relayUrl, [this.message]);

  @override
  String toString() =>
      'Nip77NotSupportedException: Relay $relayUrl does not support NIP-77${message != null ? ': $message' : ''}';
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
  final Nip77Internal _internal;

  Nip77._({required Nip77Internal internal}) : _internal = internal;

  /// Default timeout for reconciliation
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Start a negentropy reconciliation with a relay
  ///
  /// [relayUrl] - The relay to reconcile with
  /// [filter] - Filter to determine which events to sync
  /// [timeout] - How long to wait before timing out (default: 30s)
  /// [localIds] - Optional pre-computed list of local event IDs to use.
  ///              If not provided, will query the cache using the filter.
  ///
  /// Returns a [Nip77Response] with streams for real-time updates and
  /// a future that completes with the final result.
  ///
  /// Throws [Nip77NotSupportedException] if the relay doesn't support NIP-77.
  /// Throws [Nip77TimeoutException] if reconciliation times out.
  Nip77Response reconcile({
    required String relayUrl,
    required Filter filter,
    Duration timeout = defaultTimeout,
    List<String>? localIds,
  }) {
    return _internal.reconcile(
      relayUrl: relayUrl,
      filter: filter,
      timeout: timeout,
      localIds: localIds,
    );
  }
}

/// Internal implementation of NIP-77 Negentropy sync
/// This class is not part of the public API
class Nip77Internal {
  final GlobalState _globalState;
  final RelayManager _relayManager;
  final CacheManager _cacheManager;

  Nip77Internal({
    required GlobalState globalState,
    required RelayManager relayManager,
    required CacheManager cacheManager,
  })  : _globalState = globalState,
        _relayManager = relayManager,
        _cacheManager = cacheManager;

  /// Creates the public API wrapper
  Nip77 get publicApi => Nip77._(internal: this);

  Nip77Response reconcile({
    required String relayUrl,
    required Filter filter,
    Duration timeout = Nip77.defaultTimeout,
    List<String>? localIds,
  }) {
    final cleanUrl = cleanRelayUrl(relayUrl);
    if (cleanUrl == null) {
      throw ArgumentError('Invalid relay URL: $relayUrl');
    }

    // Generate subscription ID
    final subscriptionId = 'neg-${DateTime.now().microsecondsSinceEpoch}';

    // Create session state (starts with empty items, will be populated async)
    final state = Nip77State(
      subscriptionId: subscriptionId,
      relayUrl: cleanUrl,
      localItems: [],
    );

    // Register in global state
    _globalState.inFlightNegotiations[subscriptionId] = state;

    // Set up timeout
    Timer(timeout, () {
      if (!state.isCompleted) {
        _sendNegClose(cleanUrl, subscriptionId);
        state.completeWithError(Nip77TimeoutException(cleanUrl, timeout));
        _globalState.inFlightNegotiations.remove(subscriptionId);
      }
    });

    // Start async initialization
    _startReconciliation(
      cleanUrl: cleanUrl,
      filter: filter,
      localIds: localIds,
      subscriptionId: subscriptionId,
      state: state,
    );

    return Nip77Response(state);
  }

  Future<void> _startReconciliation({
    required String cleanUrl,
    required Filter filter,
    required String subscriptionId,
    required Nip77State state,
    List<String>? localIds,
  }) async {
    try {
      // Connect to relay if needed
      final connected = await _relayManager.reconnectRelay(
        cleanUrl,
        connectionSource: ConnectionSource.explicit,
      );
      if (!connected) {
        state.completeWithError(Exception('Failed to connect to relay: $cleanUrl'));
        _globalState.inFlightNegotiations.remove(subscriptionId);
        return;
      }

      // Check if relay supports NIP-77
      final relayConnectivity = _relayManager.getRelayConnectivity(cleanUrl);
      if (relayConnectivity?.relayInfo != null &&
          !relayConnectivity!.relayInfo!.supportsNip(77)) {
        state.completeWithError(Nip77NotSupportedException(cleanUrl));
        _globalState.inFlightNegotiations.remove(subscriptionId);
        return;
      }

      // Build local items from cache or provided IDs
      List<neg.NegentropyItem> localItems;
      if (localIds != null) {
        localItems = await _buildItemsFromIds(localIds);
      } else {
        localItems = await _buildItemsFromFilter(filter);
      }

      // Update state with local items
      state.localItems.addAll(localItems);

      // Create initial message (hex encoded per NIP-77)
      final initialMessage =
          neg.Negentropy.createInitialMessage(localItems, neg.Negentropy.idSize);
      final initialPayload = neg.Negentropy.bytesToHex(initialMessage);

      // Send NEG-OPEN
      final negOpen = ['NEG-OPEN', subscriptionId, filter.toMap(), initialPayload];
      _relayManager.getRelayConnectivity(cleanUrl)?.relayTransport?.send(
            jsonEncode(negOpen),
          );

      Logger.log.d(() => 'NEG-OPEN sent to $cleanUrl: $subscriptionId');
    } catch (e) {
      state.completeWithError(e);
      _globalState.inFlightNegotiations.remove(subscriptionId);
    }
  }

  Future<List<neg.NegentropyItem>> _buildItemsFromIds(List<String> ids) async {
    final items = <neg.NegentropyItem>[];

    for (final id in ids) {
      final event = await _cacheManager.loadEvent(id);
      if (event != null) {
        items.add(neg.NegentropyItem.fromHex(
          timestamp: event.createdAt,
          idHex: id,
        ));
      } else {
        items.add(neg.NegentropyItem.fromHex(
          timestamp: 0,
          idHex: id,
        ));
      }
    }

    return items;
  }

  Future<List<neg.NegentropyItem>> _buildItemsFromFilter(Filter filter) async {
    final events = await _cacheManager.loadEvents(
      pubKeys: filter.authors,
      kinds: filter.kinds,
      since: filter.since,
      until: filter.until,
    );

    return events
        .map((e) => neg.NegentropyItem.fromHex(
              timestamp: e.createdAt,
              idHex: e.id,
            ))
        .toList();
  }

  /// Process incoming NEG-MSG from a relay
  void processNegMsg(String subscriptionId, String relayUrl, String payload) {
    final state = _globalState.inFlightNegotiations[subscriptionId];
    if (state == null) {
      Logger.log.w(() => 'Received NEG-MSG for unknown session: $subscriptionId');
      return;
    }

    try {
      final messageBytes = neg.Negentropy.hexToBytes(payload);
      final response = state.processMessage(messageBytes);

      if (response == null) {
        // Reconciliation complete
        _sendNegClose(relayUrl, subscriptionId);
        state.complete();
        _globalState.inFlightNegotiations.remove(subscriptionId);
        Logger.log.d(() =>
            'NEG reconciliation complete: need=${state.needIds.length}, have=${state.haveIds.length}');
      } else {
        // Send response (hex encoded)
        final responsePayload = neg.Negentropy.bytesToHex(response);
        final negMsg = ['NEG-MSG', subscriptionId, responsePayload];
        _relayManager
            .getRelayConnectivity(relayUrl)
            ?.relayTransport
            ?.send(jsonEncode(negMsg));
        Logger.log.d(() => 'NEG-MSG sent to $relayUrl');
      }
    } catch (e) {
      Logger.log.e(() => 'Error processing NEG-MSG: $e');
      state.completeWithError(e);
      _globalState.inFlightNegotiations.remove(subscriptionId);
    }
  }

  /// Process incoming NEG-ERR from a relay
  void processNegErr(String subscriptionId, String relayUrl, String errorMsg) {
    final state = _globalState.inFlightNegotiations[subscriptionId];
    if (state == null) {
      Logger.log.w(() => 'Received NEG-ERR for unknown session: $subscriptionId');
      return;
    }

    Logger.log.e(() => 'NEG-ERR from $relayUrl: $errorMsg');

    if (errorMsg.contains('CLOSED') || errorMsg.contains('auth-required')) {
      state.completeWithError(Nip77NotSupportedException(relayUrl, errorMsg));
    } else {
      state.completeWithError(Exception(errorMsg));
    }

    _globalState.inFlightNegotiations.remove(subscriptionId);
  }

  void _sendNegClose(String relayUrl, String subscriptionId) {
    final negClose = ['NEG-CLOSE', subscriptionId];
    _relayManager
        .getRelayConnectivity(relayUrl)
        ?.relayTransport
        ?.send(jsonEncode(negClose));
    Logger.log.d(() => 'NEG-CLOSE sent to $relayUrl: $subscriptionId');
  }

  void close(String subscriptionId) {
    final state = _globalState.inFlightNegotiations[subscriptionId];
    if (state != null) {
      _sendNegClose(state.relayUrl, subscriptionId);
      state.close();
      _globalState.inFlightNegotiations.remove(subscriptionId);
    }
  }

  void closeAll() {
    for (final entry in _globalState.inFlightNegotiations.entries.toList()) {
      _sendNegClose(entry.value.relayUrl, entry.key);
      entry.value.close();
    }
    _globalState.inFlightNegotiations.clear();
  }
}
