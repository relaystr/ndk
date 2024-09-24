// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:developer' as developer;

import '../../config/bootstrap_relays.dart';
import '../../event_filter.dart';
import '../../shared/helpers/relay_helper.dart';
import '../../shared/logger/logger.dart';
import '../entities/global_state.dart';
import '../entities/nip_01_event.dart';
import '../entities/pubkey_mapping.dart';
import '../entities/read_write_marker.dart';
import '../entities/relay.dart';
import '../entities/relay_info.dart';
import '../entities/request_state.dart';
import '../repositories/event_signer.dart';
import '../repositories/event_verifier.dart';
import '../repositories/nostr_transport.dart';

class RelayManager {
  static const int DEFAULT_STREAM_IDLE_TIMEOUT = 5;
  static const int DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT = 3;
  static const int DEFAULT_BEST_RELAYS_MIN_COUNT = 2;
  static const int FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS = 60;
  static const int WEB_SOCKET_PING_INTERVAL_SECONDS = 3;

  late List<String> bootstrapRelays;
  late EventVerifier eventVerifier;
  late GlobalState globalState;

  final NostrTransportFactory nostrTransportFactory;

  /// Global relay registry by url
  Map<String, Relay> relays = {};

  /// Global transport registry by url
  Map<String, NostrTransport> transports = {};

  List<String> blockedRelays = [];

  int get blockedRelaysCount => blockedRelays.length;

  List<EventFilter> eventFilters = [];

  bool allowReconnectRelays = true;

  final Completer<void> _seedRelaysCompleter = Completer<void>();

  get seedRelaysConnected => _seedRelaysCompleter.future;

  RelayManager({
    required this.nostrTransportFactory,
    List<String>? bootstrapRelays,
    GlobalState? globalState,
  }) {
    this.bootstrapRelays = bootstrapRelays ?? DEFAULT_BOOTSTRAP_RELAYS;
    this.globalState = globalState ?? GlobalState();
  }

  // ====================================================================================================================

  /// This will initialize the manager with bootstrap relays.
  /// If you don't give any, will use some predefined
  Future<void> connect(
      {Iterable<String> urls = DEFAULT_BOOTSTRAP_RELAYS}) async {
    bootstrapRelays = [];
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
            urls.map((url) => reconnectRelay(url, force: true)).toList())
        .whenComplete(() {
      if (!_seedRelaysCompleter.isCompleted) {
        _seedRelaysCompleter.complete();
      }
    });
  }

  void send(String url, dynamic data) {
    transports[url]!.send(data);
    Logger.log.d("send message to $url: $data");
  }

  Future<void> closeTransport(url) async {
    return transports[url]?.close().timeout(const Duration(seconds: 3),
        onTimeout: () {
      print("timeout while trying to close socket $url");
    });
  }

  Future<void> closeAllTransports() async {
    try {
      await Future.wait(transports.keys.map((url) => closeTransport(url)));
    } catch (e) {
      print(e);
    }
  }

  bool isWebSocketOpen(String url) {
    NostrTransport? transport = transports[cleanRelayUrl(url)];
    return transport != null && transport.isOpen();
  }

  bool isRelayConnecting(String url) {
    Relay? relay = relays[url];
    return relay != null && relay.connecting;
  }

  /// Connect a new relay
  Future<bool> connectRelay(String dirtyUrl,
      {int connectTimeout = DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT}) async {
    String? url = cleanRelayUrl(dirtyUrl);
    if (url == null) {
      return false;
    }
    if (blockedRelays.contains(url)) {
      return false;
    }
    try {
      if (relays[url] == null) {
        relays[url] = Relay(url);
      }
      relays[url]!.tryingToConnect();
      if (url.startsWith("wss://brb.io")) {
        relays[url]!.failedToConnect();
        relays[url]!.stats.connectionErrors++;
        return false;
      }
      // var connectionOptions = SocketConnectionOptions(
      //   timeoutConnectionMs: connectTimeout*1000,
      //   skipPingMessages: true,
      //   pingRestrictionForce: true,
      //   reconnectionDelay: const Duration(seconds:5),
      // );
      // webSockets[url] = IWebSocketHandler<String, String>.createClient(
      //   url,
      //   SocketSimpleTextProcessor(),
      //   connectionOptions: connectionOptions
      // );

      transports[url] = nostrTransportFactory(url);
      await transports[url]!.ready;

      startListeningToSocket(url);

      developer.log("connected to relay: $url");
      relays[url]!.succeededToConnect();
      relays[url]!.stats.connections++;
      getRelayInfo(url);
      return true;
    } catch (e) {
      print("!! could not connect to $url -> $e");
      transports.remove(url);
    }
    relays[url]!.failedToConnect();
    relays[url]!.stats.connectionErrors++;
    return false;
  }

  void startListeningToSocket(String url) {
    transports[url]!.listen((message) {
      _handleIncommingMessage(message, url);
    }, onError: (error) async {
      /// todo: handle this better, should clean subscription stuff
      relays[url]!.stats.connectionErrors++;
      print("onError $url on listen $error");
      throw Exception("Error in socket");
    }, onDone: () {
      if (allowReconnectRelays) {
        print(
            "onDone $url on listen (close: ${transports[url]!.closeCode()} ${transports[url]!.closeReason()}), trying to reconnect");
        if (isWebSocketOpen(url)) {
          print("closing $url webSocket");
          transports[url]!.close();
          print("closed $url. Reconnecting");
        }
        reconnectRelay(url).then((connected) {
          if (connected) {
            _reSubscribeInFlightSubscriptions(url);
          }
        });
      }
    });
  }

  List<Relay> getConnectedRelays(Iterable<String> urls) {
    return urls
        .where((url) => isRelayConnected(url))
        .map((url) => relays[url]!)
        .toList();
  }

  Future<void> broadcastEvent(
      Nip01Event event, Iterable<String> relays, EventSigner signer) async {
    await signer.sign(event);
    await Future.wait(relays.map((url) => broadcastSignedEvent(event, url)));
  }

  Future<void> broadcastSignedEvent(Nip01Event event, String url) async {
    if (isWebSocketOpen(url) && (!blockedRelays.contains(url))) {
      try {
        Logger.log.i(
            "🛈 BROADCASTING to $url : kind: ${event.kind} author: ${event.pubKey}");
        var webSocket = transports[url];
        if (webSocket != null) {
          send(url, jsonEncode(["EVENT", event.toJson()]));
        }
      } catch (e) {
        print("ERROR BROADCASTING $url -> $e");
      }
    }
  }

  void removeInFlightRequest(RequestState state) {
    return removeInFlightRequestById(state.id);
  }

  void closeSubscription(String subscriptionId) {
    RequestState? state = globalState.inFlightRequests[subscriptionId];
    if (state != null) {
      for (var url in state.requests.keys) {
        sendCloseToRelay(url, state.id);
      }
      removeInFlightRequestById(subscriptionId);
    }
  }

  void removeInFlightRequestById(String id) {
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

  // =====================================================================================

  _handleIncommingMessage(dynamic message, String url) {
    List<dynamic> eventJson = json.decode(message);

    if (eventJson[0] == 'OK') {
      //nip 20 used to notify clients if an EVENT was successful
      if (eventJson.length >= 2 && eventJson[2] == false) {
        Logger.log.e("NOT OK: $eventJson");
      }
      return;
    }

    if (eventJson[0] == 'NOTICE') {
      Logger.log.w("NOTICE from $url: ${eventJson[1]}");
      logActiveRequests();
    } else if (eventJson[0] == 'EVENT') {
      handleIncomingEvent(eventJson, url, message);
    } else if (eventJson[0] == 'EOSE') {
      handleEOSE(eventJson, url);
    } else if (eventJson[0] == 'CLOSED') {
      Logger.log.w(
          " CLOSED subscription url: $url id: ${eventJson[1]} msg: ${eventJson[2]}");
      globalState.inFlightRequests.remove(eventJson[1]);
    }
    // TODO
    // if (eventJson[0] == 'AUTH') {
    //   log("AUTH: ${eventJson[1]}");
    //   // nip 42 used to send authentication challenges
    //   return;
    // }
    //
    // if (eventJson[0] == 'COUNT') {
    //   log("COUNT: ${eventJson[1]}");
    //   // nip 45 used to send requested event counts to clients
    //   return;
    // }
  }

  void handleEOSE(List<dynamic> eventJson, String url) {
    String id = eventJson[1];
    RequestState? state = globalState.inFlightRequests[id];
    if (state != null && state.request.closeOnEOSE) {
      Logger.log.t(
          "⛁ received EOSE from $url for REQ id $id, remaining requests from :${state.requests.keys} kind:${state.requests.values.first.filters.first.kinds}");
      RelayRequestState? request = state.requests[url];
      if (request != null) {
        request.receivedEOSE = true;
        closeIfAllEventsVerified(request, state, url);
      }
    }
    return;
  }

  void sendCloseToRelay(String url, String id) {
    if (isWebSocketOpen(url)) {
      try {
        Relay? relay = getRelay(url);
        if (relay != null) {
          relay.stats.activeRequests--;
        }
        send(url, jsonEncode(["CLOSE", id]));
        logActiveRequests();
      } catch (e) {
        print(e);
      }
    }
  }

  void closeIfAllEventsVerified(
      RelayRequestState request, RequestState state, String url) {
    if (request.receivedEOSE && request.eventIdsToBeVerified.isEmpty) {
      if (state.request.closeOnEOSE) {
        sendCloseToRelay(url, state.id);
        if (state.requests.isEmpty || state.didAllRequestsReceivedEOSE) {
          removeInFlightRequest(state);
        }
      }
      state.requests.remove(url);
    }
  }

  void handleIncomingEvent(List<dynamic> eventJson, String url, message) {
    var id = eventJson[1];
    if (globalState.inFlightRequests[id] == null) {
      Logger.log.w(
          "RECEIVED EVENT from $url for id $id, not in globalState inFlightRequests");
      // send(url, jsonEncode(["CLOSE", id]));
      return;
    }

    Nip01Event event = Nip01Event.fromJson(eventJson[2]);
    if (!filterEvent(event)) {
      return;
    }
    // check signature is valid
    // if (!event.isIdValid) {
    //   Logger.log.e("RECEIVED $id INVALID EVENT $event");
    //   return;
    // }
    RequestState? state = globalState.inFlightRequests[id];
    if (state != null) {
      RelayRequestState? request = state.requests[url];
      if (request != null) {
        // request.eventIdsToBeVerified.add(event.id);
        // eventVerifier.verify(event).then((validSig) {
        //   if (validSig) {
        event.sources.add(url);
        // event.validSig = true;
        // if (relays[url] != null) {
        //   relays[url]!.incStatsByNewEvent(event, message.toString().codeUnits.length);
        // }
        if (state.networkController.isClosed) {
          Logger.log.e(
              "TRIED to add event to an already closed STREAM ${state.request.id} ${state.request.filters}");
        } else {
          state.networkController.add(event);
        }
        // } else {
        //   Logger.log.f("INVALID EVENT SIGNATURE: $event");
        // }
        // request.eventIdsToBeVerified.remove(event.id);
        // closeIfAllEventsVerified(request, state, url);
        // });
      }
    }
    return;
  }

  Relay? getRelay(String url) {
    Relay? r = relays[url];
    r ??= relays[cleanRelayUrl(url)];
    return r;
  }

  /// does relay support given nip
  bool doesRelaySupportNip(String url, int nip) {
    Relay? relay = relays[cleanRelayUrl(url)];
    return relay != null && relay.supportsNip(nip);
  }

  // =====================================================================================

  Map<String, List<PubkeyMapping>> allConnectedRelays(List<String> pubKeys) {
    Map<String, List<PubkeyMapping>> map = {};
    for (var relay in relays.keys) {
      if (isWebSocketOpen(relay)) {
        map[relay] = pubKeys
            .map((pubKey) => PubkeyMapping(
                pubKey: pubKey, rwMarker: ReadWriteMarker.readWrite))
            .toList();
      }
    }
    return map;
  }

  bool isRelayConnected(String url) {
    Relay? relay = relays[url];
    return relay != null && isWebSocketOpen(url);
  }

  Future<void> reconnectRelays(Iterable<String> urls) async {
    final startTime = DateTime.now();
    Logger.log.d("connecting ${urls.length} relays in parallel");
    List<bool> connected = await Future.wait(urls.map((url) {
      return reconnectRelay(url, force: true);
    }));
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.d(
        "CONNECTED ${connected.where((element) => element).length} , ${connected.where((element) => !element).length} FAILED, took ${duration.inMilliseconds} ms");
  }

  Future<bool> reconnectRelay(String url, {bool force = false}) async {
    Relay? relay = getRelay(url);
    if (allowReconnectRelays) {
      NostrTransport? transport = transports[cleanRelayUrl(url)];
      if (transport != null) {
        await transport.ready;
      }
      if (!isWebSocketOpen(url)) {
        if (relay != null &&
            !force &&
            !relay.wasLastConnectTryLongerThanSeconds(
                FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS)) {
          // don't try too often
          return false;
        }

        if (!await connectRelay(url)) {
          // could not connect
          return false;
        }
        if (!isWebSocketOpen(url)) {
          // web socket is not open
          return false;
        }
      }
    }
    return true;
  }

  Future<RelayInfo?> getRelayInfo(String url) async {
    if (relays[url] != null) {
      relays[url]!.info ??= await RelayInfo.get(url);
      return relays[url]!.info;
    }
    return null;
  }

  bool filterEvent(Nip01Event event) {
    for (var filter in eventFilters) {
      if (!filter.filter(event)) {
        return false;
      }
    }
    return true;
  }

  void logActiveRequests() {
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

  void _reSubscribeInFlightSubscriptions(String url) {
    globalState.inFlightRequests.forEach((key, state) {
      state.requests.values.where((req) => req.url == url).forEach((req) {
        if (!state.request.closeOnEOSE) {
          List<dynamic> list = ["REQ", state.id];
          list.addAll(req.filters.map((filter) => filter.toMap()));
          Relay? relay = getRelay(req.url);
          if (relay != null) {
            relay.stats.activeRequests++;
            send(url, jsonEncode(list));
            // TODO not sure if this works, since there are old streams on the ndk response???
          }
        }
      });
    });
  }
}
