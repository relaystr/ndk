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
import '../repositories/nostr_transport.dart';

/// wip relay manger that only does connection and relay lifecycle management
class RelayManagerLight<T> {
  final Completer<void> _seedRelaysCompleter = Completer<void>();

  /// completes when all seed relays are connected
  Future<void> get seedRelaysConnected => _seedRelaysCompleter.future;

  /// global state obj
  GlobalState globalState;

  /// nostr transport factory, to create new transports (usually websocket)
  final NostrTransportFactory nostrTransportFactory;

  /// Creates a new relay manager.
  RelayManagerLight({
    required this.globalState,
    required this.nostrTransportFactory,
    List<String>? seedRelays,
  }) {
    _connectSeedRelays(urls: seedRelays ?? DEFAULT_BOOTSTRAP_RELAYS);
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
                connectionSource: ConnectionSource.SEED,
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
  List<RelayConnectivity> get connectedRelays => globalState.relays.values
      .where((relay) =>
          relay.relayTransport != null && relay.relayTransport!.isOpen())
      .toList();

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
    try {
      if (globalState.relays[url] == null) {
        globalState.relays[url] = RelayConnectivity<T>(
            relay: Relay(
          url: url,
          connectionSource: connectionSource,
        ));
      }
      globalState.relays[url]!.relay.tryingToConnect();

      globalState.relays[url]!.relayTransport = nostrTransportFactory(url);
      await globalState.relays[url]!.relayTransport!.ready
          .timeout(Duration(seconds: connectTimeout), onTimeout: () {
        print("timed out connecting to relay $url");
        return Tuple(false, "timed out connecting to relay $url");
      });

      _startListeningToSocket(globalState.relays[url]!);

      developer.log("connected to relay: $url");
      globalState.relays[url]!.relay.succeededToConnect();
      globalState.relays[url]!.stats.connections++;
      getRelayInfo(url);
      return Tuple(true, "");
    } catch (e) {
      print("!! could not connect to $url -> $e");
      globalState.relays[url]!.relayTransport == null;
    }
    globalState.relays[url]!.relay.failedToConnect();
    globalState.relays[url]!.stats.connectionErrors++;
    return Tuple(false, "could not connect to $url");
  }

  /// Reconnects to a relay, if the relay is not connected or the connection is closed.
  Future<bool> reconnectRelay(RelayConnectivity relayConnectivity,
      {bool force = false}) async {
    if (relayConnectivity.relayTransport != null) {
      await relayConnectivity.relayTransport!.ready
          .timeout(Duration(seconds: DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT))
          .onError((error, stackTrace) {
        print("error connecting to relay ${relayConnectivity.url}: $error");
        return []; // Return an empty list in case of error
      });
    }
    if (!relayConnectivity.relayTransport!.isOpen()) {
      if (!force &&
          !relayConnectivity.relay.wasLastConnectTryLongerThanSeconds(
              FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS)) {
        // don't try too often
        return false;
      }

      if (!(await connectRelay(
        dirtyUrl: relayConnectivity.url,
        connectionSource: relayConnectivity.relay.connectionSource,
      ))
          .first) {
        // could not connect
        return false;
      }
      if (!relayConnectivity.relayTransport!.isOpen()) {
        // web socket is not open
        return false;
      }
    }
    return true;
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
          "registerRelayBroadcast: relay broadcast already registered for ${eventToPublish.id} ${relayUrl}, skipping");
    }
  }

  void _startListeningToSocket(RelayConnectivity relayConnectivity) {
    relayConnectivity.relayTransport!.listen((message) {
      _handleIncomingMessage(
        message,
        relayConnectivity,
      );
    }, onError: (error) async {
      /// todo: handle this better, should clean subscription stuff
      relayConnectivity.stats.connectionErrors++;
      print("onError ${relayConnectivity.url} on listen $error");
      throw Exception("Error in socket");
    }, onDone: () {
      /// reconnect on close
      print(
          "onDone ${relayConnectivity.url} on listen (close: ${relayConnectivity.relayTransport!.closeCode()} ${relayConnectivity.relayTransport!.closeReason()}), trying to reconnect");
      if (relayConnectivity.relayTransport!.isOpen()) {
        print("closing ${relayConnectivity.url} webSocket");
        relayConnectivity.relayTransport!.close();
        print("closed ${relayConnectivity.url}. Reconnecting");
      }
      reconnectRelay(relayConnectivity).then((connected) {
        if (connected) {
          _reSubscribeInFlightSubscriptions(relayConnectivity);
        }
      });
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
    } else if (eventJson[0] == 'EVENT') {
      _handleIncomingEvent(eventJson, relayConnectivity.url);
      Logger.log.d("EVENT from ${relayConnectivity.url}: $eventJson");
    } else if (eventJson[0] == 'EOSE') {
      Logger.log.d("EOSE from ${relayConnectivity.url}: ${eventJson[1]}");
      _handleEOSE(eventJson, relayConnectivity);
    } else if (eventJson[0] == 'CLOSED') {
      Logger.log.w(
          " CLOSED subscription url: ${relayConnectivity.url} id: ${eventJson[1]} msg: ${eventJson.length > 2 ? eventJson[2] : ''}");
      globalState.inFlightRequests.remove(eventJson[1]);
    }
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
        Logger.log.w("No RelayRequestState found for id ${id}");
        return;
      }
      event.sources.add(url);

      if (state.networkController.isClosed) {
        Logger.log.e(
            "TRIED to add event to an already closed STREAM ${state.request.id} ${state.request.filters}");
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
        if (state.requests.isEmpty || state.didAllRequestsReceivedEOSE) {
          _removeInFlightRequestById(id);
        }
      }
    }
    return;
  }

  /// sends a close message to a relay
  void _sendCloseToRelay(RelayConnectivity relayConnectivity, String id) {
    try {
      send(relayConnectivity, ClientMsg(ClientMsgType.CLOSE, id: id));
    } catch (e) {
      print(e);
    }
  }

  /// removes a request from the inFlightRequests \
  /// and closes the network controller
  void _removeInFlightRequestById(String id) {
    RequestState? state = globalState.inFlightRequests[id];
    if (state != null) {
      try {
        state.networkController.close();
      } catch (e) {
        Logger.log.e(e);
      }
      globalState.inFlightRequests.remove(id);
    }
  }

  /// fetches relay info
  /// todo: refactor to use http injector and decouple data from fetching
  Future<RelayInfo?> getRelayInfo(String url) async {
    if (globalState.relays[url] != null) {
      globalState.relays[url]!.relayInfo ??= await RelayInfo.get(url);
      return globalState.relays[url]!.relayInfo;
    }
    return null;
  }
}
