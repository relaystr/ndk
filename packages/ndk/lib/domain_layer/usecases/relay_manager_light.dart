import 'dart:async';
import 'dart:developer' as developer;

import '../../config/bootstrap_relays.dart';
import '../../config/relay_defaults.dart';
import '../../shared/helpers/relay_helper.dart';
import '../entities/global_state.dart';
import '../entities/relay.dart';
import '../entities/relay_connectivity.dart';
import '../entities/relay_info.dart';
import '../entities/tuple.dart';
import '../repositories/nostr_transport.dart';

/// wip relay manger that only does connection and relay lifecycle management
class RelayManagerLight {
  final Completer<void> _seedRelaysCompleter = Completer<void>();

  get seedRelaysConnected => _seedRelaysCompleter.future;

  GlobalState globalState;
  final NostrTransportFactory nostrTransportFactory;

  RelayManagerLight({
    required this.globalState,
    required this.nostrTransportFactory,
  }) {
    _connectSeedRelays();
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
    await Future.wait(urls.map((url) => connectRelay(url)).toList())
        .whenComplete(() {
      if (!_seedRelaysCompleter.isCompleted) {
        _seedRelaysCompleter.complete();
      }
    });
  }

  /// Connects to a relay to the relay pool.
  /// Returns a tuple with the first element being a boolean indicating success \\
  /// and the second element being a string with the error message if any.
  Future<Tuple<bool, String>> connectRelay(
    String dirtyUrl, {
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
        globalState.relays[url] = RelayConnectivity(relay: Relay(url));
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
        relayConnectivity.url,
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
          send(url, jsonEncode(list));
          // TODO not sure if this works, since there are old streams on the ndk response???
        }
      });
    });
  }

  _handleIncommingMessage(dynamic message, String url) {
    throw UnimplementedError();
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
