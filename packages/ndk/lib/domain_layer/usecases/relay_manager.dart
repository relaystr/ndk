import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../../config/bootstrap_relays.dart';
import '../../config/relay_defaults.dart';
import '../../shared/helpers/relay_helper.dart';
import '../../shared/logger/logger.dart';
import '../../shared/nips/nip01/client_msg.dart';
import '../entities/broadcast_state.dart';
import '../entities/connection_source.dart';
import '../entities/filter.dart';
import '../entities/global_state.dart';
import '../entities/nip_01_event.dart';
import '../entities/relay.dart';
import '../entities/relay_connectivity.dart';
import '../entities/relay_info.dart';
import '../entities/request_state.dart';
import '../entities/tuple.dart';
import '../repositories/event_signer.dart';
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

  /// nostr transport factory, to create new transports (usually websocket)
  final NostrTransportFactory nostrTransportFactory;

  /// factory for creating additional data for the engine
  final EngineAdditionalDataFactory? engineAdditionalDataFactory;

  /// Are reconnects allowed when a connection drops?
  bool allowReconnectRelays = true;

  /// Creates a new relay manager.
  RelayManager(
      {required this.globalState,
      required this.nostrTransportFactory,
      Accounts? accounts,
      this.engineAdditionalDataFactory,
      List<String>? bootstrapRelays,
      allowReconnect = true}) : _accounts = accounts {
    allowReconnectRelays = allowReconnect;
    _connectSeedRelays(urls: bootstrapRelays ?? DEFAULT_BOOTSTRAP_RELAYS);
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
      return Tuple(false, "unclean url");
    }
    if (globalState.blockedRelays.contains(url)) {
      return Tuple(false, "relay is blocked");
    }

    if (isRelayConnected(url)) {
      Logger.log.t("relay already connected: $url");
      return Tuple(true, "");
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
        return Tuple(false, "bad relay");
      }

      Logger.log.i("connecting to relay $dirtyUrl");

      relayConnectivity.relayTransport = nostrTransportFactory(url, () {
        _reSubscribeInFlightSubscriptions(relayConnectivity!);
      });
      await relayConnectivity.relayTransport!.ready.timeout(
        Duration(seconds: connectTimeout),
        onTimeout: () {
          Logger.log.w("timed out connecting to relay $url");
        },
      );

      _startListeningToSocket(relayConnectivity);

      developer.log("connected to relay: $url");
      relayConnectivity.relay.succeededToConnect();
      relayConnectivity.stats.connections++;
      getRelayInfo(url).then((info) {
        relayConnectivity!.relayInfo = info;
      });
      return Tuple(true, "");
    } catch (e) {
      Logger.log.e("!! could not connect to $url -> $e");
      relayConnectivity!.relayTransport == null;
    }
    relayConnectivity.relay.failedToConnect();
    relayConnectivity.stats.connectionErrors++;
    return Tuple(false, "could not connect to $url");
  }

  /// Reconnects to a relay, if the relay is not connected or the connection is closed.
  Future<bool> reconnectRelay(String url,
      {required ConnectionSource connectionSource, bool force = false}) async {
    RelayConnectivity? relayConnectivity = globalState.relays[url];
    if (relayConnectivity != null && relayConnectivity.relayTransport != null) {
      await relayConnectivity.relayTransport!.ready
          .timeout(Duration(seconds: DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT))
          .onError(
        (error, stackTrace) {
          Logger.log.e("error connecting to relay $url: $error");
        },
      );
    }
    if (relayConnectivity == null ||
        !relayConnectivity.relayTransport!.isOpen()) {
      if (!force &&
          (relayConnectivity == null ||
              !relayConnectivity.relay.wasLastConnectTryLongerThanSeconds(
                  FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS))) {
        // don't try too often
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
    Logger.log.d("connecting ${urls.length} relays in parallel");
    List<bool> connected = await Future.wait(urls.map((url) => reconnectRelay(
        url,
        connectionSource: ConnectionSource.explicit,
        force: true)));
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.d(
        "CONNECTED ${connected.where((element) => element).length} , ${connected.where((element) => !element).length} FAILED, took ${duration.inMilliseconds} ms");
  }

  void _reSubscribeInFlightSubscriptions(RelayConnectivity relayConnectivity) {
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
    Logger.log.d("send message to ${relayConnectivity.url}: $data");
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
    // new tracking
    if (globalState
            .inFlightBroadcasts[eventToPublish.id]!.broadcasts[relayUrl] ==
        null) {
      globalState.inFlightBroadcasts[eventToPublish.id]!.broadcasts[relayUrl] =
          RelayBroadcastResponse(
        relayUrl: relayUrl,
      );
    } else {
      // do not overwrite
      Logger.log.w(
          "registerRelayBroadcast: relay broadcast already registered for ${eventToPublish.id} $relayUrl, skipping");
    }
  }

  void _startListeningToSocket(RelayConnectivity relayConnectivity) {
    relayConnectivity.listen((message) {
      _handleIncomingMessage(
        message,
        relayConnectivity,
      );
    }, onError: (error) async {
      await relayConnectivity.close();
      relayConnectivity.stats.connectionErrors++;
      Logger.log.e("onError ${relayConnectivity.url} on listen $error");
      throw Exception("Error in socket");
    }, onDone: () async {
      Logger.log.t(
          "onDone ${relayConnectivity.url} on listen (close: ${relayConnectivity.relayTransport!.closeCode()} ${relayConnectivity.relayTransport!.closeReason()})");
      await relayConnectivity.close();
      // reconnect on close
      if (allowReconnectRelays &&
          globalState.relays[relayConnectivity.url] != null &&
          globalState.relays[relayConnectivity.url]!.relayTransport != null) {
        Logger.log.i("closed ${relayConnectivity.url}. Reconnecting");
        reconnectRelay(relayConnectivity.url,
                connectionSource: relayConnectivity.relay.connectionSource)
            .then((connected) {
          if (connected) {
            _reSubscribeInFlightSubscriptions(relayConnectivity);
          }
        });
      }
    });
  }

  void _handleIncomingMessage(
      dynamic message, RelayConnectivity relayConnectivity) {
    List<dynamic> eventJson = json.decode(message);

    if (eventJson[0] == 'OK') {
      //nip 20 used to notify clients if an EVENT was successful
      if (eventJson.length >= 2 && eventJson[2] == false) {
        Logger.log.e("NOT OK from ${relayConnectivity.url}: $eventJson");
      }
      globalState.inFlightBroadcasts[eventJson[1]]?.networkController.add(
        RelayBroadcastResponse(
          relayUrl: relayConnectivity.url,
          okReceived: true,
          broadcastSuccessful: eventJson[2],
          msg: eventJson[3] ?? '',
        ),
      );

      return;
    }
    if (eventJson[0] == 'NOTICE') {
      Logger.log.w("NOTICE from ${relayConnectivity.url}: ${eventJson[1]}");
      _logActiveRequests();
    } else if (eventJson[0] == 'EVENT') {
      _handleIncomingEvent(eventJson, relayConnectivity.url);
      Logger.log.t("EVENT from ${relayConnectivity.url}: $eventJson");
    } else if (eventJson[0] == 'EOSE') {
      Logger.log.d("EOSE from ${relayConnectivity.url}: ${eventJson[1]}");
      _handleEOSE(eventJson, relayConnectivity);
    } else if (eventJson[0] == 'CLOSED') {
      Logger.log.w(
          " CLOSED subscription url: ${relayConnectivity.url} id: ${eventJson[1]} msg: ${eventJson.length > 2 ? eventJson[2] : ''}");
      globalState.inFlightRequests.remove(eventJson[1]);
    }
    if (eventJson[0] == ClientMsgType.kAuth) {
      // nip 42 used to send authentication challenges
      final challenge = eventJson[1];
      Logger.log.d("AUTH: $challenge");
      if (_accounts!=null && _accounts.canSign) {
        final auth = AuthEvent(pubKey: _accounts.getLoggedAccount()!.pubkey, tags: [
          ["relay", relayConnectivity.url],
          ["challenge", challenge]
        ]);
        _accounts.sign(auth).then((e) {
          send(relayConnectivity, ClientMsg(ClientMsgType.kAuth, event: auth));
        });
      } else {
        Logger.log
            .w("Received an AUTH challenge but don't have a signer configured");
      }
      return;
    }
    //
    // if (eventJson[0] == 'COUNT') {
    //   log("COUNT: ${eventJson[1]}");
    //   // nip 45 used to send requested event counts to clients
    //   return;
    // }
  }

  void _handleIncomingEvent(List<dynamic> eventJson, String url) {
    var id = eventJson[1];
    if (globalState.inFlightRequests[id] == null) {
      Logger.log.w(
          "RECEIVED EVENT from $url for id $id, not in globalState inFlightRequests");
      // send(url, jsonEncode(["CLOSE", id]));
      return;
    }

    Nip01Event event = Nip01Event.fromJson(eventJson[2]);

    RequestState? state = globalState.inFlightRequests[id];
    if (state != null) {
      RelayRequestState? request = state.requests[url];
      if (request == null) {
        Logger.log.w("No RelayRequestState found for id $id");
        return;
      }
      event.sources.add(url);

      if (state.networkController.isClosed) {
        // this might happen because relays even after we send a CLOSE subscription.id, they'll still send more events
        Logger.log.t(
            "tried to add event to an already closed STREAM ${state.request.id} ${state.request.filters}");
      } else {
        state.networkController.add(event);
      }
    }
  }

  /// handles EOSE messages
  void _handleEOSE(
      List<dynamic> eventJson, RelayConnectivity relayConnectivity) {
    String id = eventJson[1];
    RequestState? state = globalState.inFlightRequests[id];
    if (state != null && state.request.closeOnEOSE) {
      Logger.log.t(
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

  void _checkNetworkClose(
      RequestState state, RelayConnectivity relayConnectivity) {
    /// recived everything, close the network controller
    if (state.didAllRequestsReceivedEOSE) {
      state.networkController.close();
      return;
    }

    /// check if relays for this request are still connected
    /// if not ignore it and wait for the ones still alive to receive EOSE
    final listOfRelaysForThisRequest = state.requests.keys.toList();
    final myNotConnectedRelays = globalState.relays.keys
        .where((url) => listOfRelaysForThisRequest.contains(url))
        .where((url) => !isRelayConnected(url))
        .toList();

    final bool didAllRelaysFinish = state.requests.values.every(
      (element) =>
          element.receivedEOSE || myNotConnectedRelays.contains(element.url),
    );

    if (didAllRelaysFinish) {
      state.networkController.close();
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
      Logger.log.e(e);
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
        "------------ IN FLIGHT REQUESTS: ${globalState.inFlightRequests.length} || $namesMap");
  }

  /// Closes this url transport and removes
  Future<void> closeTransport(url) async {
    RelayConnectivity? connectivity = globalState.relays[url];
    if (connectivity != null && connectivity.relayTransport != null) {
      Logger.log.d("Disconnecting $url...");
      globalState.relays.remove(url);
      return connectivity.close();
    }
  }

  /// Closes all transports
  Future<void> closeAllTransports() async {
    Iterable<String> keys = globalState.relays.keys.toList();
    try {
      await Future.wait(keys.map((url) => closeTransport(url)));
    } catch (e) {
      Logger.log.e(e);
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
