part of 'nip77.dart';

/// Internal implementation of NIP-77 Negentropy sync.
///
/// **Not part of the public API.** Use [Nip77] instead.
class _Nip77Internal {
  final GlobalState _globalState;
  final RelayManager _relayManager;
  final CacheManager _cacheManager;

  _Nip77Internal({
    required GlobalState globalState,
    required RelayManager relayManager,
    required CacheManager cacheManager,
  })  : _globalState = globalState,
        _relayManager = relayManager,
        _cacheManager = cacheManager;

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
      if (state.isCompleted) {
        return; // Guard: timeout may have fired during await
      }
      if (!connected) {
        state.completeWithError(
            Exception('Failed to connect to relay: $cleanUrl'));
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
      if (state.isCompleted) {
        return; // Guard: timeout may have fired during await
      }

      // Update state with local items
      state.localItems.addAll(localItems);

      // Create initial message (hex encoded per NIP-77)
      final initialMessage = neg.NegentropyEncoder.createInitialMessage(
          localItems, neg.NegentropyEncoder.idSize);
      final initialPayload = neg.NegentropyEncoder.bytesToHex(initialMessage);

      // Send NEG-OPEN (final guard before network action)
      if (state.isCompleted) return;
      final negOpen = [
        'NEG-OPEN',
        subscriptionId,
        filter.toMap(),
        initialPayload
      ];
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
      ids: filter.ids,
      pubKeys: filter.authors,
      kinds: filter.kinds,
      tags: filter.tags,
      since: filter.since,
      until: filter.until,
      search: filter.search,
      limit: filter.limit,
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
      Logger.log
          .w(() => 'Received NEG-MSG for unknown session: $subscriptionId');
      return;
    }

    // Verify relay origin to avoid cross-relay session contamination
    final cleanUrl = cleanRelayUrl(relayUrl);
    if (cleanUrl == null || state.relayUrl != cleanUrl) {
      Logger.log.w(() =>
          'Received NEG-MSG from mismatched relay: expected ${state.relayUrl}, got $relayUrl');
      return;
    }

    try {
      final messageBytes = neg.NegentropyEncoder.hexToBytes(payload);
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
        final responsePayload = neg.NegentropyEncoder.bytesToHex(response);
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
      Logger.log
          .w(() => 'Received NEG-ERR for unknown session: $subscriptionId');
      return;
    }

    // Verify relay origin to avoid cross-relay session contamination
    final cleanUrl = cleanRelayUrl(relayUrl);
    if (cleanUrl == null || state.relayUrl != cleanUrl) {
      Logger.log.w(() =>
          'Received NEG-ERR from mismatched relay: expected ${state.relayUrl}, got $relayUrl');
      return;
    }

    Logger.log.e(() => 'NEG-ERR from $cleanUrl: $errorMsg');

    if (errorMsg.contains('CLOSED') || errorMsg.contains('auth-required')) {
      state.completeWithError(Nip77NotSupportedException(cleanUrl, errorMsg));
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
