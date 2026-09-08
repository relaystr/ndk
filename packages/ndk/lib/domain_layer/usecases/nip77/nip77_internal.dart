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
    RelayAuth? auth,
  }) {
    final cleanUrl = cleanRelayUrl(relayUrl);
    if (cleanUrl == null) {
      throw ArgumentError('Invalid relay URL: $relayUrl');
    }

    // nothing can carry this reconciliation, and nothing is sent. Raised like
    // the invalid url above rather than through a future the caller has had no
    // chance to listen to yet
    final connectionKey = RelayAuth.keyFor(cleanUrl, auth);
    if (connectionKey == null) {
      throw Nip77AuthUnavailableException(cleanUrl, auth!.account!.pubkey);
    }

    // Generate subscription ID
    final subscriptionId = 'neg-${DateTime.now().microsecondsSinceEpoch}';

    // Create session state (starts with empty items, will be populated async)
    final state = Nip77State(
      subscriptionId: subscriptionId,
      connectionKey: connectionKey,
      filter: filter,
      localItems: [],
      auth: auth,
    );

    // Register in global state
    _globalState.inFlightNegotiations[subscriptionId] = state;

    // Set up timeout. The state owns it so an authentication can pause it
    state.startTimeout(timeout, () {
      if (state.isCompleted) return;
      _sendNegClose(state.connectionKey, subscriptionId);
      _fail(state, Nip77TimeoutException(cleanUrl, timeout));
    });

    // Start async initialization
    _startReconciliation(
      localIds: localIds,
      subscriptionId: subscriptionId,
      state: state,
    );

    return Nip77Response(state);
  }

  Future<void> _startReconciliation({
    required String subscriptionId,
    required Nip77State state,
    List<String>? localIds,
  }) async {
    final cleanUrl = state.connectionKey.url;
    try {
      final connectivity = await _openConnection(state);
      if (state.isCompleted) {
        return; // Guard: timeout may have fired during await
      }
      if (connectivity == null) {
        state.completeWithError(
          Exception('Failed to connect to relay: ${state.connectionKey}'),
        );
        _globalState.inFlightNegotiations.remove(subscriptionId);
        return;
      }

      // Check if relay supports NIP-77
      if (connectivity.relayInfo != null &&
          !connectivity.relayInfo!.supportsNip(77)) {
        state.completeWithError(Nip77NotSupportedException(cleanUrl));
        _globalState.inFlightNegotiations.remove(subscriptionId);
        return;
      }

      // Build local items from cache or provided IDs
      List<neg.NegentropyItem> localItems;
      if (localIds != null) {
        localItems = await _buildItemsFromIds(localIds);
      } else {
        localItems = await _buildItemsFromFilter(state.filter);
      }
      if (state.isCompleted) {
        return; // Guard: timeout may have fired during await
      }

      // Update state with local items
      state.localItems.addAll(localItems);

      _sendNegOpen(state);
    } catch (e) {
      state.completeWithError(e);
      _globalState.inFlightNegotiations.remove(subscriptionId);
    }
  }

  /// Opens the connection the session is bound to, handing over the account so
  /// a bound connection works for an identity that was never registered.
  Future<RelayConnectivity?> _openConnection(Nip77State state) async {
    final connected = await _relayManager.reconnectConnection(
      state.connectionKey,
      connectionSource: ConnectionSource.explicit,
      as: state.auth?.account,
    );
    if (!connected) {
      return null;
    }
    return _relayManager.getConnectivity(state.connectionKey);
  }

  /// Sends NEG-OPEN on the connection the session currently holds. The initial
  /// message is rebuilt from [Nip77State.localItems], so a refused negotiation
  /// can be reopened on another connection by calling this again.
  void _sendNegOpen(Nip77State state) {
    if (state.isCompleted) return;

    final initialMessage = neg.NegentropyEncoder.createInitialMessage(
      state.localItems,
      neg.NegentropyEncoder.idSize,
    );
    final negOpen = [
      'NEG-OPEN',
      state.subscriptionId,
      state.filter.toMap(),
      neg.NegentropyEncoder.bytesToHex(initialMessage),
    ];
    _send(state.connectionKey, negOpen);

    Logger.log.d(
      () => 'NEG-OPEN sent to ${state.connectionKey}: ${state.subscriptionId}',
    );
  }

  void _send(RelayConnectionKey key, List<dynamic> message) {
    _relayManager.getConnectivity(key)?.relayTransport?.send(
          jsonEncode(message),
        );
  }

  Future<List<neg.NegentropyItem>> _buildItemsFromIds(List<String> ids) async {
    final items = <neg.NegentropyItem>[];

    for (final id in ids) {
      final event = await _cacheManager.loadEvent(id);
      if (event != null) {
        items.add(
          neg.NegentropyItem.fromHex(timestamp: event.createdAt, idHex: id),
        );
      } else {
        items.add(neg.NegentropyItem.fromHex(timestamp: 0, idHex: id));
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
        .map(
          (e) =>
              neg.NegentropyItem.fromHex(timestamp: e.createdAt, idHex: e.id),
        )
        .toList();
  }

  /// The session [subscriptionId] belongs to, when the message really came
  /// from the connection it runs on. Matching the whole key, not just the url,
  /// keeps a message seen on the anonymous socket from feeding a session that
  /// moved to a bound one.
  Nip77State? _sessionFor(
    String subscriptionId,
    RelayConnectionKey key,
    String messageType,
  ) {
    final state = _globalState.inFlightNegotiations[subscriptionId];
    if (state == null) {
      Logger.log.w(
        () => 'Received $messageType for unknown session: $subscriptionId',
      );
      return null;
    }
    if (state.connectionKey != key) {
      Logger.log.w(
        () => 'Received $messageType from mismatched connection: expected '
            '${state.connectionKey}, got $key',
      );
      return null;
    }
    return state;
  }

  /// Process incoming NEG-MSG from a relay
  void processNegMsg(
    String subscriptionId,
    RelayConnectionKey key,
    String payload,
  ) {
    final state = _sessionFor(subscriptionId, key, 'NEG-MSG');
    if (state == null) return;

    try {
      final messageBytes = neg.NegentropyEncoder.hexToBytes(payload);
      final response = state.processMessage(messageBytes);

      if (response == null) {
        // Reconciliation complete
        _sendNegClose(key, subscriptionId);
        state.complete();
        _globalState.inFlightNegotiations.remove(subscriptionId);
        Logger.log.d(
          () =>
              'NEG reconciliation complete: need=${state.needIds.length}, have=${state.haveIds.length}',
        );
      } else {
        // Send response (hex encoded)
        final responsePayload = neg.NegentropyEncoder.bytesToHex(response);
        _send(key, ['NEG-MSG', subscriptionId, responsePayload]);
        Logger.log.d(() => 'NEG-MSG sent to $key');
      }
    } catch (e) {
      Logger.log.e(() => 'Error processing NEG-MSG: $e');
      state.completeWithError(e);
      _globalState.inFlightNegotiations.remove(subscriptionId);
    }
  }

  /// Process incoming NEG-ERR from a relay
  void processNegErr(
    String subscriptionId,
    RelayConnectionKey key,
    String errorMsg,
  ) {
    final state = _sessionFor(subscriptionId, key, 'NEG-ERR');
    if (state == null) return;

    Logger.log.e(() => 'NEG-ERR from $key: $errorMsg');

    if (_isAuthRefusal(errorMsg)) {
      _handleNegAuthRequired(state, errorMsg);
      return;
    }

    if (errorMsg.contains('CLOSED')) {
      state.completeWithError(
        Nip77NotSupportedException(key.url, errorMsg),
      );
    } else {
      state.completeWithError(Exception(errorMsg));
    }

    _globalState.inFlightNegotiations.remove(subscriptionId);
  }

  /// Process a CLOSED that ends a negotiation. NIP-77 only names NEG-ERR, but
  /// relays that gate NEG-OPEN behind NIP-42 commonly refuse it the way they
  /// refuse a REQ.
  void processNegClosed(
    String subscriptionId,
    RelayConnectionKey key,
    String? message,
  ) {
    final state = _sessionFor(subscriptionId, key, 'CLOSED');
    if (state == null) return;

    final reason = message ?? '';
    Logger.log
        .d(() => 'CLOSED for negotiation $subscriptionId on $key: $reason');

    if (_isAuthRefusal(reason)) {
      _handleNegAuthRequired(state, reason);
      return;
    }

    state.completeWithError(Exception(reason.isEmpty ? 'closed' : reason));
    _globalState.inFlightNegotiations.remove(subscriptionId);
  }

  /// NIP-77 only suggests `blocked` and `closed`, so a relay that gates the
  /// negotiation behind an identity says so in the machine-readable prefixes
  /// NIP-01 defines for CLOSED.
  bool _isAuthRefusal(String message) {
    final lower = message.toLowerCase();
    return lower.contains('auth-required') || lower.contains('restricted');
  }

  void _fail(Nip77State state, Object error) {
    state.completeWithError(error);
    _globalState.inFlightNegotiations.remove(state.subscriptionId);
  }

  /// Reopens a refused negotiation on a connection bound to an identity, the
  /// way a refused REQ is retried.
  void _handleNegAuthRequired(Nip77State state, String message) {
    final url = state.connectionKey.url;

    // a refusal that lands mid-session cannot be replayed: the streams already
    // emitted, and a fresh NEG-OPEN would report those ids twice
    if (state.needIds.isNotEmpty || state.haveIds.isNotEmpty) {
      _fail(state, Nip77AuthRequiredException(url, message));
      return;
    }

    final account = _relayManager.accountForAuth(state.auth);
    if (account == null) {
      _fail(state, Nip77AuthRequiredException(url, message));
      return;
    }

    // the connection is already bound, so the relay wants the AUTH it has not
    // been given yet rather than another identity
    if (!state.connectionKey.isAnonymous) {
      if (state.authenticatedAfterRefusal) {
        _fail(state, Nip77AuthRequiredException(url, message));
        return;
      }
      unawaited(_authenticateAndReopen(state, message));
      return;
    }

    if (state.movedToBoundConnection) {
      _fail(state, Nip77AuthRequiredException(url, message));
      return;
    }
    unawaited(_moveToBoundConnection(state, account, message));
  }

  /// Answers the challenge on the bound connection, then reopens.
  ///
  /// The timeout is paused: signing may sit on a remote signer waiting for a
  /// human, which is not time the relay is taking to reconcile.
  Future<void> _authenticateAndReopen(Nip77State state, String message) async {
    final url = state.connectionKey.url;
    state.authenticatedAfterRefusal = true;

    state.pauseTimeout();
    final authenticated =
        await _relayManager.authenticateConnection(state.connectionKey);

    if (state.isCompleted) return;
    state.resumeTimeout();

    if (!authenticated) {
      _fail(state, Nip77AuthRequiredException(url, message));
      return;
    }
    _sendNegOpen(state);
  }

  /// Moves a refused anonymous negotiation onto a connection bound to
  /// [account]. The timeout is paused for the same reason as above: opening
  /// that connection is not the relay reconciling.
  Future<void> _moveToBoundConnection(
    Nip77State state,
    Account account,
    String message,
  ) async {
    final url = state.connectionKey.url;
    state.movedToBoundConnection = true;

    Logger.log.d(
      () => 'AUTH required for negotiation ${state.subscriptionId} on $url, '
          'retrying as ${account.pubkey}',
    );

    state.pauseTimeout();
    final bound = await _relayManager.openConnectionAs(
      url,
      account,
      connectionSource: ConnectionSource.explicit,
    );

    if (state.isCompleted) return;
    state.resumeTimeout();

    if (bound == null) {
      _fail(state, Nip77AuthRequiredException(url, message));
      return;
    }
    state.connectionKey = bound.key;
    // sent without waiting for the AUTH: a relay that only challenges on
    // demand needs this NEG-OPEN as the trigger, and the challenge it then
    // sends authenticates the bound connection on its own
    _sendNegOpen(state);
  }

  void _sendNegClose(RelayConnectionKey key, String subscriptionId) {
    _send(key, ['NEG-CLOSE', subscriptionId]);
    Logger.log.d(() => 'NEG-CLOSE sent to $key: $subscriptionId');
  }

  void close(String subscriptionId) {
    final state = _globalState.inFlightNegotiations[subscriptionId];
    if (state != null) {
      _sendNegClose(state.connectionKey, subscriptionId);
      state.close();
      _globalState.inFlightNegotiations.remove(subscriptionId);
    }
  }

  void closeAll() {
    for (final entry in _globalState.inFlightNegotiations.entries.toList()) {
      _sendNegClose(entry.value.connectionKey, entry.key);
      entry.value.close();
    }
    _globalState.inFlightNegotiations.clear();
  }
}
