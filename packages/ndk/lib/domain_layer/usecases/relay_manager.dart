import 'dart:async';
import 'dart:convert';

import 'package:rxdart/rxdart.dart';

import '../../config/bootstrap_relays.dart';
import '../../config/relay_defaults.dart';
import '../../config/request_defaults.dart';
import '../../shared/decode_nostr_msg/decode_nostr_msg.dart';
import '../../shared/helpers/relay_helper.dart';
import '../../shared/isolates/isolate_manager.dart';
import '../../shared/logger/logger.dart';
import '../../shared/nips/nip01/client_msg.dart';
import '../entities/account.dart';
import '../entities/broadcast_state.dart';
import '../entities/connection_source.dart';
import '../entities/filter.dart';
import '../entities/global_state.dart';
import '../entities/nip_01_event.dart';
import '../entities/nostr_message_raw.dart';
import '../entities/relay.dart';
import '../entities/relay_connection_key.dart';
import '../entities/relay_connectivity.dart';
import '../entities/relay_info.dart';
import '../entities/request_state.dart';
import '../entities/tuple.dart';
import '../repositories/nostr_transport.dart';
import 'accounts/accounts.dart';
import 'engines/network_engine.dart';
import 'nip42/auth_event.dart';

///  relay manager, responsible for lifecycle of relays, sending messages, \
///  and help with tracking of requests
class RelayManager<T> {
  final Completer<void> _seedRelaysCompleter = Completer<void>();

  /// completes when all seed relays are connected
  Future<void> get seedRelaysConnected => _seedRelaysCompleter.future;

  /// global state obj
  GlobalState globalState;

  /// signer for nip-42 AUTH challenges from relays
  final Accounts? _accounts;

  /// stores the last AUTH challenge per connection for late authentication;
  /// each socket gets its own challenge, so this cannot be keyed by relay
  final Map<RelayConnectionKey, String> _lastChallengePerConnection = {};

  /// stores pending AUTH callbacks: authEventId -> callback run on the relay's
  /// OK, with whether the relay accepted the AUTH event
  final Map<String, void Function(bool accepted)> _pendingAuthCallbacks = {};

  /// stores timers for pending AUTH callbacks to clean them up on timeout
  final Map<String, Timer> _pendingAuthTimers = {};

  /// waiters for the AUTH challenge of a connection that is being authenticated
  final Map<RelayConnectionKey, Completer<String>> _challengeWaiters = {};

  /// in flight authentications, so concurrent callers share a single AUTH
  final Map<RelayConnectionKey, Future<bool>> _authenticating = {};

  /// connections whose AUTH event the relay accepted
  final Set<RelayConnectionKey> _authenticatedConnections = {};

  /// Tracks relay connect attempts that are still finishing setup so callers
  /// can wait for "socket open + listener attached", not just raw socket open.
  final Map<RelayConnectionKey, Completer<bool>> _connectReadyCompleters = {};

  /// timeout for AUTH callbacks (how long to wait for AUTH OK)
  final Duration authCallbackTimeout;

  /// how long to wait for a NIP-42 challenge once authentication was asked for
  final Duration authChallengeTimeout;

  /// Handler for NIP-77 NEG-MSG messages
  void Function(String subscriptionId, String relayUrl, String payload)?
  onNegMsg;

  /// Handler for NIP-77 NEG-ERR messages
  void Function(String subscriptionId, String relayUrl, String errorMsg)?
  onNegErr;

  /// nostr transport factory, to create new transports (usually websocket)
  final NostrTransportFactory nostrTransportFactory;

  /// factory for creating additional data for the engine
  final EngineAdditionalDataFactory? engineAdditionalDataFactory;

  /// Are reconnects allowed when a connection drops?
  bool allowReconnectRelays = true;

  /// stream controller for relay updates
  final _relayUpdatesStreamController =
      BehaviorSubject<List<RelayConnectivity>>();

  /// stream of connection updates, used to notify connectivity changes, latest
  /// value is cached. A relay can hold several connections, so this cannot be
  /// indexed by url; group by [RelayConnectivity.url] if you need to.
  Stream<List<RelayConnectivity>> get relayConnectivityChanges =>
      _relayUpdatesStreamController.stream;

  /// Creates a new relay manager.
  RelayManager({
    required this.globalState,
    required this.nostrTransportFactory,
    Accounts? accounts,
    this.engineAdditionalDataFactory,
    List<String>? bootstrapRelays,
    allowReconnect = true,
    this.authCallbackTimeout = RequestDefaults.DEFAULT_AUTH_CALLBACK_TIMEOUT,
    this.authChallengeTimeout = RequestDefaults.DEFAULT_AUTH_CHALLENGE_TIMEOUT,
  }) : _accounts = accounts {
    allowReconnectRelays = allowReconnect;
    _connectSeedRelays(urls: bootstrapRelays ?? DEFAULT_BOOTSTRAP_RELAYS);
  }

  void updateRelayConnectivity() {
    _relayUpdatesStreamController.add(globalState.relays.values.toList());
  }

  /// This will initialize the manager with bootstrap relays.
  /// If you don't give any, will use some predefined
  Future<void> _connectSeedRelays({
    Iterable<String> urls = DEFAULT_BOOTSTRAP_RELAYS,
  }) async {
    List<String> bootstrapRelays = [];
    for (String url in urls) {
      String? clean = cleanRelayUrl(url);
      if (clean != null) {
        bootstrapRelays.add(clean);
      }
    }
    if (bootstrapRelays.isEmpty) {
      bootstrapRelays = DEFAULT_BOOTSTRAP_RELAYS;
    }
    await Future.wait(
      urls
          .map(
            (url) => connectRelay(
              dirtyUrl: url,
              connectionSource: ConnectionSource.seed,
            ),
          )
          .toList(),
    ).whenComplete(() {
      if (!_seedRelaysCompleter.isCompleted) {
        _seedRelaysCompleter.complete();
      }
    });
  }

  /// Returns a list of fully connected relays, excluding connecting ones.
  /// DO NOT USE THIS FOR CHECKING A SINGLE RELAY, use [isRelayConnected] INSTEAD
  List<RelayConnectivity> get connectedRelays => globalState.relays.values
      .where((connectivity) => connectivity.isConnected)
      .toList();

  /// Connected connections bound to nobody, one per relay at most.
  ///
  /// Engines pick relays, not identities: sending on every connection of a
  /// relay would duplicate the request, and sending on a bound one would make
  /// it attributable. An identity is added later, by the re-route, and only on
  /// the relays that ask for one.
  List<RelayConnectivity> get connectedAnonymousRelays => globalState
      .relays
      .values
      .where((connectivity) => connectivity.key.isAnonymous)
      .where((connectivity) => connectivity.isConnected)
      .toList();

  /// checks if a relay is connected, avoid using this
  bool isRelayConnected(String url) =>
      isConnectionOpen(RelayConnectionKey.anonymous(url));

  /// checks if a relay is connecting
  bool isRelayConnecting(String url) =>
      isConnectionConnecting(RelayConnectionKey.anonymous(url));

  /// checks if the connection identified by [key] is open
  bool isConnectionOpen(RelayConnectionKey key) =>
      globalState.relays[key]?.relayTransport?.isOpen() ?? false;

  /// checks if the connection identified by [key] is connecting
  bool isConnectionConnecting(RelayConnectionKey key) {
    final relay = globalState.relays[key]?.relay;
    return relay != null && relay.connecting;
  }

  Future<bool> _waitForTransportOpen(
    NostrTransport transport, {
    required int timeoutSeconds,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: timeoutSeconds));

    while (DateTime.now().isBefore(deadline)) {
      if (transport.isOpen()) {
        return true;
      }

      try {
        await transport.ready.timeout(const Duration(milliseconds: 250));
      } catch (_) {
        // keep polling isOpen() until the overall timeout expires
      }

      if (transport.isOpen()) {
        return true;
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    return transport.isOpen();
  }

  /// Connects to a relay to the relay pool.
  /// Returns a tuple with the first element being a boolean indicating success \\
  /// and the second element being a string with the error message if any.
  Future<Tuple<bool, String>> connectRelay({
    required String dirtyUrl,
    required ConnectionSource connectionSource,
    String? authPubkey,
    int connectTimeout = DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT,
  }) async {
    String? url = cleanRelayUrl(dirtyUrl);
    if (url == null) {
      updateRelayConnectivity();
      return Tuple(false, "unclean url");
    }
    if (globalState.blockedRelays.contains(url)) {
      updateRelayConnectivity();
      return Tuple(false, "relay is blocked");
    }

    final connectionKey = authPubkey == null
        ? RelayConnectionKey.anonymous(url)
        : RelayConnectionKey.authenticated(url, authPubkey);

    if (isConnectionOpen(connectionKey)) {
      Logger.log.t(() => "relay already connected: $connectionKey");
      updateRelayConnectivity();
      return Tuple(true, "");
    }

    if (isConnectionConnecting(connectionKey)) {
      Logger.log.t(() => "relay is already connecting: $connectionKey");
      final inFlightConnect = _connectReadyCompleters[connectionKey];
      if (inFlightConnect != null) {
        final connected = await inFlightConnect.future;
        updateRelayConnectivity();
        return Tuple(
          connected,
          connected
              ? "relay finished connecting"
              : "relay failed while connecting",
        );
      }
      updateRelayConnectivity();
      return Tuple(false, "relay is still connecting");
    }
    RelayConnectivity? relayConnectivity = globalState.relays[connectionKey];
    final connectCompleter = Completer<bool>();
    _connectReadyCompleters[connectionKey] = connectCompleter;

    try {
      if (relayConnectivity == null) {
        relayConnectivity = RelayConnectivity<T>(
          key: connectionKey,
          relay: Relay(url: url, connectionSource: connectionSource),
          specificEngineData: engineAdditionalDataFactory?.call(),
        );
        globalState.relays[connectionKey] = relayConnectivity;
      }

      relayConnectivity.relay.tryingToConnect();

      /// TO BE REMOVED, ONCE WE FIND A WAY OF AVOIDING PROBLEM WHEN CONNECTING TO THIS
      if (url.startsWith("wss://brb.io")) {
        relayConnectivity.relay.failedToConnect();
        if (!connectCompleter.isCompleted) {
          connectCompleter.complete(false);
        }
        if (identical(
          _connectReadyCompleters[connectionKey],
          connectCompleter,
        )) {
          _connectReadyCompleters.remove(connectionKey);
        }
        updateRelayConnectivity();
        return Tuple(false, "bad relay");
      }

      Logger.log.i(() => "connecting to relay $dirtyUrl");

      relayConnectivity.relayTransport = nostrTransportFactory(
        url,
        onReconnect: () {
          // the relay accepted our AUTH on the socket that just died, not on
          // this one; the binding survives, the authentication does not
          _authenticatedConnections.remove(connectionKey);
          _lastChallengePerConnection.remove(connectionKey);
          reSubscribeInFlightSubscriptions(relayConnectivity!);
          updateRelayConnectivity();
        },
        onDisconnect: (code, error, reason) {
          relayConnectivity!.stats.connectionErrors++;
          updateRelayConnectivity();
        },
      );
      // Start listening immediately so we don't miss early frames such as
      // relay AUTH challenges that may arrive before the transport reports
      // itself fully open.
      _startListeningToSocket(relayConnectivity);
      final opened = await _waitForTransportOpen(
        relayConnectivity.relayTransport!,
        timeoutSeconds: connectTimeout,
      );
      if (!opened) {
        throw TimeoutException(
          "Future not completed",
          Duration(seconds: connectTimeout),
        );
      }

      Logger.log.i(() => "connected to relay: $url");
      relayConnectivity.relay.succeededToConnect();
      relayConnectivity.stats.connections++;
      getRelayInfo(url).then((info) {
        relayConnectivity!.relayInfo = info;
      });
      if (!connectCompleter.isCompleted) {
        connectCompleter.complete(true);
      }
      if (identical(_connectReadyCompleters[connectionKey], connectCompleter)) {
        _connectReadyCompleters.remove(connectionKey);
      }
      updateRelayConnectivity();
      return Tuple(true, "");
    } catch (e) {
      Logger.log.e(() => "!! could not connect to $url -> $e");
      await relayConnectivity!.close();
    }
    relayConnectivity.relay.failedToConnect();
    relayConnectivity.stats.connectionErrors++;
    if (!connectCompleter.isCompleted) {
      connectCompleter.complete(false);
    }
    if (identical(_connectReadyCompleters[connectionKey], connectCompleter)) {
      _connectReadyCompleters.remove(connectionKey);
    }
    updateRelayConnectivity();
    return Tuple(false, "could not connect to $url");
  }

  /// Reconnects the anonymous connection to a relay, if it is closed.
  Future<bool> reconnectRelay(
    String url, {
    required ConnectionSource connectionSource,
    bool force = false,
  }) => reconnectConnection(
    RelayConnectionKey.anonymous(url),
    connectionSource: connectionSource,
    force: force,
  );

  /// Reconnects the connection identified by [key], if it is closed. An
  /// authenticated connection comes back authenticated or not at all.
  Future<bool> reconnectConnection(
    RelayConnectionKey key, {
    required ConnectionSource connectionSource,
    bool force = false,
  }) async {
    final inFlightConnect = _connectReadyCompleters[key];
    if (inFlightConnect != null) {
      final connected = await inFlightConnect.future;
      updateRelayConnectivity();
      return connected;
    }

    RelayConnectivity? relayConnectivity = globalState.relays[key];
    if (relayConnectivity != null && relayConnectivity.relayTransport != null) {
      try {
        final opened = await _waitForTransportOpen(
          relayConnectivity.relayTransport!,
          timeoutSeconds: DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT,
        );
        if (opened && relayConnectivity.relayTransport!.isOpen()) {
          updateRelayConnectivity();
          return true;
        }
      } catch (error) {
        Logger.log.e(() => "error connecting to $key: $error");
      }
    }
    if (relayConnectivity == null ||
        relayConnectivity.relayTransport == null ||
        !relayConnectivity.relayTransport!.isOpen()) {
      if (!force &&
          (relayConnectivity != null &&
              !relayConnectivity.relay.wasLastConnectTryLongerThanSeconds(
                FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS,
              ))) {
        // don't try too often
        updateRelayConnectivity();
        return false;
      }

      if (!key.isAnonymous) {
        final account = _accounts?.accounts[key.pubkey];
        if (account == null) {
          Logger.log.w(() => "No account left to reconnect $key");
          return false;
        }
        return await openConnectionAs(
              key.url,
              account,
              connectionSource: connectionSource,
            ) !=
            null;
      }

      if (!(await connectRelay(
        dirtyUrl: key.url,
        connectionSource: connectionSource,
      )).first) {
        // could not connect
        return false;
      }
      relayConnectivity = globalState.relays[key];
      if (relayConnectivity == null ||
          relayConnectivity.relayTransport == null ||
          !relayConnectivity.relayTransport!.isOpen()) {
        // web socket is not open
        return false;
      }
    }
    return true;
  }

  /// Closes and clears only transport-scoped state of every connection to
  /// [url], while keeping the entries and relay-scoped metadata in memory.
  Future<void> resetTransport(String url) async {
    await Future.wait(_connectionKeysForRelay(url).map(resetConnection));
  }

  /// Closes and clears only transport-scoped state of one connection, while
  /// keeping its entry and relay-scoped metadata in memory.
  Future<void> resetConnection(RelayConnectionKey key) async {
    final connectivity = globalState.relays[key];
    if (connectivity != null) {
      Logger.log.d(() => "Resetting transport for $key...");
      connectivity.relay.failedToConnect();
      _authenticatedConnections.remove(key);
      _lastChallengePerConnection.remove(key);
      await connectivity.close();
      updateRelayConnectivity();
    }
  }

  /// every connection currently held towards [url]
  List<RelayConnectionKey> _connectionKeysForRelay(String url) {
    final relayUrl = RelayConnectionKey.anonymous(url).url;
    return globalState.relays.keys.where((key) => key.url == relayUrl).toList();
  }

  /// Reconnects all given relays
  Future<void> reconnectRelays(Iterable<String> urls) async {
    final startTime = DateTime.now();
    Logger.log.d(() => "connecting ${urls.length} relays in parallel");
    List<bool> connected = await Future.wait(
      urls.map(
        (url) => reconnectRelay(
          url,
          connectionSource: ConnectionSource.explicit,
          force: true,
        ),
      ),
    );
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.d(
      () =>
          "CONNECTED ${connected.where((element) => element).length} , ${connected.where((element) => !element).length} FAILED, took ${duration.inMilliseconds} ms",
    );
  }

  void reSubscribeInFlightSubscriptions(RelayConnectivity relayConnectivity) {
    final transport = relayConnectivity.relayTransport;
    if (transport == null || !transport.isOpen()) {
      return;
    }

    globalState.inFlightRequests.forEach((key, state) {
      state.requests.values
          // by connection, not by relay: replaying a bound request on the
          // anonymous socket gets it refused, and replaying an anonymous one on
          // a bound socket makes it attributable. An entry the relay already
          // refused stays refused, replaying it only retriggers the re-route.
          .where(
            (req) => req.key == relayConnectivity.key && !req.receivedClosed,
          )
          .forEach((req) {
            if (!state.request.closeOnEOSE) {
              List<dynamic> list = ["REQ", state.id];
              list.addAll(req.filters.map((filter) => filter.toMap()));

              relayConnectivity.stats.activeRequests++;
              _sendRaw(relayConnectivity, transport, jsonEncode(list));
            }
          });
    });
  }

  void _sendRaw(
    RelayConnectivity relayConnectivity,
    NostrTransport transport,
    dynamic data,
  ) {
    if (!identical(relayConnectivity.relayTransport, transport) ||
        !transport.isOpen()) {
      Logger.log.t(
        () =>
            "skip send to ${relayConnectivity.url}: transport changed or closed",
      );
      return;
    }
    transport.send(data);
    Logger.log.d(() => "send message to ${relayConnectivity.url}: $data");
  }

  /// Sends a [ClientMsg] and surfaces transport churn/closed-socket failures to
  /// the caller instead of silently dropping the write.
  Future<void> sendOrThrow(
    RelayConnectivity relayConnectivity,
    ClientMsg msg,
  ) async {
    NostrTransport? transport = relayConnectivity.relayTransport;
    if (transport == null) {
      throw StateError("relay not connected: ${relayConnectivity.url}");
    }

    await transport.ready;

    if (!identical(relayConnectivity.relayTransport, transport) ||
        !transport.isOpen()) {
      transport = relayConnectivity.relayTransport;
      if (transport == null) {
        throw StateError(
          "transport changed while waiting for ${relayConnectivity.url}",
        );
      }

      await transport.ready;

      if (!identical(relayConnectivity.relayTransport, transport) ||
          !transport.isOpen()) {
        throw StateError(
          "transport changed while waiting for ${relayConnectivity.url}",
        );
      }
    }

    final String encodedMsg = jsonEncode(msg.toJson());
    if (!identical(relayConnectivity.relayTransport, transport) ||
        !transport.isOpen()) {
      throw StateError(
        "transport closed before send: ${relayConnectivity.url}",
      );
    }
    _sendRaw(relayConnectivity, transport, encodedMsg);
  }

  /// sends a [ClientMsg] to relay transport sink, throw an error if relay not connected
  void send(RelayConnectivity relayConnectivity, ClientMsg msg) {
    unawaited(
      sendOrThrow(relayConnectivity, msg).catchError((Object error) {
        Logger.log.t(() => "skip send to ${relayConnectivity.url}: $error");
      }),
    );
  }

  /// use this to register your request against a relay, \
  /// this is needed so the response from a relay can be tracked back
  void registerRelayRequest({
    required String reqId,
    required RelayConnectionKey connectionKey,
    required List<Filter> filters,
  }) {
    // new tracking
    if (globalState.inFlightRequests[reqId]!.requests[connectionKey] == null) {
      globalState.inFlightRequests[reqId]!.requests[connectionKey] =
          RelayRequestState(connectionKey, filters);
    } else {
      // do not overwrite and add new filters
      globalState.inFlightRequests[reqId]!.requests[connectionKey]!.filters
          .addAll(filters);
    }
  }

  /// use this to register your broadcast against a relay, \
  /// this is needed so the response from a relay can be tracked back
  void registerRelayBroadcast({
    required String relayUrl,
    required Nip01Event eventToPublish,
  }) {
    final broadcastState = globalState.inFlightBroadcasts[eventToPublish.id];
    if (broadcastState == null) {
      Logger.log.w(
        () =>
            "registerRelayBroadcast: no broadcast state for ${eventToPublish.id}",
      );
      return;
    }

    // Store the event for potential retries on auth-required
    broadcastState.event ??= eventToPublish;

    // new tracking
    if (broadcastState.broadcasts[relayUrl] == null) {
      broadcastState.broadcasts[relayUrl] = RelayBroadcastResponse(
        relayUrl: relayUrl,
      );
    } else {
      // do not overwrite
      Logger.log.w(
        () =>
            "registerRelayBroadcast: relay broadcast already registered for ${eventToPublish.id} $relayUrl, skipping",
      );
    }
  }

  /// use this to signal a failed broadcast
  void failBroadcast(String nostrEventId, String relay, String msg) {
    final broadcastState = globalState.inFlightBroadcasts[nostrEventId];
    if (broadcastState == null) {
      return;
    }
    if (broadcastState.networkController.isClosed) {
      Logger.log.w(
        () =>
            "Ignoring late failed broadcast for $nostrEventId on $relay because the broadcast controller is already closed",
      );
      return;
    }

    broadcastState.networkController.add(
      RelayBroadcastResponse(
        relayUrl: relay,
        okReceived: false,
        broadcastSuccessful: false,
        msg: msg,
      ),
    );
  }

  void _startListeningToSocket(RelayConnectivity relayConnectivity) {
    relayConnectivity.listen(
      (message) {
        _handleIncomingMessage(message, relayConnectivity);
      },
      onError: (error) async {
        Logger.log.e(() => "onError ${relayConnectivity.url} on listen $error");
        relayConnectivity.stats.connectionErrors++;
        try {
          await relayConnectivity.close();
        } catch (e) {
          Logger.log.w(
            () => "Error closing relay ${relayConnectivity.url}: $e",
          );
        }
        updateRelayConnectivity();
      },
      onDone: () async {
        Logger.log.t(
          () =>
              "onDone ${relayConnectivity.url} on listen (close: ${relayConnectivity.relayTransport?.closeCode()} ${relayConnectivity.relayTransport?.closeReason()})",
        );

        try {
          await relayConnectivity.close();
        } catch (e) {
          Logger.log.w(
            () => "Error closing relay ${relayConnectivity.url}: $e",
          );
        }
        // the socket is gone, so is the AUTH the relay accepted on it
        _authenticatedConnections.remove(relayConnectivity.key);
        _lastChallengePerConnection.remove(relayConnectivity.key);
        updateRelayConnectivity();
        // Reconnect on close. close() above nulls relayTransport, so the only
        // condition is that the relay is still tracked: deliberate closes cancel
        // the stream subscription first and never reach this handler.
        if (allowReconnectRelays &&
            globalState.relays[relayConnectivity.key] != null) {
          Logger.log.i(() => "closed ${relayConnectivity.url}. Reconnecting");
          reconnectConnection(
            relayConnectivity.key,
            connectionSource: relayConnectivity.relay.connectionSource,
          ).then((connected) {
            updateRelayConnectivity();
            if (connected) {
              reSubscribeInFlightSubscriptions(relayConnectivity);
            }
          });
        }
      },
    );
  }

  // Track processing order per relay so EVENT/EOSE/AUTH/CLOSED ordering stays
  // correct without introducing cross-relay head-of-line blocking.
  final Map<String, Completer<void>> _lastMessageCompleters = {};

  Future<void> _handleIncomingMessage(
    dynamic message,
    RelayConnectivity relayConnectivity,
  ) async {
    final relayUrl = relayConnectivity.url;
    final previousMessage = _lastMessageCompleters[relayUrl];

    final myCompleter = Completer<void>();
    _lastMessageCompleters[relayUrl] = myCompleter;

    NostrMessageRaw nostrMsg;
    try {
      nostrMsg = await IsolateManager.instance
          .runInEncodingIsolate<String, NostrMessageRaw>(
            decodeNostrMsg,
            message,
          );
    } catch (e) {
      // Isolates not available on web
      nostrMsg = decodeNostrMsg(message);
    }

    if (previousMessage != null) {
      await previousMessage.future;
    }
    try {
      await _processDecodedMessage(nostrMsg, relayConnectivity, message);
    } finally {
      if (!myCompleter.isCompleted) {
        myCompleter.complete();
      }
      if (identical(_lastMessageCompleters[relayUrl], myCompleter)) {
        _lastMessageCompleters.remove(relayUrl);
      }
    }
  }

  Future<void> _processDecodedMessage(
    NostrMessageRaw nostrMsg,
    RelayConnectivity relayConnectivity,
    dynamic message,
  ) {
    if (nostrMsg.type == NostrMessageRawType.unknown) {
      Logger.log.w(
        () =>
            "Received non NostrMessageRaw message from ${relayConnectivity.url}: $nostrMsg",
      );
      return Future.value();
    }

    if (nostrMsg.type == NostrMessageRawType.ok) {
      final eventJson = nostrMsg.otherData;
      final String eventId = eventJson[1];
      final bool success = eventJson[2] == true;
      final String? msg = eventJson.length > 3 ? eventJson[3] : null;

      // Check if this is an AUTH OK response
      if (_pendingAuthCallbacks.containsKey(eventId)) {
        _pendingAuthTimers[eventId]?.cancel();
        _pendingAuthTimers.remove(eventId);
        if (success) {
          Logger.log.d(() => "AUTH OK for $eventId, executing callback");
        } else {
          Logger.log.e(() => "AUTH failed for $eventId: $msg");
        }
        final callback = _pendingAuthCallbacks.remove(eventId);
        callback?.call(success);
        return Future.value();
      }

      //nip 20 used to notify clients if an EVENT was successful
      if (!success) {
        Logger.log.e(() => "NOT OK from ${relayConnectivity.url}: $eventJson");

        // Check if this is auth-required for a broadcast - don't mark as done, will retry
        if (msg != null && msg.startsWith("auth-required")) {
          _handleBroadcastAuthRequired(eventId, relayConnectivity);
          return Future.value(); // Don't add to network controller yet, wait for retry result
        }
      }
      if (globalState.inFlightBroadcasts[eventId] != null &&
          !globalState
              .inFlightBroadcasts[eventId]!
              .networkController
              .isClosed) {
        globalState.inFlightBroadcasts[eventId]?.networkController.add(
          RelayBroadcastResponse(
            relayUrl: relayConnectivity.url,
            okReceived: true,
            broadcastSuccessful: success,
            msg: msg ?? '',
          ),
        );
      } else {
        Logger.log.w(
          () =>
              "Received OK for broadcast $eventId but the network controller is already closed",
        );
      }
      return Future.value();
    }
    if (nostrMsg.type == NostrMessageRawType.notice) {
      final eventJson = nostrMsg.otherData;
      final noticeMsg = eventJson[1] as String? ?? '';
      Logger.log.w(() => "NOTICE from ${relayConnectivity.url}: $noticeMsg");
      _logActiveRequests();

      // Check if this is a negentropy-related error
      // Look for various patterns relays might use to reject NEG commands
      final noticeLower = noticeMsg.toLowerCase();
      final isNegentropyError =
          noticeLower.contains('negentropy') ||
          noticeLower.contains('neg-') ||
          noticeLower.contains('unsupported') ||
          noticeLower.contains('unknown command') ||
          noticeLower.contains('not implemented') ||
          noticeLower.contains('nip-77');

      if (isNegentropyError) {
        // Fail all in-flight negotiations for this relay
        final relayUrl = relayConnectivity.url;
        final toRemove = <String>[];
        for (final entry in globalState.inFlightNegotiations.entries) {
          if (entry.value.relayUrl == relayUrl) {
            entry.value.completeWithError(
              Exception('Relay does not support NIP-77: $noticeMsg'),
            );
            toRemove.add(entry.key);
          }
        }
        for (final key in toRemove) {
          globalState.inFlightNegotiations.remove(key);
        }
      }
    } else if (nostrMsg.type == NostrMessageRawType.event) {
      _handleIncomingEvent(
        nostrMsg,
        relayConnectivity,
        message.toString().codeUnits.length,
      );
      // Logger.log.t(()=>"EVENT from ${relayConnectivity.url}: $eventJson");
    } else if (nostrMsg.type == NostrMessageRawType.eose) {
      final eventJson = nostrMsg.otherData;
      Logger.log.d(() => "EOSE from ${relayConnectivity.url}: ${eventJson[1]}");
      _handleEOSE(eventJson, relayConnectivity);
    } else if (nostrMsg.type == NostrMessageRawType.closed) {
      final eventJson = nostrMsg.otherData;
      Logger.log.w(
        () =>
            " CLOSED subscription url: ${relayConnectivity.url} id: ${eventJson[1]} msg: ${eventJson.length > 2 ? eventJson[2] : ''}",
      );
      _handleClosed(eventJson, relayConnectivity);
    }
    if (nostrMsg.type == NostrMessageRawType.auth) {
      final eventJson = nostrMsg.otherData;
      // nip 42 used to send authentication challenges
      final challenge = eventJson[1];
      Logger.log.d(
        () => "AUTH challenge from ${relayConnectivity.key}: $challenge",
      );

      _lastChallengePerConnection[relayConnectivity.key] = challenge;

      final waiter = _challengeWaiters.remove(relayConnectivity.key);
      if (waiter != null && !waiter.isCompleted) {
        waiter.complete(challenge);
      }

      // an anonymous connection never answers a challenge: signing here would
      // bind it to an identity nobody asked for, and every request already on
      // it would become attributable. A bound one answers as soon as it can.
      if (!relayConnectivity.key.isAnonymous) {
        unawaited(authenticateConnection(relayConnectivity.key));
      }
      return Future.value();
    }
    if (nostrMsg.type == NostrMessageRawType.negMsg) {
      final msgData = nostrMsg.otherData;
      if (msgData.length >= 3 && onNegMsg != null) {
        final subscriptionId = msgData[1] as String;
        final payload = msgData[2] as String;
        onNegMsg!(subscriptionId, relayConnectivity.url, payload);
      }
      return Future.value();
    }
    if (nostrMsg.type == NostrMessageRawType.negErr) {
      final msgData = nostrMsg.otherData;
      if (msgData.length >= 3 && onNegErr != null) {
        final subscriptionId = msgData[1] as String;
        final errorMsg = msgData[2] as String;
        onNegErr!(subscriptionId, relayConnectivity.url, errorMsg);
      }
      return Future.value();
    }
    return Future.value();
    //
    // if (eventJson[0] == 'COUNT') {
    //   log("COUNT: ${eventJson[1]}");
    //   // nip 45 used to send requested event counts to clients
    //   return;
    // }
  }

  /// Opens the connection towards [url] bound to [account]. The binding says
  /// which identity this socket may ever assume, not that it is already
  /// authenticated: relays are free to send their challenge whenever they want,
  /// and some only send it once a request needs it.
  Future<RelayConnectivity?> openConnectionAs(
    String url,
    Account account, {
    ConnectionSource connectionSource = ConnectionSource.explicit,
  }) async {
    if (!account.signer.canSign()) {
      Logger.log.w(() => "Cannot bind a connection to ${account.pubkey}");
      return null;
    }
    final key = RelayConnectionKey.authenticated(url, account.pubkey);

    if (isConnectionOpen(key)) {
      return globalState.relays[key];
    }

    final connected = await connectRelay(
      dirtyUrl: url,
      connectionSource: connectionSource,
      authPubkey: account.pubkey,
    );
    final connectivity = globalState.relays[key];
    if (!connected.first || connectivity == null) {
      Logger.log.w(() => "Could not open $key: ${connected.second}");
      return null;
    }
    return connectivity;
  }

  /// Waits for the AUTH challenge of [key]. Only call this once something has
  /// asked for authentication, otherwise a relay that only challenges on demand
  /// would never answer. Returns null if it never arrives.
  Future<String?> _awaitChallenge(RelayConnectionKey key) async {
    final stored = _lastChallengePerConnection[key];
    if (stored != null) {
      return stored;
    }
    final waiter = _challengeWaiters.putIfAbsent(key, Completer<String>.new);
    try {
      return await waiter.future.timeout(authChallengeTimeout);
    } catch (_) {
      _challengeWaiters.remove(key);
      Logger.log.w(() => "No AUTH challenge from $key");
      return null;
    }
  }

  /// Answers the challenge for [key] and completes once the relay accepted the
  /// AUTH event. Concurrent callers share a single AUTH.
  Future<bool> authenticateConnection(RelayConnectionKey key) {
    if (key.isAnonymous) {
      return Future.value(false);
    }
    if (_authenticatedConnections.contains(key)) {
      return Future.value(true);
    }
    final inFlight = _authenticating[key];
    if (inFlight != null) {
      return inFlight;
    }
    final attempt = _sendAuth(key);
    _authenticating[key] = attempt;
    return attempt.whenComplete(() => _authenticating.remove(key));
  }

  Future<bool> _sendAuth(RelayConnectionKey key) async {
    final connectivity = globalState.relays[key];
    final account = _accounts?.accounts[key.pubkey];
    if (connectivity == null || account == null) {
      return false;
    }
    if (!account.signer.canSign()) {
      Logger.log.w(() => "Cannot authenticate $key, signer cannot sign");
      return false;
    }

    // the relay may send its challenge before or with the refusal, so waiting
    // is safe here: something already asked us to authenticate
    final challenge = await _awaitChallenge(key);
    if (challenge == null) {
      return false;
    }

    final signedAuth = await account.signer.sign(
      AuthEvent(
        pubKey: account.pubkey,
        tags: [
          ["relay", key.url],
          ["challenge", challenge],
        ],
      ),
    );

    final accepted = Completer<bool>();
    _pendingAuthCallbacks[signedAuth.id] = (ok) {
      if (!accepted.isCompleted) {
        accepted.complete(ok);
      }
    };
    _pendingAuthTimers[signedAuth.id] = Timer(authCallbackTimeout, () {
      Logger.log.w(() => "AUTH callback timeout for ${signedAuth.id} on $key");
      _pendingAuthCallbacks.remove(signedAuth.id);
      _pendingAuthTimers.remove(signedAuth.id);
      if (!accepted.isCompleted) {
        accepted.complete(false);
      }
    });

    send(connectivity, ClientMsg(ClientMsgType.kAuth, event: signedAuth));
    Logger.log.d(() => "AUTH sent on $key");

    if (!await accepted.future) {
      return false;
    }
    _authenticatedConnections.add(key);
    return true;
  }

  /// Opens the bound connections a subscription will need, so the re-route on
  /// auth-required does not have to open a socket first.
  void authenticateIfNeeded(String relayUrl, List<Account> accounts) {
    for (final account in accounts.where((a) => a.signer.canSign())) {
      unawaited(openConnectionAs(relayUrl, account));
    }
  }

  void _handleIncomingEvent(
    NostrMessageRaw nostrMsgRaw,
    RelayConnectivity connectivity,
    int messageSize,
  ) {
    final requestId = nostrMsgRaw.requestId!;
    final event = nostrMsgRaw.nip01Event!;

    if (globalState.inFlightRequests[requestId] == null) {
      Logger.log.w(
        () =>
            "RECEIVED EVENT from ${connectivity.url} for id $requestId, not in globalState inFlightRequests. Likely data after EOSE on a query",
      );
      return;
    }

    connectivity.stats.incStatsByNewEvent(event, messageSize);

    RequestState? state = globalState.inFlightRequests[requestId];
    if (state != null) {
      RelayRequestState? request = state.requests[connectivity.key];
      if (request == null) {
        Logger.log.w(() => "No RelayRequestState found for id $requestId");
        return;
      }

      final eventWithSources = event.copyWith(
        sources: [...event.sources, connectivity.url],
      );

      if (state.networkController.isClosed) {
        // this might happen because relays even after we send a CLOSE subscription.id, they'll still send more events
        Logger.log.t(
          () =>
              "tried to add event to an already closed STREAM ${state.request.id} ${state.request.filters}",
        );
      } else {
        state.networkController.add(eventWithSources);
      }
    }
  }

  /// handles EOSE messages
  void _handleEOSE(
    List<dynamic> eventJson,
    RelayConnectivity relayConnectivity,
  ) {
    String id = eventJson[1];
    RequestState? state = globalState.inFlightRequests[id];
    if (state != null && state.request.closeOnEOSE) {
      Logger.log.t(
        () =>
            "⛁ received EOSE from ${relayConnectivity.url} for REQ id $id, remaining requests from :${state.requests.keys} kind:${state.requests.values.first.filters.first.kinds}",
      );
      RelayRequestState? request = state.requests[relayConnectivity.key];
      if (request != null) {
        request.receivedEOSE = true;
      }

      if (state.request.closeOnEOSE) {
        _sendCloseToRelay(relayConnectivity, state.id);
        _checkNetworkClose(state, relayConnectivity);
        _logActiveRequests();
      }
    }
    return;
  }

  /// handles CLOSED messages
  void _handleClosed(
    List<dynamic> eventJson,
    RelayConnectivity relayConnectivity,
  ) {
    String id = eventJson[1];
    String? message = eventJson.length > 2 ? eventJson[2] : null;

    // Check if this is an auth-required CLOSED message
    if (message != null && message.startsWith("auth-required")) {
      _handleClosedAuthRequired(id, relayConnectivity);
      return;
    }

    RequestState? state = globalState.inFlightRequests[id];
    if (state != null) {
      Logger.log.t(
        () =>
            "⛁ received CLOSE from ${relayConnectivity.url} for REQ id $id, remaining requests from :${state.requests.keys} kind:${state.requests.values.first.filters.first.kinds}",
      );
      RelayRequestState? request = state.requests[relayConnectivity.key];
      if (request != null) {
        request.receivedClosed = true;
      }

      _checkNetworkClose(state, relayConnectivity);
      _logActiveRequests();
    }
    return;
  }

  /// Whether [state] is still the request tracked under [reqId]. A request
  /// closed while an authentication or a connection was pending must not be
  /// sent afterwards: nothing tracks it anymore, so nothing would ever CLOSE it.
  bool _isStillInFlight(String reqId, RequestState state) =>
      identical(globalState.inFlightRequests[reqId], state);

  /// Handles CLOSED auth-required.
  ///
  /// A connection is bound to at most one identity, and that binding never
  /// changes. An anonymous connection therefore hands the request over to a
  /// bound one, while a bound connection answers the challenge itself.
  void _handleClosedAuthRequired(
    String reqId,
    RelayConnectivity relayConnectivity,
  ) {
    final state = globalState.inFlightRequests[reqId];
    if (state == null) {
      Logger.log.w(
        () => "Received CLOSED auth-required for unknown request $reqId",
      );
      return;
    }

    final key = relayConnectivity.key;
    final request = state.requests[key];
    if (request == null) {
      Logger.log.w(
        () => "Received CLOSED auth-required but no request state for $key",
      );
      return;
    }

    if (!key.isAnonymous) {
      if (_authenticatedConnections.contains(key)) {
        // the relay refused us while we were authenticated as the only identity
        // this connection may ever assume, so there is nothing left to try
        Logger.log.w(() => "REQ $reqId refused on authenticated $key");
        request.receivedClosed = true;
        _checkNetworkClose(state, relayConnectivity);
        return;
      }

      Logger.log.d(() => "Authenticating $key to satisfy REQ $reqId");
      state.pauseTimeout();
      authenticateConnection(key).then((authenticated) {
        if (!_isStillInFlight(reqId, state)) {
          return;
        }
        state.resumeTimeout();
        if (!authenticated) {
          request.receivedClosed = true;
          _checkNetworkClose(state, relayConnectivity);
          return;
        }
        send(
          relayConnectivity,
          ClientMsg(ClientMsgType.kReq, id: reqId, filters: request.filters),
        );
      });
      return;
    }

    final account = _accountForRequest(state);
    if (account == null) {
      Logger.log.w(() => "Cannot satisfy auth-required for REQ $reqId on $key");
      request.receivedClosed = true;
      _checkNetworkClose(state, relayConnectivity);
      return;
    }

    final target = RelayConnectionKey.authenticated(key.url, account.pubkey);

    // register the retry before closing the refused entry, otherwise the
    // request could complete while the bound connection is opening
    state.addRequest(target, request.filters);
    request.receivedClosed = true;

    Logger.log.d(
      () => "AUTH required for REQ $reqId on $key, retrying on $target",
    );

    state.pauseTimeout();
    openConnectionAs(
      key.url,
      account,
      connectionSource: relayConnectivity.relay.connectionSource,
    ).then((bound) {
      if (!_isStillInFlight(reqId, state)) {
        return;
      }
      state.resumeTimeout();
      final retry = state.requests[target];
      if (retry == null) {
        return;
      }
      if (bound == null) {
        retry.receivedClosed = true;
        _checkNetworkClose(state, relayConnectivity);
        return;
      }
      // sent without waiting for the AUTH: a relay that only challenges on
      // demand needs this request as the trigger, and the refusal that may
      // follow lands on the branch above
      send(
        bound,
        ClientMsg(ClientMsgType.kReq, id: reqId, filters: retry.filters),
      );
    });
  }

  /// Account a request authenticates as: the first one it asks for that can
  /// sign, otherwise the logged one.
  Account? _accountForRequest(RequestState state) {
    final requested = state.request.authenticateAs;
    if (requested != null && requested.isNotEmpty) {
      for (final account in requested) {
        if (account.signer.canSign()) {
          return account;
        }
      }
      return null;
    }
    final logged = _accounts?.getLoggedAccount();
    return logged != null && logged.signer.canSign() ? logged : null;
  }

  /// Handles OK auth-required for broadcasts by authenticating and re-sending the EVENT
  ///
  /// This is the last place that still authenticates in place, because
  /// BroadcastState is keyed by relay url and cannot yet track an event across
  /// two connections. It goes away with the broadcast lot.
  void _handleBroadcastAuthRequired(
    String eventId,
    RelayConnectivity relayConnectivity,
  ) {
    final challenge = _lastChallengePerConnection[relayConnectivity.key];
    if (challenge == null) {
      Logger.log.w(
        () =>
            "Received OK auth-required but no challenge stored for ${relayConnectivity.url}",
      );
      return;
    }

    final broadcastState = globalState.inFlightBroadcasts[eventId];
    if (broadcastState == null) {
      Logger.log.w(
        () => "Received OK auth-required for unknown broadcast $eventId",
      );
      return;
    }

    final eventToResend = broadcastState.event;
    if (eventToResend == null) {
      Logger.log.w(
        () =>
            "Received OK auth-required but no event stored for broadcast $eventId",
      );
      return;
    }

    // Prefer authenticating as the event author. Gift wraps and other
    // ephemeral-author events may not have a matching account, so fall back to
    // the currently logged-in account when needed.
    Account? account = _accounts?.accounts[eventToResend.pubKey];
    final loggedAccount = _accounts?.getLoggedAccount();
    if ((account == null || !account.signer.canSign()) &&
        loggedAccount != null &&
        loggedAccount.pubkey != account?.pubkey) {
      account = loggedAccount;
    }

    if (account == null || !account.signer.canSign()) {
      Logger.log.w(
        () =>
            "Received OK auth-required but no account can sign for ${relayConnectivity.url}",
      );
      return;
    }

    Logger.log.d(
      () =>
          "AUTH required for EVENT $eventId on ${relayConnectivity.url}, authenticating...",
    );

    // Create AUTH event
    final auth = AuthEvent(
      pubKey: account.pubkey,
      tags: [
        ["relay", relayConnectivity.url],
        ["challenge", challenge],
      ],
    );

    // Sign and send AUTH, then re-send EVENT on OK
    account.signer.sign(auth).then((signedAuth) {
      // Store callback to re-send EVENT after AUTH OK
      _pendingAuthCallbacks[signedAuth.id] = (accepted) {
        if (!accepted) {
          return;
        }
        Logger.log.d(
          () =>
              "AUTH OK received, re-sending EVENT $eventId to ${relayConnectivity.url}",
        );
        // Re-send the EVENT
        send(
          relayConnectivity,
          ClientMsg(ClientMsgType.kEvent, event: eventToResend),
        );
      };

      // Start timeout timer to clean up orphaned callbacks
      _pendingAuthTimers[signedAuth.id] = Timer(authCallbackTimeout, () {
        Logger.log.w(
          () =>
              "AUTH callback timeout for ${signedAuth.id} on ${relayConnectivity.url}",
        );
        _pendingAuthCallbacks.remove(signedAuth.id);
        _pendingAuthTimers.remove(signedAuth.id);
      });

      send(
        relayConnectivity,
        ClientMsg(ClientMsgType.kAuth, event: signedAuth),
      );
      Logger.log.d(
        () =>
            "AUTH sent for ${account!.pubkey.substring(0, 8)} to ${relayConnectivity.url}, waiting for OK...",
      );
    });
  }

  void _checkNetworkClose(
    RequestState state,
    RelayConnectivity relayConnectivity,
  ) {
    /// received everything, close the network controller
    if (state.didAllRequestsFinish) {
      state.networkController.close();
      updateRelayConnectivity();
      return;
    }

    /// check if relays for this request are still connected
    /// if not ignore it and wait for the ones still alive to finish
    final connectionsForThisRequest = state.requests.keys.toList();
    final myNotConnectedRelays = globalState.relays.keys
        .where((key) => connectionsForThisRequest.contains(key))
        .where((key) => !isConnectionOpen(key))
        .toList();

    final bool didAllRelaysFinish = state.requests.values.every(
      (element) =>
          element.receivedEOSE ||
          element.receivedClosed ||
          myNotConnectedRelays.contains(element.key),
    );

    if (didAllRelaysFinish) {
      state.networkController.close();
      updateRelayConnectivity();
    }
  }

  /// sends a close message on the anonymous connection to a relay
  void sendCloseToRelay(String url, String id) =>
      sendCloseToConnection(RelayConnectionKey.anonymous(url), id);

  /// sends a close message on the connection the subscription was sent on
  void sendCloseToConnection(RelayConnectionKey key, String id) {
    RelayConnectivity? connectivity = globalState.relays[key];
    if (connectivity != null) {
      _sendCloseToRelay(connectivity, id);
    }
  }

  void _sendCloseToRelay(RelayConnectivity relayConnectivity, String id) {
    try {
      send(relayConnectivity, ClientMsg(ClientMsgType.kClose, id: id));
      relayConnectivity.stats.activeRequests--;
    } catch (e) {
      Logger.log.e(() => e);
    }
  }

  void _logActiveRequests() {
    // Map<int?, int> kindsMap = {};
    Map<String?, int> namesMap = {};
    globalState.inFlightRequests.forEach((key, state) {
      // int? kind;
      // if (state.requests.isNotEmpty &&
      //     state.requests.values.first.filters.first.kinds != null &&
      //     state.requests.values.first.filters.first.kinds!.isNotEmpty) {
      //   kind = state.requests.values.first.filters.first.kinds!.first;
      // }
      // int? kindCount = kindsMap[kind];
      int? nameCount = namesMap[state.request.name];
      // kindCount ??= 0;
      // kindCount++;
      nameCount ??= 0;
      nameCount++;
      // kindsMap[kind] = kindCount;
      namesMap[state.request.name] = nameCount;
    });
    Logger.log.d(
      () =>
          "------------ IN FLIGHT REQUESTS: ${globalState.inFlightRequests.length} || $namesMap",
    );
  }

  /// Closes every connection towards [url] and forgets them
  Future<void> closeTransport(String url) async {
    await Future.wait(_connectionKeysForRelay(url).map(closeConnection));
  }

  /// Closes one connection and forgets it
  Future<void> closeConnection(RelayConnectionKey key) async {
    RelayConnectivity? connectivity = globalState.relays[key];
    if (connectivity != null && connectivity.relayTransport != null) {
      Logger.log.d(() => "Disconnecting $key...");
      globalState.relays.remove(key);
      _authenticatedConnections.remove(key);
      _lastChallengePerConnection.remove(key);
      return connectivity.close();
    }
  }

  /// Closes all transports
  Future<void> closeAllTransports() async {
    final keys = globalState.relays.keys.toList();
    try {
      await Future.wait(keys.map(closeConnection));
    } catch (e) {
      Logger.log.e(() => e);
    }
  }

  /// fetches relay info
  /// todo: refactor to use http injector and decouple data from fetching
  Future<RelayInfo?> getRelayInfo(String url) async {
    if (globalState.relays[RelayConnectionKey.anonymous(url)] != null) {
      return await RelayInfo.get(url);
    }
    return null;
  }

  /// does relay support given nip
  bool doesRelaySupportNip(String url, int nip) {
    RelayConnectivity? connectivity =
        globalState.relays[RelayConnectionKey.anonymous(url)];
    return connectivity != null &&
        connectivity.relayInfo != null &&
        connectivity.relayInfo!.supportsNip(nip);
  }

  /// return [RelayConnectivity] by url
  RelayConnectivity? getRelayConnectivity(String url) {
    return globalState.relays[RelayConnectionKey.anonymous(url)];
  }
}

dynamic decodeJson(String jsonString) {
  return json.decode(jsonString);
}
