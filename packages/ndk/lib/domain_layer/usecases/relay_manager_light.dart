import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../../config/bootstrap_relays.dart';
import '../../config/relay_defaults.dart';
import '../../shared/helpers/relay_helper.dart';
import '../../shared/logger/logger.dart';
import '../entities/connection_source.dart';
import '../entities/global_state.dart';
import '../entities/relay.dart';
import '../entities/relay_connectivity.dart';
import '../entities/relay_info.dart';
import '../entities/tuple.dart';
import '../repositories/nostr_transport.dart';

/// wip relay manger that only does connection and relay lifecycle management
class RelayManagerLight {
  final Completer<void> _seedRelaysCompleter = Completer<void>();

  /// completes when all seed relays are connected
  Future<void> get seedRelaysConnected => _seedRelaysCompleter.future;

  GlobalState globalState;
  final NostrTransportFactory nostrTransportFactory;

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
        globalState.relays[url] = RelayConnectivity(
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
      globalState.relays[url]!.relay.stats.connections++;
      getRelayInfo(url);
      return Tuple(true, "");
    } catch (e) {
      print("!! could not connect to $url -> $e");
      globalState.relays[url]!.relayTransport == null;
    }
    globalState.relays[url]!.relay.failedToConnect();
    globalState.relays[url]!.relay.stats.connectionErrors++;
    return Tuple(false, "could not connect to $url");
  }

  void _startListeningToSocket(RelayConnectivity relayConnectivity) {
    relayConnectivity.relayTransport!.listen((message) {
      _handleIncommingMessage(
        message,
        relayConnectivity,
      );
    }, onError: (error) async {
      /// todo: handle this better, should clean subscription stuff
      relayConnectivity.relay.stats.connectionErrors++;
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

  Future<bool> reconnectRelay(RelayConnectivity relayConnectivity) {
    throw UnimplementedError();
  }

  void _reSubscribeInFlightSubscriptions(RelayConnectivity relayConnectivity) {
    globalState.inFlightRequests.forEach((key, state) {
      state.requests.values
          .where((req) => req.url == relayConnectivity.url)
          .forEach((req) {
        if (!state.request.closeOnEOSE) {
          List<dynamic> list = ["REQ", state.id];
          list.addAll(req.filters.map((filter) => filter.toMap()));
          Relay relay = relayConnectivity.relay;

          relay.stats.activeRequests++;
          _send(relayConnectivity, jsonEncode(list));
        }
      });
    });
  }

  void _send(RelayConnectivity relayConnectivity, dynamic data) {
    relayConnectivity.relayTransport!.send(data);
    Logger.log.d("send message to ${relayConnectivity.url}: $data");
  }

  void _handleIncommingMessage(
      dynamic message, RelayConnectivity relayConnectivity) {
    List<dynamic> eventJson = json.decode(message);

    if (eventJson[0] == 'OK') {
      //nip 20 used to notify clients if an EVENT was successful
      if (eventJson.length >= 2 && eventJson[2] == false) {
        Logger.log.e("NOT OK from ${relayConnectivity.url}: $eventJson");
      }
      globalState.activeBroadcasts[eventJson[1]]?.completePublishingRelay(
        url: relayConnectivity.url,
        success: eventJson[2],
        response: eventJson[3] ?? '',
      );

      return;
    }
    if (eventJson[0] == 'NOTICE') {
      Logger.log.w("NOTICE from ${relayConnectivity.url}: ${eventJson[1]}");
    } else if (eventJson[0] == 'EVENT') {
      //handleIncomingEvent(eventJson, url, message);
      Logger.log.d("EVENT from ${relayConnectivity.url}: $eventJson");
    } else if (eventJson[0] == 'EOSE') {
      Logger.log.d("EOSE from ${relayConnectivity.url}: ${eventJson[1]}");
      //handleEOSE(eventJson, url);
    } else if (eventJson[0] == 'CLOSED') {
      Logger.log.w(
          " CLOSED subscription url: ${relayConnectivity.url} id: ${eventJson[1]} msg: ${eventJson.length > 2 ? eventJson[2] : ''}");
      globalState.inFlightRequests.remove(eventJson[1]);
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
