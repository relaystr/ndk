import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'nips/nip01.dart';
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

  /// Global subscriptions by request id
  final Map<String, Function(Nip01Event)> _subscriptions = {};

  // Global pub keys mappings by url
  Map<String, Set<PubkeyMapping>> pubKeyMappings = {};

  // todo: think about scoring according to nip65 nip05 kind03 etc
  // todo:  what happens if relay go down? and comes up? how do we make active subrscriptions to that relay again?

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

    // channel.ready.catchError((error) {
    //   print(error);
    //   //throw error;//Exception("Error in socket");
    // });

    await channel.ready;

    channel.stream.listen((message) {
      _handleIncommingMessage(message, url);
    });
    channel.stream.handleError((error) {
      throw Exception("Error in socket");
    });
    relays[url] = Relay(url);
    developer.log("connected to relay: $url");
    return true;
  }

  Future<void> query(Filter filter, Function(Nip01Event)? onEvent) async {
    /// extract from the filter which pubKeys and directions we should use the query for such filter
    List<PubkeyMapping> pubKeys = filter.extractPubKeyMappingsFromFilter();

    /// calculate best relays for each pubKey/direction considering connectivity quality for each relay
    Map<String, List<PubkeyMapping>> bestRelays = _calculateBestRelays(pubKeys);

    List<Future> futures = [];
    for (String url in bestRelays.keys) {
      List<PubkeyMapping>? pubKeys = bestRelays[url];
      Filter dedicatedFilter = filter.splitForPubKeys(pubKeys!);
      futures.add(request(url, dedicatedFilter, (json) {
        if (onEvent != null) {
          onEvent(json);
        }
      }));
    }
    await Future.wait(futures);
  }

  Future<Map<String, dynamic>> request(
      String url, Filter filter, Function(Nip01Event) onEvent) {
    WebSocketChannel? channel = webSockets[url];
    if (channel != null) {
      // TODO should check if connected / state
      String id = Random().nextInt(4294967296).toString();
      List<dynamic> request = ["REQ", id, filter.toMap()];
      final encoded = jsonEncode(request);
      var completer = Completer<Map<String, dynamic>>();
      _completers[id] = completer;
      _subscriptions[id] = onEvent;
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

  // =====================================================================================

  _handleIncommingMessage(dynamic message, String url) async {
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
      Nip01Event event = Nip01Event.fromJson(eventJson[2]);
      event.sources.add(url);
      _subscriptions[eventJson[1]]?.call(event);
      // _completers[eventJson[1]]?.complete(eventJson[2]);
      return;
    }
    if (eventJson[0] == 'EOSE') {
      // log("EOSE: ${eventJson[1]}, $relayUrl");
      // _eoseStreamController.add(eventJson);
      // used for await on query
      _completers[eventJson[1]]?.complete(eventJson[1]);
      return;
    }
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

  bool _isPubKeyForRead(String url, String pubKey) {
    Set<PubkeyMapping>? set = pubKeyMappings[url];
    return set != null &&
        set!.any((pubKeyMapping) =>
            pubKey == pubKeyMapping.pubKey && pubKeyMapping.isRead());
  }

  bool _isPubKeyForWrite(String url, String pubKey) {
    Set<PubkeyMapping>? set = pubKeyMappings[url];
    return set != null &&
        set!.any((pubKeyMapping) =>
            pubKey == pubKeyMapping.pubKey && pubKeyMapping.isWrite());
  }

  Map<String, List<PubkeyMapping>> _calculateBestRelays(
      List<PubkeyMapping> pubKeys) {
    /// todo: go fetch nip65 for pubKeys and check connectivity
    /// for now just return a map of all currently registered relays for each pubKeys
    Map<String, List<PubkeyMapping>> map = {};
    for (var relay in relays.keys) {
      map[relay] = pubKeys;
    }
    return map;
  }
}
