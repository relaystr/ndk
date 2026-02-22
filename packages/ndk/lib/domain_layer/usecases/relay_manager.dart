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

  /// stores the last AUTH challenge per relay for late authentication
  final Map<String, String> _lastChallengePerRelay = {};

  /// stores pending AUTH callbacks: authEventId -> callback to execute on AUTH OK
  final Map<String, void Function()> _pendingAuthCallbacks = {};

  /// stores timers for pending AUTH callbacks to clean them up on timeout
  final Map<String, Timer> _pendingAuthTimers = {};

  /// timeout for AUTH callbacks (how long to wait for AUTH OK)
  final Duration authCallbackTimeout;

  /// nostr transport factory, to create new transports (usually websocket)
  final NostrTransportFactory nostrTransportFactory;

  /// factory for creating additional data for the engine
  final EngineAdditionalDataFactory? engineAdditionalDataFactory;

  /// Are reconnects allowed when a connection drops?
  bool allowReconnectRelays = true;

  /// stream controller for relay updates
  final _relayUpdatesStreamController =
      BehaviorSubject<Map<String, RelayConnectivity>>();

  /// stream of relay updates, used to notify connectivity changes, latest value is cached
  Stream<Map<String, RelayConnectivity>> get relayConnectivityChanges =>
      _relayUpdatesStreamController.stream;

  /// AUTH strategy: eager (on challenge) or lazy (on auth-required)
  final bool eagerAuth;

  /// Creates a new relay manager.
  RelayManager({
    required this.globalState,
    required this.nostrTransportFactory,
    Accounts? accounts,
    this.engineAdditionalDataFactory,
    List<String>? bootstrapRelays,
    allowReconnect = true,
    this.eagerAuth = false,
    this.authCallbackTimeout = RequestDefaults.DEFAULT_AUTH_CALLBACK_TIMEOUT,
  }) : _accounts = accounts {
    allowReconnectRelays = allowReconnect;
    _connectSeedRelays(urls: bootstrapRelays ?? DEFAULT_BOOTSTRAP_RELAYS);
  }

  void updateRelayConnectivity() {
    _relayUpdatesStreamController.add(globalState.relays);
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
    await Future.wait(urls
            .map(
              (url) => connectRelay(
                dirtyUrl: url,
                connectionSource: ConnectionSource.seed,
              ),
            )
            .toList())
        .whenComplete(() {
      if (!_seedRelaysCompleter.isCompleted) {
        _seedRelaysCompleter.complete();
      }
    });
  }

  /// Returns a list of fully connected relays, excluding connecting ones.
  /// DO NOT USE THIS FOR CHECKING A SINGLE RELAY, use [isRelayConnected] INSTEAD
  List<RelayConnectivity> get connectedRelays => globalState.relays.values
      .where((relay) => isRelayConnected(relay.url))
      .toList();

  /// checks if a relay is connected, avoid using this
  bool isRelayConnected(String url) {
    return globalState.relays[url]?.relayTransport?.isOpen() ?? false;
  }

  /// checks if a relay is connecting
  bool isRelayConnecting(String url) {
    final relay = globalState.relays[url]?.relay;
    return relay != null && relay.connecting;
  }

  /// Connects to a relay to the relay pool.
  /// Returns a tuple with the first element being a boolean indicating success \\
  /// and the second element being a string with the error message if any.
  Future<Tuple<bool, String>> connectRelay({
    required String dirtyUrl,
    required ConnectionSource connectionSource,
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

    if (isRelayConnected(url)) {
      Logger.log.t(() => "relay already connected: $url");
      updateRelayConnectivity();
      return Tuple(true, "");
    }

    if (isRelayConnecting(url)) {
      Logger.log.t(() => "relay is already connecting: $url");
      updateRelayConnectivity();
      return Tuple(true, "relay is still connecting");
    }
    RelayConnectivity? relayConnectivity = globalState.relays[url];

    try {
      if (relayConnectivity == null) {
        relayConnectivity = RelayConnectivity<T>(
          relay: Relay(
            url: url,
            connectionSource: connectionSource,
          ),
          specificEngineData: engineAdditionalDataFactory?.call(),
        );
        globalState.relays[url] = relayConnectivity;
      }

      relayConnectivity.relay.tryingToConnect();

      /// TO BE REMOVED, ONCE WE FIND A WAY OF AVOIDING PROBLEM WHEN CONNECTING TO THIS
      if (url.startsWith("wss://brb.io")) {
        relayConnectivity.relay.failedToConnect();
        updateRelayConnectivity();
        return Tuple(false, "bad relay");
      }

      Logger.log.i(() => "connecting to relay $dirtyUrl");

      relayConnectivity.relayTransport =
          nostrTransportFactory(url, onReconnect: () {
        reSubscribeInFlightSubscriptions(relayConnectivity!);
        updateRelayConnectivity();
      }, onDisconnect: (code, error, reason) {
        relayConnectivity!.stats.connectionErrors++;
        updateRelayConnectivity();
      });
      await relayConnectivity.relayTransport!.ready.timeout(
        Duration(seconds: connectTimeout),
        onTimeout: () {
          Logger.log.w(() => "timed out connecting to relay $url");
        },
      );

      _startListeningToSocket(relayConnectivity);

      Logger.log.i(() => "connected to relay: $url");
      relayConnectivity.relay.succeededToConnect();
      relayConnectivity.stats.connections++;
      getRelayInfo(url).then((info) {
        relayConnectivity!.relayInfo = info;
      });
      updateRelayConnectivity();
      return Tuple(true, "");
    } catch (e) {
      Logger.log.e(() => "!! could not connect to $url -> $e");
      relayConnectivity!.relayTransport == null;
    }
    relayConnectivity.relay.failedToConnect();
    relayConnectivity.stats.connectionErrors++;
    updateRelayConnectivity();
    return Tuple(false, "could not connect to $url");
  }

  /// Reconnects to a relay, if the relay is not connected or the connection is closed.
  Future<bool> reconnectRelay(
    String url, {
    required ConnectionSource connectionSource,
    bool force = false,
  }) async {
    RelayConnectivity? relayConnectivity = globalState.relays[url];
    if (relayConnectivity != null && relayConnectivity.relayTransport != null) {
      await relayConnectivity.relayTransport!.ready
          .timeout(Duration(seconds: DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT))
          .onError(
        (error, stackTrace) {
          Logger.log.e(() => "error connecting to relay $url: $error");
        },
      );
    }
    if (relayConnectivity == null ||
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

      if (!(await connectRelay(
        dirtyUrl: url,
        connectionSource: connectionSource,
      ))
          .first) {
        // could not connect
        return false;
      }
      relayConnectivity = globalState.relays[url];
      if (relayConnectivity == null ||
          !relayConnectivity.relayTransport!.isOpen()) {
        // web socket is not open
        return false;
      }
    }
    return true;
  }

  /// Reconnects all given relays
  Future<void> reconnectRelays(Iterable<String> urls) async {
    final startTime = DateTime.now();
    Logger.log.d(() => "connecting ${urls.length} relays in parallel");
    List<bool> connected = await Future.wait(urls.map((url) => reconnectRelay(
        url,
        connectionSource: ConnectionSource.explicit,
        force: true)));
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.d(() =>
        "CONNECTED ${connected.where((element) => element).length} , ${connected.where((element) => !element).length} FAILED, took ${duration.inMilliseconds} ms");
  }

  void reSubscribeInFlightSubscriptions(RelayConnectivity relayConnectivity) {
    globalState.inFlightRequests.forEach((key, state) {
      state.requests.values
          .where((req) => req.url == relayConnectivity.url)
          .forEach((req) {
        if (!state.request.closeOnEOSE) {
          List<dynamic> list = ["REQ", state.id];
          list.addAll(req.filters.map((filter) => filter.toMap()));

          relayConnectivity.stats.activeRequests++;
          _sendRaw(relayConnectivity, jsonEncode(list));
        }
      });
    });
  }

  void _sendRaw(RelayConnectivity relayConnectivity, dynamic data) {
    relayConnectivity.relayTransport!.send(data);
    Logger.log.d(() => "send message to ${relayConnectivity.url}: $data");
  }

  /// sends a [ClientMsg] to relay transport sink, throw an error if relay not connected
  void send(RelayConnectivity relayConnectivity, ClientMsg msg) async {
    if (relayConnectivity.relayTransport == null) {
      throw Exception("relay not connected");
    }

    /// wait until rdy
    await relayConnectivity.relayTransport!.ready;

    final String encodedMsg = jsonEncode(msg.toJson());
    _sendRaw(relayConnectivity, encodedMsg);
  }

  /// use this to register your request against a relay, \
  /// this is needed so the response from a relay can be tracked back
  void registerRelayRequest({
    required String reqId,
    required String relayUrl,
    required List<Filter> filters,
  }) {
    // new tracking
    if (globalState.inFlightRequests[reqId]!.requests[relayUrl] == null) {
      globalState.inFlightRequests[reqId]!.requests[relayUrl] =
          RelayRequestState(
        relayUrl,
        filters,
      );
    } else {
      // do not overwrite and add new filters
      globalState.inFlightRequests[reqId]!.requests[relayUrl]!.filters
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
      Logger.log.w(() =>
          "registerRelayBroadcast: no broadcast state for ${eventToPublish.id}");
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
      Logger.log.w(() =>
          "registerRelayBroadcast: relay broadcast already registered for ${eventToPublish.id} $relayUrl, skipping");
    }
  }

  /// use this to signal a failed broadcast
  void failBroadcast(String nostrEventId, String relay, String msg) {
    if (globalState.inFlightBroadcasts.containsKey(nostrEventId)) {
      globalState.inFlightBroadcasts[nostrEventId]?.networkController.add(
        RelayBroadcastResponse(
          relayUrl: relay,
          okReceived: false,
          broadcastSuccessful: false,
          msg: msg,
        ),
      );
    }
  }

  void _startListeningToSocket(RelayConnectivity relayConnectivity) {
    relayConnectivity.listen((message) {
      _handleIncomingMessage(
        message,
        relayConnectivity,
      );
    }, onError: (error) async {
      Logger.log.e(() => "onError ${relayConnectivity.url} on listen $error");
      relayConnectivity.stats.connectionErrors++;
      try {
        await relayConnectivity.close();
      } catch (e) {
        Logger.log.w(() => "Error closing relay ${relayConnectivity.url}: $e");
      }
      updateRelayConnectivity();
    }, onDone: () async {
      Logger.log.t(() =>
          "onDone ${relayConnectivity.url} on listen (close: ${relayConnectivity.relayTransport?.closeCode()} ${relayConnectivity.relayTransport?.closeReason()})");

      try {
        await relayConnectivity.close();
      } catch (e) {
        Logger.log.w(() => "Error closing relay ${relayConnectivity.url}: $e");
      }
      updateRelayConnectivity();
      // reconnect on close
      if (allowReconnectRelays &&
          globalState.relays[relayConnectivity.url] != null &&
          globalState.relays[relayConnectivity.url]!.relayTransport != null) {
        Logger.log.i(() => "closed ${relayConnectivity.url}. Reconnecting");
        reconnectRelay(relayConnectivity.url,
                connectionSource: relayConnectivity.relay.connectionSource)
            .then((connected) {
          updateRelayConnectivity();
          if (connected) {
            reSubscribeInFlightSubscriptions(relayConnectivity);
          }
        });
      }
    });
  }

  // tracking to process in order
  Completer<void>? _lastMessageCompleter;

  Future<void> _handleIncomingMessage(
      dynamic message, RelayConnectivity relayConnectivity) async {
    final previousMessage = _lastMessageCompleter;

    final myCompleter = Completer<void>();
    _lastMessageCompleter = myCompleter;

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

    myCompleter.complete();

    _processDecodedMessage(nostrMsg, relayConnectivity, message);
  }

  void _processDecodedMessage(NostrMessageRaw nostrMsg,
      RelayConnectivity relayConnectivity, dynamic message) {
    if (nostrMsg.type == NostrMessageRawType.unknown) {
      Logger.log.w(() =>
          "Received non NostrMessageRaw message from ${relayConnectivity.url}: $nostrMsg");
      return;
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
          final callback = _pendingAuthCallbacks.remove(eventId);
          callback?.call();
        } else {
          Logger.log.e(() => "AUTH failed for $eventId: $msg");
          _pendingAuthCallbacks.remove(eventId);
        }
        return;
      }

      //nip 20 used to notify clients if an EVENT was successful
      if (!success) {
        Logger.log.e(() => "NOT OK from ${relayConnectivity.url}: $eventJson");

        // Check if this is auth-required for a broadcast - don't mark as done, will retry
        if (msg != null && msg.startsWith("auth-required")) {
          _handleBroadcastAuthRequired(eventId, relayConnectivity);
          return; // Don't add to network controller yet, wait for retry result
        }
      }
      if (globalState.inFlightBroadcasts[eventId] != null &&
          !globalState
              .inFlightBroadcasts[eventId]!.networkController.isClosed) {
        globalState.inFlightBroadcasts[eventId]?.networkController.add(
          RelayBroadcastResponse(
            relayUrl: relayConnectivity.url,
            okReceived: true,
            broadcastSuccessful: success,
            msg: msg ?? '',
          ),
        );
      } else {
        Logger.log.w(() =>
            "Received OK for broadcast $eventId but the network controller is already closed");
      }
      return;
    }
    if (nostrMsg.type == NostrMessageRawType.notice) {
      final eventJson = nostrMsg.otherData;
      Logger.log
          .w(() => "NOTICE from ${relayConnectivity.url}: ${eventJson[1]}");
      _logActiveRequests();
    } else if (nostrMsg.type == NostrMessageRawType.event) {
      _handleIncomingEvent(
          nostrMsg, relayConnectivity, message.toString().codeUnits.length);
      // Logger.log.t(()=>"EVENT from ${relayConnectivity.url}: $eventJson");
    } else if (nostrMsg.type == NostrMessageRawType.eose) {
      final eventJson = nostrMsg.otherData;
      Logger.log.d(() => "EOSE from ${relayConnectivity.url}: ${eventJson[1]}");
      _handleEOSE(eventJson, relayConnectivity);
    } else if (nostrMsg.type == NostrMessageRawType.closed) {
      final eventJson = nostrMsg.otherData;
      Logger.log.w(() =>
          " CLOSED subscription url: ${relayConnectivity.url} id: ${eventJson[1]} msg: ${eventJson.length > 2 ? eventJson[2] : ''}");
      _handleClosed(eventJson, relayConnectivity);
    }
    if (nostrMsg.type == NostrMessageRawType.auth) {
      final eventJson = nostrMsg.otherData;
      // nip 42 used to send authentication challenges
      // NIP-42 allows multiple AUTH events for different pubkeys on the same connection
      final challenge = eventJson[1];
      Logger.log
          .d(() => "AUTH challenge from ${relayConnectivity.url}: $challenge");

      // Store challenge for late authentication (multiple accounts on same connection)
      _lastChallengePerRelay[relayConnectivity.url] = challenge;

      // If not eager auth, don't authenticate now - wait for auth-required
      if (!eagerAuth) {
        return;
      }

      if (_accounts == null) {
        Logger.log
            .w(() => "Received an AUTH challenge but no accounts configured");
        return;
      }

      // Collect accounts from active requests on this relay
      final accountsToAuth = <Account>{};
      for (final state in globalState.inFlightRequests.values) {
        final hasRequestOnThisRelay =
            state.requests.keys.contains(relayConnectivity.url);
        if (hasRequestOnThisRelay && state.request.authenticateAs != null) {
          accountsToAuth.addAll(state.request.authenticateAs!);
        }
      }

      // Fallback to logged account if no authenticateAs specified
      if (accountsToAuth.isEmpty && _accounts.getLoggedAccount() != null) {
        accountsToAuth.add(_accounts.getLoggedAccount()!);
      }

      if (accountsToAuth.isEmpty) {
        Logger.log.w(
            () => "Received an AUTH challenge but no accounts to authenticate");
        return;
      }

      _authenticateAccounts(relayConnectivity, challenge, accountsToAuth);
      return;
    }
    //
    // if (eventJson[0] == 'COUNT') {
    //   log("COUNT: ${eventJson[1]}");
    //   // nip 45 used to send requested event counts to clients
    //   return;
    // }
  }

  /// Sends AUTH events for the given accounts using the stored challenge
  void _authenticateAccounts(
    RelayConnectivity relayConnectivity,
    String challenge,
    Set<Account> accounts,
  ) {
    int authCount = 0;
    for (final account in accounts) {
      if (account.signer.canSign()) {
        final auth = AuthEvent(pubKey: account.pubkey, tags: [
          ["relay", relayConnectivity.url],
          ["challenge", challenge]
        ]);
        account.signer.sign(auth).then((signedAuth) {
          send(relayConnectivity,
              ClientMsg(ClientMsgType.kAuth, event: signedAuth));
          Logger.log.d(() =>
              "AUTH sent for ${account.pubkey.substring(0, 8)} to ${relayConnectivity.url}");
        });
        authCount++;
      }
    }

    if (authCount == 0) {
      Logger.log.w(() => "Received an AUTH challenge but no account can sign");
    }
  }

  /// Authenticates accounts on a relay if we have a stored challenge.
  /// Call this when creating a new subscription with authenticateAs.
  void authenticateIfNeeded(String relayUrl, List<Account> accounts) {
    final challenge = _lastChallengePerRelay[relayUrl];
    if (challenge == null) {
      Logger.log
          .t(() => "No stored challenge for $relayUrl, skipping late auth");
      return;
    }

    final relayConnectivity = globalState.relays[relayUrl];
    if (relayConnectivity == null) {
      Logger.log.w(() => "Relay $relayUrl not found for late auth");
      return;
    }

    Logger.log
        .d(() => "Late AUTH for ${accounts.length} accounts on $relayUrl");
    _authenticateAccounts(relayConnectivity, challenge, accounts.toSet());
  }

  void _handleIncomingEvent(NostrMessageRaw nostrMsgRaw,
      RelayConnectivity connectivity, int messageSize) {
    final requestId = nostrMsgRaw.requestId!;
    final event = nostrMsgRaw.nip01Event!;

    if (globalState.inFlightRequests[requestId] == null) {
      Logger.log.w(() =>
          "RECEIVED EVENT from ${connectivity.url} for id $requestId, not in globalState inFlightRequests. Likely data after EOSE on a query");
      return;
    }

    connectivity.stats.incStatsByNewEvent(event, messageSize);

    RequestState? state = globalState.inFlightRequests[requestId];
    if (state != null) {
      RelayRequestState? request = state.requests[connectivity.url];
      if (request == null) {
        Logger.log.w(() => "No RelayRequestState found for id $requestId");
        return;
      }

      final eventWithSources =
          event.copyWith(sources: [...event.sources, connectivity.url]);

      if (state.networkController.isClosed) {
        // this might happen because relays even after we send a CLOSE subscription.id, they'll still send more events
        Logger.log.t(() =>
            "tried to add event to an already closed STREAM ${state.request.id} ${state.request.filters}");
      } else {
        state.networkController.add(eventWithSources);
      }
    }
  }

  /// handles EOSE messages
  void _handleEOSE(
      List<dynamic> eventJson, RelayConnectivity relayConnectivity) {
    String id = eventJson[1];
    RequestState? state = globalState.inFlightRequests[id];
    if (state != null && state.request.closeOnEOSE) {
      Logger.log.t(() =>
          "⛁ received EOSE from ${relayConnectivity.url} for REQ id $id, remaining requests from :${state.requests.keys} kind:${state.requests.values.first.filters.first.kinds}");
      RelayRequestState? request = state.requests[relayConnectivity.url];
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
      List<dynamic> eventJson, RelayConnectivity relayConnectivity) {
    String id = eventJson[1];
    String? message = eventJson.length > 2 ? eventJson[2] : null;

    // Check if this is an auth-required CLOSED message
    if (message != null && message.startsWith("auth-required")) {
      _handleClosedAuthRequired(id, relayConnectivity);
      return;
    }

    RequestState? state = globalState.inFlightRequests[id];
    if (state != null) {
      Logger.log.t(() =>
          "⛁ received CLOSE from ${relayConnectivity.url} for REQ id $id, remaining requests from :${state.requests.keys} kind:${state.requests.values.first.filters.first.kinds}");
      RelayRequestState? request = state.requests[relayConnectivity.url];
      if (request != null) {
        request.receivedClosed = true;
      }

      _checkNetworkClose(state, relayConnectivity);
      _logActiveRequests();
    }
    return;
  }

  /// Handles CLOSED auth-required by authenticating and re-sending the REQ
  void _handleClosedAuthRequired(
      String reqId, RelayConnectivity relayConnectivity) {
    final state = globalState.inFlightRequests[reqId];
    if (state == null) {
      Logger.log
          .w(() => "Received CLOSED auth-required for unknown request $reqId");
      return;
    }

    final request = state.requests[relayConnectivity.url];
    if (request == null) {
      Logger.log.w(() =>
          "Received CLOSED auth-required but no request state for ${relayConnectivity.url}");
      return;
    }

    final challenge = _lastChallengePerRelay[relayConnectivity.url];
    if (challenge == null) {
      Logger.log.w(() =>
          "Received CLOSED auth-required but no challenge stored for ${relayConnectivity.url}");
      // Mark this relay as closed since we can't authenticate without a challenge
      request.receivedClosed = true;
      _checkNetworkClose(state, relayConnectivity);
      return;
    }

    // Collect accounts to authenticate
    final accountsToAuth = <Account>{};
    if (state.request.authenticateAs != null &&
        state.request.authenticateAs!.isNotEmpty) {
      accountsToAuth.addAll(state.request.authenticateAs!);
    } else if (_accounts?.getLoggedAccount() != null) {
      accountsToAuth.add(_accounts!.getLoggedAccount()!);
    }

    // Filter to accounts that can sign
    final signableAccounts =
        accountsToAuth.where((a) => a.signer.canSign()).toList();

    if (signableAccounts.isEmpty) {
      Logger.log.w(() =>
          "Received CLOSED auth-required but no account can sign for ${relayConnectivity.url}");
      // Mark this relay as closed and check if we can complete the request
      request.receivedClosed = true;
      _checkNetworkClose(state, relayConnectivity);
      return;
    }

    Logger.log.d(() =>
        "AUTH required for REQ $reqId on ${relayConnectivity.url}, authenticating ${signableAccounts.length} account(s)...");

    // Track how many AUTH OKs we need before re-sending REQ
    int pendingAuthCount = signableAccounts.length;

    for (final account in signableAccounts) {
      final auth = AuthEvent(pubKey: account.pubkey, tags: [
        ["relay", relayConnectivity.url],
        ["challenge", challenge]
      ]);

      account.signer.sign(auth).then((signedAuth) {
        // Store callback - only re-send REQ after last AUTH OK
        _pendingAuthCallbacks[signedAuth.id] = () {
          pendingAuthCount--;
          if (pendingAuthCount == 0) {
            Logger.log.d(() =>
                "All AUTH OK received, re-sending REQ $reqId to ${relayConnectivity.url}");
            List<dynamic> list = ["REQ", reqId];
            list.addAll(request.filters.map((filter) => filter.toMap()));
            _sendRaw(relayConnectivity, jsonEncode(list));
          }
        };

        // Start timeout timer to clean up orphaned callbacks
        _pendingAuthTimers[signedAuth.id] = Timer(authCallbackTimeout, () {
          Logger.log.w(() =>
              "AUTH callback timeout for ${signedAuth.id} on ${relayConnectivity.url}");
          _pendingAuthCallbacks.remove(signedAuth.id);
          _pendingAuthTimers.remove(signedAuth.id);
        });

        send(relayConnectivity,
            ClientMsg(ClientMsgType.kAuth, event: signedAuth));
        Logger.log.d(() =>
            "AUTH sent for ${account.pubkey.substring(0, 8)} to ${relayConnectivity.url}");
      });
    }
  }

  /// Handles OK auth-required for broadcasts by authenticating and re-sending the EVENT
  void _handleBroadcastAuthRequired(
      String eventId, RelayConnectivity relayConnectivity) {
    final challenge = _lastChallengePerRelay[relayConnectivity.url];
    if (challenge == null) {
      Logger.log.w(() =>
          "Received OK auth-required but no challenge stored for ${relayConnectivity.url}");
      return;
    }

    final broadcastState = globalState.inFlightBroadcasts[eventId];
    if (broadcastState == null) {
      Logger.log
          .w(() => "Received OK auth-required for unknown broadcast $eventId");
      return;
    }

    final eventToResend = broadcastState.event;
    if (eventToResend == null) {
      Logger.log.w(() =>
          "Received OK auth-required but no event stored for broadcast $eventId");
      return;
    }

    // Get account to authenticate (use the event's author)
    Account? account;
    final loggedAccount = _accounts?.getLoggedAccount();
    if (loggedAccount != null && loggedAccount.pubkey == eventToResend.pubKey) {
      account = loggedAccount;
    } else {
      // Try to find an account that matches the event author
      account = _accounts?.accounts[eventToResend.pubKey];
    }

    if (account == null || !account.signer.canSign()) {
      Logger.log.w(() =>
          "Received OK auth-required but no account can sign for ${relayConnectivity.url}");
      return;
    }

    Logger.log.d(() =>
        "AUTH required for EVENT $eventId on ${relayConnectivity.url}, authenticating...");

    // Create AUTH event
    final auth = AuthEvent(pubKey: account.pubkey, tags: [
      ["relay", relayConnectivity.url],
      ["challenge", challenge]
    ]);

    // Sign and send AUTH, then re-send EVENT on OK
    account.signer.sign(auth).then((signedAuth) {
      // Store callback to re-send EVENT after AUTH OK
      _pendingAuthCallbacks[signedAuth.id] = () {
        Logger.log.d(() =>
            "AUTH OK received, re-sending EVENT $eventId to ${relayConnectivity.url}");
        // Re-send the EVENT
        send(relayConnectivity,
            ClientMsg(ClientMsgType.kEvent, event: eventToResend));
      };

      // Start timeout timer to clean up orphaned callbacks
      _pendingAuthTimers[signedAuth.id] = Timer(authCallbackTimeout, () {
        Logger.log.w(() =>
            "AUTH callback timeout for ${signedAuth.id} on ${relayConnectivity.url}");
        _pendingAuthCallbacks.remove(signedAuth.id);
        _pendingAuthTimers.remove(signedAuth.id);
      });

      send(
          relayConnectivity, ClientMsg(ClientMsgType.kAuth, event: signedAuth));
      Logger.log.d(() =>
          "AUTH sent for ${account!.pubkey.substring(0, 8)} to ${relayConnectivity.url}, waiting for OK...");
    });
  }

  void _checkNetworkClose(
      RequestState state, RelayConnectivity relayConnectivity) {
    /// recived everything, close the network controller
    if (state.didAllRequestsFinish) {
      state.networkController.close();
      updateRelayConnectivity();
      return;
    }

    /// check if relays for this request are still connected
    /// if not ignore it and wait for the ones still alive to finish
    final listOfRelaysForThisRequest = state.requests.keys.toList();
    final myNotConnectedRelays = globalState.relays.keys
        .where((url) => listOfRelaysForThisRequest.contains(url))
        .where((url) => !isRelayConnected(url))
        .toList();

    final bool didAllRelaysFinish = state.requests.values.every(
      (element) =>
          element.receivedEOSE ||
          element.receivedClosed ||
          myNotConnectedRelays.contains(element.url),
    );

    if (didAllRelaysFinish) {
      state.networkController.close();
      updateRelayConnectivity();
    }
  }

  /// sends a close message to a relay
  void sendCloseToRelay(String url, String id) {
    RelayConnectivity? connectivity = globalState.relays[url];
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
    Logger.log.d(() =>
        "------------ IN FLIGHT REQUESTS: ${globalState.inFlightRequests.length} || $namesMap");
  }

  /// Closes this url transport and removes
  Future<void> closeTransport(String url) async {
    RelayConnectivity? connectivity = globalState.relays[url];
    if (connectivity != null && connectivity.relayTransport != null) {
      Logger.log.d(() => "Disconnecting $url...");
      globalState.relays.remove(url);
      _lastChallengePerRelay.remove(url);
      return connectivity.close();
    }
  }

  /// Closes all transports
  Future<void> closeAllTransports() async {
    Iterable<String> keys = globalState.relays.keys.toList();
    try {
      await Future.wait(keys.map((url) => closeTransport(url)));
    } catch (e) {
      Logger.log.e(() => e);
    }
  }

  /// fetches relay info
  /// todo: refactor to use http injector and decouple data from fetching
  Future<RelayInfo?> getRelayInfo(String url) async {
    if (globalState.relays[url] != null) {
      return await RelayInfo.get(url);
    }
    return null;
  }

  /// does relay support given nip
  bool doesRelaySupportNip(String url, int nip) {
    RelayConnectivity? connectivity = globalState.relays[cleanRelayUrl(url)];
    return connectivity != null &&
        connectivity.relayInfo != null &&
        connectivity.relayInfo!.supportsNip(nip);
  }

  /// return [RelayConnectivity] by url
  RelayConnectivity? getRelayConnectivity(String url) {
    return globalState.relays[url];
  }
}

dynamic decodeJson(String jsonString) {
  return json.decode(jsonString);
}
