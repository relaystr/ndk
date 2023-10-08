import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math';

import 'package:dart_ndk/relay.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'filter.dart';

class RelayManager {

  /// Bootstrap relays from these to start looking for NIP65/NIP03 events
  static const List<String> BOOTSTRAP_RELAYS = [
    "wss://purplepag.es",
    "wss://relay.damus.io",
    "wss://nos.lol",
    "wss://nostr.wine",
    "wss://relay.snort.social",
    "wss://nostr.bitcoiner.social"
  ];

  /// Global relay registry by url
  Map<String, Relay> relays = {};

  /// Global webSocket registry by url
  Map<String, WebSocketChannel> webSockets = {};

  /// Global completer subscriptions by request id
  final Map<String, Completer<Map<String, dynamic>>> _completers = {};

  // ====================================================================================================================

  /// This will initialize the manager with bootstrap relays.
  /// If you don't give any, will use some predefined
  Future<void> init({List<String> bootstrapRelays = BOOTSTRAP_RELAYS}) async {
    await Future.wait(bootstrapRelays.map((url) => connectRelay(url)).toList());
  }

  /// Connect a new relay
  Future<bool> connectRelay(String url) async {
    final wssUrl = Uri.parse(url);
    WebSocketChannel channel = WebSocketChannel.connect(wssUrl);
    webSockets[url] = channel;

    channel.ready.catchError((error) {
      throw Exception("Error in socket");
    });

    await channel.ready;

    channel.stream.listen((message) {
      _handleIncommingMessage(message);
    });
    channel.stream.handleError((error) {
      throw Exception("Error in socket");
    });
    if (kDebugMode) {
      print("connected to relay: $url");
    }
    return true;
  }

  Future<Map<String, dynamic>> request(String url, Filter filter) {
    WebSocketChannel? channel = webSockets[url];
    if (channel != null) {
      // TODO should check if connected / state
      String id = Random().nextInt(4294967296).toString();
      List<dynamic> request = ["REQ", id, filter.toMap()];
      final encoded = jsonEncode(request);
      var completer = Completer<Map<String, dynamic>>();
      _completers[id] = completer;
      channel.sink.add(encoded);
      var future =
      completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
        // log("Rtimeout: ${id}, $url");
        return {};
      });

      return future;
    }
    return Future.error("invalid relay $url");
  }

  _handleIncommingMessage(dynamic message) async {
    List<dynamic> eventJson = json.decode(message);

    if (eventJson[0] == 'OK') {
      //nip 20 used to notify clients if an EVENT was successful
      // log("OK: ${eventJson[1]}");

      // used for await on query
      _completers[eventJson[1]]?.complete(eventJson[1]);
      return;
    }

    if (eventJson[0] == 'NOTICE') {
      // log("NOTICE: ${eventJson[1]}");
      return;
    }

    if (eventJson[0] == 'EVENT') {
      _completers[eventJson[1]]?.complete(eventJson[2]);
      return;
    }
    // if (eventJson[0] == 'EOSE') {
    //   log("EOSE: ${eventJson[1]}, $relayUrl");
    //   _eoseStreamController.add(eventJson);
    //   // used for await on query
    //   _completers[eventJson[1]]?.complete(eventJson[1]);
    //   return;
    // }
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

  Relay? _getRelay(String url) {
    return relays[url];
  }

  bool _doesRelaySupportNip(String url, int nip) {
    Relay? relay = relays[url];
    return relay != null && relay.supportsNip(nip);
  }

}
