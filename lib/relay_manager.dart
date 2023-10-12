import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip02/metadata.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/pubkey_mapping.dart';

import 'nips/nip01/event.dart';
import 'nips/nip01/filter.dart';
import 'package:async/async.dart' show StreamGroup;

import 'nips/nip65/nip65.dart';

class RelayManager {
  static const int DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT = 2;
  static const int DEFAULT_STREAM_IDLE_TIMEOUT = 10;
  static const int DEFAULT_BEST_RELAYS_MIN_COUNT = 2;

  /// Bootstrap relays from these to start looking for NIP65/NIP03 events
  static const List<String> DEFAULT_BOOTSTRAP_RELAYS = [
    "wss://purplepag.es",
    "wss://relay.damus.io",
    "wss://nos.lol",
    "wss://nostr.wine",
    "wss://relay.snort.social",
    "wss://nostr.bitcoiner.social"
  ];

  List<String> bootstrapRelays = DEFAULT_BOOTSTRAP_RELAYS;

  /// Global relay registry by url
  Map<String, Relay> relays = {};

  /// Global webSocket registry by url
  Map<String, WebSocket> webSockets = {};

  /// Global subscriptions streams by request id
  final Map<String, StreamController<Nip01Event>> _subscriptions = {};

  final Map<String, StreamGroup<Nip01Event>> _subscriptionGroups = {};

  /// Queries close stream flag map by request Id (value true will close stream when receive EOSE, false will keep listening until client closes)
  final Map<String, bool> _requestQueries = {};

  /// Global nip65 map by pubKey
  Map<String, Nip65> nip65s = {};

  /// Global nip02 contact lists map by pubKey
  Map<String, Nip02ContactList> nip02s = {};

  // ====================================================================================================================

  /// This will initialize the manager with bootstrap relays.
  /// If you don't give any, will use some predefined
  Future<void> connect(
      {List<String> bootstrapRelays = DEFAULT_BOOTSTRAP_RELAYS}) async {
    this.bootstrapRelays = bootstrapRelays;
    await Future.wait(bootstrapRelays.map((url) => connectRelay(url)).toList());
  }

  bool isWebSocketOpen(String url) {
    WebSocket? webSocket = webSockets[url];
    return webSocket != null && webSocket.readyState == WebSocket.open;
  }

  bool isWebSocketConnecting(String url) {
    WebSocket? webSocket = webSockets[url];
    return webSocket != null && webSocket.readyState == WebSocket.connecting;
  }

  bool isRelayConnecting(String url) {
    Relay? relay = relays[url];
    return relay != null && relay.connecting;
  }

  /// Connect a new relay
  Future<bool> connectRelay(String url,
      {int connectTimeout = DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT}) async {
    try {
      relays[url] = Relay(url);
      relays[url]!.connecting = true;
      print("connecting to relay $url");
      webSockets[url] = await WebSocket.connect(url)
          .timeout(Duration(seconds: connectTimeout))
          .onError((error, stackTrace) {
        relays[url]!.connecting = false;
        print("could not connect to relay $url error:$error");
        throw Exception();
      });

      relays[url]!.connecting = false;

      webSockets[url]!.listen((message) {
        _handleIncommingMessage(message, url);
      }, onError: (error) async {
        /// todo: handle this better, should clean subscription stuff
        throw Exception("Error in socket");
      }, onDone: () {
        /// todo: handle this better, should clean subscription stuff
      });

      if (isWebSocketOpen(url)) {
        developer.log("connected to relay: $url");
        return true;
      }
    } catch (e) {

    }
    return false;
  }

  Future<Stream<Nip01Event>> subscription(Filter filter,
      {int relayMinCount = DEFAULT_BEST_RELAYS_MIN_COUNT}) async {
    return _doSubscriptionOrQuery(filter,
        closeOnEOSE: false, relayMinCount: relayMinCount);
  }

  Future<Stream<Nip01Event>> query(Filter filter,
      {int relayMinCount = DEFAULT_BEST_RELAYS_MIN_COUNT}) async {
    return _doSubscriptionOrQuery(filter,
        closeOnEOSE: true, relayMinCount: relayMinCount);
  }

  Stream<Nip01Event> request(String url, Filter filter,
      {bool closeOnEOSE = true,
      int? idleTimeout,
      StreamGroup<Nip01Event>? streamGroup}) {
    if (isWebSocketOpen(url)) {
      String id = Random().nextInt(4294967296).toString();
      List<dynamic> request = ["REQ", id, filter.toMap()];
      final encoded = jsonEncode(request);
      _requestQueries[id] = closeOnEOSE;
      _subscriptions[id] = StreamController<Nip01Event>();
      if (streamGroup != null) {
        _subscriptionGroups[id] = streamGroup;
      }
      // print("Request for relay $url -> $encoded");
      webSockets[url]!.add(encoded);

      return _subscriptions[id]!.stream.timeout(
          Duration(seconds: idleTimeout ?? DEFAULT_STREAM_IDLE_TIMEOUT),
          onTimeout: (sink) {
        print("TIMED OUT on relay $url for $filter");
        sink.close();
      });
    }
    return const Stream.empty();
  }

  // =====================================================================================

  _handleIncommingMessage(dynamic message, String url) async {
    List<dynamic> eventJson = json.decode(message);

    if (eventJson[0] == 'OK') {
      //nip 20 used to notify clients if an EVENT was successful
      // log("OK: ${eventJson[1]}");

      // used for await on query
      if (_requestQueries[eventJson[1]] != null &&
          _requestQueries[eventJson[1]]!) {
        _subscriptions[eventJson[1]]?.close();
      }
      return;
    }

    if (eventJson[0] == 'NOTICE') {
      // log("NOTICE: ${eventJson[1]}");
      return;
    }

    if (eventJson[0] == 'EVENT') {
      Nip01Event event = Nip01Event.fromJson(eventJson[2]);
      event.sources.add(url);
      _subscriptions[eventJson[1]]?.add(event);
      return;
    }
    if (eventJson[0] == 'EOSE') {
      // print("EOSE: ${eventJson[1]}, $url");
      String id = eventJson[1];
      if (_requestQueries[id] != null && _requestQueries[id]!) {
        _subscriptions[id]?.close();
        _requestQueries.remove(id);
        _subscriptions.remove(id);
      }
      if (_subscriptionGroups[id] != null) {
        _subscriptionGroups[id]!.close();
      }
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

  Future<Stream<Nip01Event>> _doSubscriptionOrQuery(Filter filter,
      {bool closeOnEOSE = true,
      int? idleTimeout,
      int relayMinCount = DEFAULT_BEST_RELAYS_MIN_COUNT}) async {

    /// extract from the filter which pubKeys and directions we should use the query for such filter
    List<PubkeyMapping> pubKeys = filter.extractPubKeyMappingsFromFilter();

    /// calculate best relays for each pubKey/direction considering connectivity quality for each relay
    Map<String, List<PubkeyMapping>> bestRelays =
        await _calculateBestRelaysForPubKeyMappings(pubKeys, relayMinCount);

    print("BEST ${bestRelays.length} RELAYS:");
    bestRelays.forEach((url, pubKeys) {
      print("  $url ${pubKeys.length} follows");
    });

    StreamGroup<Nip01Event> streamGroup = StreamGroup<Nip01Event>();
    for (var url in bestRelays.keys) {
      List<PubkeyMapping>? pubKeys = bestRelays[url];
      Filter dedicatedFilter = filter.splitForPubKeys(pubKeys!);
//      print("SPLITING request on $url filter $dedicatedFilter");
      streamGroup.add(request(url, dedicatedFilter,
          closeOnEOSE: closeOnEOSE,
          idleTimeout: idleTimeout,
          streamGroup: streamGroup));
    }
    return streamGroup.stream;
  }

  Future<Stream<Nip01Event>> requestRelays(
      List<String> urls, Filter filter) async {
    StreamGroup<Nip01Event> streamGroup = StreamGroup<Nip01Event>();
    for (var url in urls) {
      streamGroup.add(request(url, filter, streamGroup: streamGroup));
    }
    return streamGroup.stream;
  }

  /// relay -> list of pubKey mappings
  Future<Map<String, List<PubkeyMapping>>>
      _calculateBestRelaysForPubKeyMappings(
          List<PubkeyMapping> pubKeys, int relayMinCount) async {
    Map<String, List<PubkeyMapping>> byScore =
        await _relaysByScore(pubKeys, relayMinCount);

    /// try by score
    if (byScore != null && byScore.isNotEmpty) {
      return byScore;
    }

    /// if everything fails just return a map of all currently registered connected relays for each pubKeys
    return _allConnectedRelays(pubKeys);
  }
  Map<String, List<PubkeyMapping>> _allConnectedRelays(
      List<PubkeyMapping> pubKeys) {
    Map<String, List<PubkeyMapping>> map = {};
    for (var relay in relays.keys) {
      if (isWebSocketOpen(relay)) {
        map[relay] = pubKeys;
      }
    }
    return map;
  }


  /// - get all nip65s for all pubKeys
  /// - construct a map of relays and pubKeys that use it in some marker direction (write for outbox feed)
  /// - sort this map by descending amount of pubKeys (in future take other stuff into account like source of relay list)
  /// - starting from the top (biggest count of pubKeys) iterate and:
  ///   - check if relay is connected or can connect
  ///   - construct a map of pubKeys and minimum amount of relays needed for each pub key coverage
  ///   - gather best Relays
  Future<Map<String, List<PubkeyMapping>>> _relaysByScore(
      List<PubkeyMapping> pubKeys, int relayMinCount) async {

    await _loadMissingRelayListsFromNip65OrNip02(pubKeys);

    Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl = await _buildPubKeysMapFromRelayLists(pubKeys);

    Map<String, Set<String>> minimumRelaysCoverageByPubkey = {};
    Map<String, List<PubkeyMapping>> bestRelays = {};

    for (String url in pubKeysByRelayUrl.keys) {
      if (!pubKeysByRelayUrl[url]!.any((pub_key) =>
          minimumRelaysCoverageByPubkey[pub_key.pubKey] == null ||
          minimumRelaysCoverageByPubkey[pub_key.pubKey]!.length <
              relayMinCount)) {
        continue;
      }
      Relay? relay = relays[url];
      if (relay == null || !isWebSocketOpen(url)) {
        await connectRelay(url);
      }
      if (bestRelays[url] == null) {
        bestRelays[url] = [];
      }
      for (PubkeyMapping pubKey in pubKeysByRelayUrl[url]!) {
        Set<String>? relays = minimumRelaysCoverageByPubkey[pubKey.pubKey];
        if (relays == null) {
          relays = {};
          minimumRelaysCoverageByPubkey[pubKey.pubKey] = relays;
        }
        relays.add(url);
        if (!bestRelays[url]!.contains(pubKey)) {
          bestRelays[url]!.add(pubKey);
        }
      }
    }

    return bestRelays;
  }

  _loadMissingRelayListsFromNip65OrNip02(List<PubkeyMapping> pubKeys) async {
    List<String> missingPubKeys = [];
    for (var pubKey in pubKeys) {
      Map<String,ReadWriteMarker>? map = getRelayMarkerMap(pubKey.pubKey);
      if (map==null || map.isEmpty) {
        missingPubKeys.add(pubKey.pubKey);
      }
    }
    if (missingPubKeys.isNotEmpty) {
      await for (final event in await requestRelays(
          bootstrapRelays,
          Filter(
              authors: missingPubKeys,
              kinds: [Nip65.kind, Nip02ContactList.kind]))) {
        switch (event.kind) {
          case Nip65.kind:
            if (nip65s[event.pubKey] == null ||
                nip65s[event.pubKey]!.createdAt < event.createdAt) {
              nip65s[event.pubKey] = Nip65.fromEvent(event);
            }
            break;
          case Nip02ContactList.kind:
            if (nip02s[event.pubKey] == null ||
                nip02s[event.pubKey]!.createdAt < event.createdAt) {
              nip02s[event.pubKey] = Nip02ContactList.fromEvent(event);
            }
            break;
        }
      }
    }
  }

  Future<Nip02ContactList?> loadContactList(String pubKey) async {
    if (nip02s[pubKey]==null) {
      Stream<Nip01Event> contactListQuery = await requestRelays( bootstrapRelays,
          Filter(kinds: [Nip02ContactList.kind], authors: [pubKey]));

      await for (final event in contactListQuery) {
        if (nip02s[pubKey]==null || nip02s[pubKey]!.createdAt < event.createdAt) {
          nip02s[pubKey] = Nip02ContactList.fromEvent(event);
        }
      }
    }
    return nip02s[pubKey];
  }

  Map<String,ReadWriteMarker>? getRelayMarkerMap(String pubKey) {
    Nip65? nip65 = nip65s[pubKey]; //await getNip65(pubKey.pubKey);
    if (nip65 != null && nip65.relays.isNotEmpty) {
      return nip65.relays;
    } else {
      Nip02ContactList? nip02 = nip02s[pubKey];
      if (nip02!=null && nip02.relaysInContent.isNotEmpty) {
        return nip02.relaysInContent;
      }
    }
    return null;
  }

  _buildPubKeysMapFromRelayLists(List<PubkeyMapping> pubKeys) async {
    Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl = {};
    int foundCount = 0;
    for (PubkeyMapping pubKey in pubKeys) {
      bool foundRelayList = false;
      Map<String, ReadWriteMarker>? relayMap = getRelayMarkerMap(pubKey.pubKey);
      if (relayMap!=null && relayMap.isNotEmpty) {
        foundRelayList = true;
        relayMap.forEach((url, marker) {
          _handleRelayUrlForPubKey(pubKey, url,marker, pubKeysByRelayUrl);
        });
      }
      if (foundRelayList) {
        foundCount++;
      } else {
        print("Missing relay list from nip65 or nip02 for ${pubKey.pubKey} (${Helpers.encodeBech32(pubKey.pubKey, "npub")})");
      }
    }
    print("Have lists of relays for ${foundCount}/${pubKeys.length} pubKeys "+(foundCount < pubKeys.length? "(missing ${pubKeys.length - foundCount})":""));

    /// sort by pubKeys count for each relay descending
    List<MapEntry<String, Set<PubkeyMapping>>> sortedEntries =
    pubKeysByRelayUrl.entries.toList()

    /// todo: use more stuff to improve sorting
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Map<String, Set<PubkeyMapping>>.fromEntries(sortedEntries);
  }

  _handleRelayUrlForPubKey(PubkeyMapping pubKey, String url, ReadWriteMarker marker, Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl) {
    String? cleanUrl = Relay.clean(url);
    if (cleanUrl!=null) {
      if (pubKey.rwMarker.isWrite && marker.isWrite ||
          pubKey.rwMarker.isRead && marker.isRead) {
        Set<PubkeyMapping>? set = pubKeysByRelayUrl[cleanUrl];
        if (set == null) {
          pubKeysByRelayUrl[cleanUrl] = {};
        }
        pubKeysByRelayUrl[cleanUrl]!.add(pubKey);
      }
    }
  }

// Future<Nip65?> getSingleNip65(String pubKey) async {
//   if (nip65s[pubKey] == null) {
//     await for (final event in await requestRelays(relays.keys.take(3).toList(), Filter(authors: [pubKey], kinds: [Nip65.kind], limit:1))) {
//       if (nip65s[pubKey] == null || nip65s[pubKey]!.createdAt < event.createdAt) {
//         nip65s[pubKey] = Nip65.fromEvent(event);
//         print("Received Nip65 ${nip65s[pubKey]}");
//       }
//     }
//   }
//   return nip65s[pubKey];
// }
}
