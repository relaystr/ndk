// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart' show StreamGroup;
import 'package:collection/collection.dart';
import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/db/user_contacts.dart';
import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/mem_cache_manager.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:dart_ndk/read_write.dart';
import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/relay_info.dart';
import 'package:dart_ndk/db/relay_set.dart';
import 'package:flutter/foundation.dart';

import 'nips/nip01/event.dart';
import 'nips/nip01/filter.dart';
import 'nips/nip65/nip65.dart';

class RelayManager {
  static const int DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT = 3;
  static const int DEFAULT_STREAM_IDLE_TIMEOUT = 5;
  static const int DEFAULT_BEST_RELAYS_MIN_COUNT = 2;
  static const int MAX_AUTHORS_PER_REQUEST = 100;
  static const int FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS = 60;
  static const int WEB_SOCKET_PING_INTERVAL_SECONDS = 3;

  /// Bootstrap relays from these to start looking for NIP65/NIP03 events
  static const List<String> DEFAULT_BOOTSTRAP_RELAYS = [
    "wss://purplepag.es",
    "wss://relay.damus.io",
    "wss://nos.lol",
    "wss://nostr.wine",
    "wss://nostr-pub.wellorder.net",
    "wss://offchain.pub",
    "wss://relay.mostr.pub"
  ];

  List<String> bootstrapRelays = DEFAULT_BOOTSTRAP_RELAYS;

  CacheManager cacheManager = MemCacheManager();

  /// Global relay registry by url
  Map<String, Relay> relays = {};

  /// Global webSocket registry by url
  Map<String, WebSocket> webSockets = {};

  // Global registry of RelaySets
  // Map<String, RelaySet> relaySets = {};

  /// Global subscriptions streams by request id
  final Map<String, StreamController<Nip01Event>> _subscriptions = {};

  final Map<String, StreamGroup<Nip01Event>> _subscriptionGroups = {};

  /// Queries close stream flag map by request Id (value true will close stream when receive EOSE, false will keep listening until client closes)
  final Map<String, bool> _requestQueries = {};

  // ====================================================================================================================

  Future<void> setCacheManager(CacheManager cacheManager) async {
    this.cacheManager = cacheManager;
  }

  /// This will initialize the manager with bootstrap relays.
  /// If you don't give any, will use some predefined
  Future<void> connect({List<String> bootstrapRelays = DEFAULT_BOOTSTRAP_RELAYS}) async {
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
  Future<bool> connectRelay(String url, {int connectTimeout = DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT}) async {
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
      print("connecting to relay $url");
      HttpClient httpClient = HttpClient();
      httpClient.idleTimeout = const Duration(seconds: 3600);
      webSockets[url] = await WebSocket.connect(url, customClient: httpClient).timeout(Duration(seconds: connectTimeout)).catchError((error) {
        return Future<WebSocket>.error(error);
      });
      // try {
      //   webSockets[url]!.done.then((value) {
      //     print("!!!!!!! $url IS DONE $value");
      //     webSockets.remove(url);
      //   },).onError((error, stackTrace) {
      //     print("error on done $error");
      //   });
      //   // print('WebSocket donw');
      // } catch (error) {
      //   print('WebScoket done with error $error');
      // }

      if (isWebSocketOpen(url)) {
        developer.log("connected to relay: $url");
        // webSockets[url]!.pingInterval = const Duration(seconds: WEB_SOCKET_PING_INTERVAL_SECONDS);
        relays[url]!.succeededToConnect();
        relays[url]!.stats.connections++;
        startListeningToSocket(url);
        return true;
      }
    } catch (e) {
      print("!! could not connect to $url -> $e");
    }
    relays[url]!.failedToConnect();
    relays[url]!.stats.connectionErrors++;
    return false;
  }

  void startListeningToSocket(String url) {
    // print("listening on $url...");
    webSockets[url]!.asBroadcastStream(onCancel: (sub) {
      // print("onCancel ${sub.");
    }, onListen: (sub) {
      // print("onListen $sub");
    }).listen((message) {
      _handleIncommingMessage(message, url);
    }, onError: (error) async {
      /// todo: handle this better, should clean subscription stuff
      print("onError $url on listen $error");
      throw Exception("Error in socket");
    }, onDone: () {
      print("onDone $url on listen, trying to reconnect");
      relays[url]!.stats.connectionErrors++;
      if (isWebSocketOpen(url)) {
        print("closing $url webSocket");
        webSockets[url]!.close().then(
          (value) {
            print("closed $url. Reconnecting");
            connectRelay(url);
          },
        );
      } else {
        connectRelay(url);
      }
      // startListeningToSocket(url);
      // if (webSockets[url] != null) {
      //   webSockets[url]!.close();
      //   webSockets.remove(url);
      // }
      /// todo: handle this better, should clean subscription stuff
    });
  }

  List<Relay> getConnectedRelays(Iterable<String> urls) {
    return urls.where((url) => isRelayConnected(url)).map((url) => relays[url]!).toList();
  }

  Future<Stream<Nip01Event>> subscriptionWithCalculation(Filter filter, {int relayMinCountPerPubKey = DEFAULT_BEST_RELAYS_MIN_COUNT}) async {
    return _doCalculateBestRelaysAndDoSubscriptionOrQuery(filter, closeOnEOSE: false, relayMinCountPerPubKey: relayMinCountPerPubKey);
  }

  Future<Stream<Nip01Event>> queryWithCalculation(Filter filter, {int relayMinCountPerPubKey = DEFAULT_BEST_RELAYS_MIN_COUNT}) async {
    return _doCalculateBestRelaysAndDoSubscriptionOrQuery(filter,
        closeOnEOSE: true, relayMinCountPerPubKey: relayMinCountPerPubKey, idleTimeout: DEFAULT_STREAM_IDLE_TIMEOUT);
  }

  Future<Stream<Nip01Event>> subscription(Filter filter, RelaySet relaySet, {int relayMinCountPerPubKey = DEFAULT_BEST_RELAYS_MIN_COUNT}) async {
    return _doSubscriptionOrQuery(filter, relaySet, closeOnEOSE: false);
  }

  Future<Stream<Nip01Event>> query(Filter filter, RelaySet relaySet) async {
    return _doSubscriptionOrQuery(filter, relaySet, closeOnEOSE: true);
  }

  Stream<Nip01Event> request(String url, Filter filter, {bool closeOnEOSE = true, int? idleTimeout, StreamGroup<Nip01Event>? streamGroup}) {
    if (isWebSocketOpen(url)) {
      String id = Random().nextInt(4294967296).toString();
      List<dynamic> request = ["REQ", id, filter.toMap()];
      final encoded = jsonEncode(request);
      _requestQueries[id] = closeOnEOSE;
      _subscriptions[id] = StreamController<Nip01Event>();
      if (streamGroup != null) {
        _subscriptionGroups[id] = streamGroup;
      }
      // print("Request for relay $url , $encoded (state is: ${webSockets[url]!.readyState})");
      try {
        webSockets[url]!.add(encoded);
      } catch (e) {
        print(e);
      }

      Stream<Nip01Event> stream = _subscriptions[id]!.stream;

      return idleTimeout != null
          ? stream.timeout(Duration(seconds: idleTimeout), onTimeout: (sink) {
              // print("TIMED OUT on relay $url for ${jsonEncode(filter.toMap())}");
              print("$idleTimeout TIMED OUT on relay $url for kinds ${filter.kinds}");
              sink.close();
            })
          : stream;
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
      if (_requestQueries[eventJson[1]] != null && _requestQueries[eventJson[1]]!) {
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
      if (relays[url] != null) {
        int eventsRead = relays[url]!.stats.eventsRead[event.kind] ?? 0;
        relays[url]!.stats.eventsRead[event.kind] = eventsRead + 1;
        int bytesRead = relays[url]!.stats.dataReadBytes[event.kind] ?? 0;
        relays[url]!.stats.dataReadBytes[event.kind] = bytesRead + message.toString().codeUnits.length;
      }
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

  Future<Stream<Nip01Event>> _doCalculateBestRelaysAndDoSubscriptionOrQuery(Filter filter,
      {bool closeOnEOSE = true, int? idleTimeout, int relayMinCountPerPubKey = DEFAULT_BEST_RELAYS_MIN_COUNT}) async {
    List<String> pubKeys = filter.authors != null ? filter.authors! : [];
    RelayDirection direction = RelayDirection.outbox;

    /// calculate best relays for each pubKey/direction considering connectivity quality for each relay
    RelaySet relaySet = await calculateRelaySet(pubKeys, direction, relayMinCountPerPubKey: relayMinCountPerPubKey);

    if (kDebugMode) {
      print("BEST ${relaySet.items.length} RELAYS:");
      relaySet.items.forEach((item) {
        print("  ${item.url} ${pubKeys.length} follows");
      });
    }

    return _doSubscriptionOrQuery(filter, relaySet, closeOnEOSE: closeOnEOSE, idleTimeout: idleTimeout);
  }

  Future<Stream<Nip01Event>> _doSubscriptionOrQuery(Filter filter, RelaySet relaySet, {bool closeOnEOSE = true, int? idleTimeout}) async {
    StreamGroup<Nip01Event> streamGroup = StreamGroup<Nip01Event>();

    for (var item in relaySet.items) {
      Filter relayFilter = splitFilter(item.pubKeyMappings, filter, relaySet.direction, relaySet.notCoveredPubkeys);

      requestWithSlicingFilterAuthors(relayFilter, streamGroup, item.url, closeOnEOSE: closeOnEOSE, idleTimeout: idleTimeout);
    }
    return streamGroup.stream;
  }

  Filter splitFilter(List<PubkeyMapping> pubKeyMappings, Filter filter, RelayDirection direction, List<NotCoveredPubKey> notCoveredPubKeys) {
    Filter relayFilter = filter;

    /// TODO allow for more usecases
    /// extract from the filter which pubKeys and directions we should use the query for such filter
    if (pubKeyMappings.isEmpty) {
      relayFilter = filter;
    } else if (filter.authors != null && filter.authors!.isNotEmpty && direction == RelayDirection.outbox) {
      List<String> pubKeysForRelay = [];
      for (String pubKey in filter.authors!) {
        if (pubKeyMappings.any((pubKeyMapping) => pubKey == pubKeyMapping.pubKey || notCoveredPubKeys.any((element) => element.pubKey == pubKey))) {
          pubKeysForRelay.add(pubKey);
        }
      }
      if (pubKeysForRelay.isNotEmpty) {
        relayFilter = filter.cloneWithAuthors(pubKeysForRelay);
      }
    } else if (filter.pTags != null && filter.pTags!.isNotEmpty && direction == RelayDirection.inbox) {
      List<String> pubKeysForRelay = [];
      for (String pubKey in filter.pTags!) {
        if (pubKeyMappings.any((pubKeyMapping) => pubKey == pubKeyMapping.pubKey || notCoveredPubKeys.any((element) => element.pubKey == pubKey))) {
          pubKeysForRelay.add(pubKey);
        }
      }
      if (pubKeysForRelay.isNotEmpty) {
        relayFilter = filter.cloneWithPTags(pubKeysForRelay);
      }
    } else {
      // ???
    }
    return relayFilter;
  }

  void requestWithSlicingFilterAuthors(Filter filter, StreamGroup<Nip01Event> streamGroup, String url, {bool closeOnEOSE = true, int? idleTimeout}) {
    if (filter.authors != null && filter.authors!.length > MAX_AUTHORS_PER_REQUEST) {
      Iterable<List<String>> slices = filter.authors!.slices(MAX_AUTHORS_PER_REQUEST);
      for (List<String> slice in slices) {
        streamGroup.add(request(url, filter.cloneWithAuthors(slice), closeOnEOSE: closeOnEOSE, idleTimeout: idleTimeout, streamGroup: streamGroup));
      }
    } else {
      streamGroup.add(request(url, filter, closeOnEOSE: closeOnEOSE, idleTimeout: idleTimeout, streamGroup: streamGroup));
    }
  }

  Future<Stream<Nip01Event>> requestRelays(List<String> urls, Filter filter, {int idleTimeout = DEFAULT_STREAM_IDLE_TIMEOUT}) async {
    StreamGroup<Nip01Event> streamGroup = StreamGroup<Nip01Event>();
    for (var url in urls) {
      requestWithSlicingFilterAuthors(filter, streamGroup, url, closeOnEOSE: true, idleTimeout: idleTimeout);
    }
    return streamGroup.stream.timeout(Duration(seconds: idleTimeout + 1));
  }

  RelaySet? getRelaySet(String name, String pubKey) {
    return cacheManager.loadRelaySet(name, pubKey);
  }

  Future<void> saveRelaySet(RelaySet relaySet) async {
    return cacheManager.saveRelaySet(relaySet);
  }

  /// relay -> list of pubKey mappings
  Future<RelaySet> calculateRelaySet(List<String> pubKeys, RelayDirection direction,
      {required int relayMinCountPerPubKey, Function(String, int, int)? onProgress}) async {
    RelaySet byScore = await _relaysByPopularity(pubKeys, direction, relayMinCountPerPubKey, onProgress: onProgress);

    /// try by score
    if (byScore.items.isNotEmpty) {
      return byScore;
    }

    /// if everything fails just return a map of all currently registered connected relays for each pubKeys
    return RelaySet(relayMinCountPerPubkey: relayMinCountPerPubKey, direction: direction, items: _allConnectedRelays(pubKeys), notCoveredPubkeys: []);
  }

  List<RelaySetItem> _allConnectedRelays(List<String> pubKeys) {
    List<RelaySetItem> items = [];
    for (var relay in relays.keys) {
      if (isWebSocketOpen(relay)) {
        items.add(RelaySetItem(relay, pubKeys.map((pubKey) => PubkeyMapping(pubKey: pubKey, rwMarker: ReadWriteMarker.readWrite)).toList()));
      }
    }
    return items;
  }

  /// - get missing relay lists for pubKeys from nip65 or nip02 (todo nip05)
  /// - construct a map of relays and pubKeys that use it in some marker direction (write for outbox feed)
  /// - sort this map by descending amount of pubKeys per relay
  /// - starting from the top relay (biggest count of pubKeys) iterate down and:
  ///   - check if relay is connected or can connect
  ///   - for each pubKey mapped for given relay check if you already have minimum amount of relay coverage (use auxiliary map to remember this)
  ///     - if not add this relay to list of best relays
  Future<RelaySet> _relaysByPopularity(List<String> pubKeys, RelayDirection direction, int relayMinCount,
      {Function(String stepName, int count, int total)? onProgress}) async {
    await loadMissingRelayListsFromNip65OrNip02(pubKeys, onProgress: onProgress);

    Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl = await _buildPubKeysMapFromRelayLists(pubKeys, direction);

    Map<String, Set<String>> minimumRelaysCoverageByPubkey = {};
    Map<String, List<PubkeyMapping>> bestRelays = {};
    if (onProgress != null) {
      print("Calculating best relays...");
      onProgress.call("Calculating best relays", minimumRelaysCoverageByPubkey.length, pubKeysByRelayUrl.length);
    }
    Map<String, int> notCoveredPubkeys = {};
    pubKeys.forEach((pubKey) {
      notCoveredPubkeys[pubKey] = relayMinCount;
    });
    for (String url in pubKeysByRelayUrl.keys) {
      if (!pubKeysByRelayUrl[url]!
          .any((pub_key) => minimumRelaysCoverageByPubkey[pub_key.pubKey] == null || minimumRelaysCoverageByPubkey[pub_key.pubKey]!.length < relayMinCount)) {
        continue;
      }
      if (!await _reconnectRelay(url)) {
        continue;
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
          int count = notCoveredPubkeys[pubKey.pubKey] ?? relayMinCount;
          notCoveredPubkeys[pubKey.pubKey] = count - 1;
        }
      }
      if (onProgress != null) {
        // print(
        //     "Calculating best relays minimumRelaysCoverageByPubkey.length:${minimumRelaysCoverageByPubkey
        //         .length} pubKeysByRelayUrl.length: ${pubKeys.length}");
        onProgress.call("Calculating best relays", minimumRelaysCoverageByPubkey.length, pubKeys.length);
      }
    }

    notCoveredPubkeys.removeWhere((key, value) => value <= 0);

    return RelaySet(
        relayMinCountPerPubkey: relayMinCount,
        direction: direction,
        items: bestRelays.entries.map((entry) => RelaySetItem(entry.key, entry.value)).toList(),
        notCoveredPubkeys: notCoveredPubkeys.entries
            .map(
              (entry) => NotCoveredPubKey(entry.key, entry.value),
            )
            .toList());
  }

  Future<void> loadMissingRelayListsFromNip65OrNip02(List<String> pubKeys, {Function(String stepName, int count, int total)? onProgress}) async {
    List<String> missingPubKeys = [];
    for (var pubKey in pubKeys) {
      UserRelayList? userRelayList = cacheManager.loadUserRelayList(pubKey); //getUserRelayList(pubKey);
      if (userRelayList == null) {
        // TODO check if not too old (time passed since last refreshed timestamp)
        missingPubKeys.add(pubKey);
      }
    }
    Map<String, UserRelayList> fromNip65s = {};
    Map<String, UserRelayList> fromNip02Contacts = {};
    Set<String> found = {};

    if (missingPubKeys.isNotEmpty) {
      print("loading missing relay lists ${missingPubKeys.length}");
      if (onProgress != null) {
        onProgress.call("loading missing relay lists", 0, missingPubKeys.length);
      }
      try {
        await for (final event
            in await requestRelays(idleTimeout: 10, bootstrapRelays, Filter(authors: missingPubKeys, kinds: [Nip65.kind, Nip02ContactList.kind]))) {
          switch (event.kind) {
            case Nip65.kind:
              Nip65 nip65 = Nip65.fromEvent(event);
              if (nip65.relays.isNotEmpty) {
                UserRelayList fromNip65 = UserRelayList.fromNip65(nip65);
                if (fromNip65s[event.pubKey] == null || fromNip65s[event.pubKey]!.createdAt < event.createdAt) {
                  fromNip65s[event.pubKey] = fromNip65;
                }
                if (onProgress != null) {
                  found.add(event.pubKey);
                  onProgress.call("loading missing relay lists", found.length, missingPubKeys.length);
                }
              }
              break;
            case Nip02ContactList.kind:
              Nip02ContactList contactList = Nip02ContactList.fromEvent(event);
              if (contactList.relaysInContent.isNotEmpty) {
                UserRelayList fromContacts = UserRelayList.fromNip02ContactList(contactList);
                if (fromNip02Contacts[event.pubKey] == null || fromNip02Contacts[event.pubKey]!.createdAt < event.createdAt) {
                  fromNip02Contacts[event.pubKey] = fromContacts;
                }
                if (onProgress != null) {
                  found.add(event.pubKey);
                  onProgress.call("loading missing relay lists", found.length, missingPubKeys.length);
                }
              }
              break;
          }
        }
      } catch (e) {
        print(e);
      }
      Set<UserRelayList> relayLists = Set.of(fromNip65s.values);
      // Only add kind3 contents relays if there is no Nip65 for given pubKey.
      // This is because kind3 contents relay should be deprecated, and if we have a nip65 list should be considered more up-to-date.
      for(MapEntry<String,UserRelayList> entry in fromNip02Contacts.entries) {
        if (!fromNip65s.containsKey(entry.key)) {
          relayLists.add(entry.value);
        }
      }
      await cacheManager.saveUserRelayLists(relayLists.toList());
      if (onProgress != null) {
        onProgress.call("loading missing relay lists", found.length, missingPubKeys.length);
      }
    }
    print("Loaded ${found.length} relay lists ");
  }

  Future<UserContacts?> loadUserContacts(String pubKey, {bool forceRefresh = false}) async {
    UserContacts? userContacts = cacheManager.loadUserContacts(pubKey);
    if (userContacts == null || forceRefresh) {
      try {
        await for (final event in await requestRelays(
            bootstrapRelays, idleTimeout: DEFAULT_STREAM_IDLE_TIMEOUT, Filter(kinds: [Nip02ContactList.kind], authors: [pubKey], limit: 1))) {
          if (userContacts == null || userContacts.createdAt < event.createdAt) {
            userContacts = UserContacts.fromNip02ContactList(Nip02ContactList.fromEvent(event));
          }
        }
      } catch (e) {
        // probably timeout;
      }
    }
    if (userContacts != null) {
      await cacheManager.saveUserContacts(userContacts);
    }
    return userContacts;
  }

  UserContacts? getUserContacts(String pubKey) {
    return cacheManager.loadUserContacts(pubKey);
  }

  _buildPubKeysMapFromRelayLists(List<String> pubKeys, RelayDirection direction) async {
    Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl = {};
    int foundCount = 0;
    for (String pubKey in pubKeys) {
      UserRelayList? userRelayList = cacheManager.loadUserRelayList(pubKey);
      if (userRelayList != null) {
        if (userRelayList.items.isNotEmpty) {
          foundCount++;
        }
        for (var item in userRelayList.items) {
          _handleRelayUrlForPubKey(pubKey, direction, item.url, item.marker, pubKeysByRelayUrl);
        }
      } else {
        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await cacheManager.saveUserRelayList(UserRelayList(pubKey, [], now, now));
      }
    }
    print("Have lists of relays for $foundCount/${pubKeys.length} pubKeys ${foundCount < pubKeys.length ? "(missing ${pubKeys.length - foundCount})" : ""}");

    /// sort by pubKeys count for each relay descending
    List<MapEntry<String, Set<PubkeyMapping>>> sortedEntries = pubKeysByRelayUrl.entries.toList()

      /// todo: use more stuff to improve sorting
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Map<String, Set<PubkeyMapping>>.fromEntries(sortedEntries);
  }

  _handleRelayUrlForPubKey(String pubKey, RelayDirection direction, String url, ReadWriteMarker marker, Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl) {
    String? cleanUrl = Relay.clean(url);
    if (cleanUrl != null) {
      if (direction.matchesMarker(marker)) {
        Set<PubkeyMapping>? set = pubKeysByRelayUrl[cleanUrl];
        if (set == null) {
          pubKeysByRelayUrl[cleanUrl] = {};
        }
        pubKeysByRelayUrl[cleanUrl]!.add(PubkeyMapping(pubKey: pubKey, rwMarker: marker));
      }
    }
  }

  bool isRelayConnected(String url) {
    Relay? relay = relays[url];
    return relay != null && isWebSocketOpen(url);
  }

  reconnectRelays(List<String> urls) async {
    final startTime = DateTime.now();
    print("connecting ${urls.length} relays in parallel");
    List<bool> connected = await Future.wait(urls.map((url) {
      return _reconnectRelay(url, force: true);
    }));
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print(
        "CONNECTED ${connected.where((element) => element).length} , ${connected.where((element) => !element).length} FAILED took ${duration.inMilliseconds} ms");
  }

  Future<bool> _reconnectRelay(String url, {bool force = false}) async {
    Relay? relay = relays[url];
    if (relay == null || !isWebSocketOpen(url)) {
      if (relay != null && !force && !relay.wasLastConnectTryLongerThanSeconds(FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS)) {
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
    return true;
  }

  Future<UserRelayList?> getSingleUserRelayList(String pubKey) async {
    UserRelayList? userRelayList = cacheManager.loadUserRelayList(pubKey);
    if (userRelayList == null) {
      /// todo should also load from nip02
      await for (final event in await requestRelays(bootstrapRelays.toList(), Filter(authors: [pubKey], kinds: [Nip65.kind], limit: 1))) {
        if (userRelayList == null || userRelayList.createdAt < event.createdAt) {
          userRelayList = UserRelayList.fromNip65(Nip65.fromEvent(event));
          // should it be sync or async is ok?
          // await cache.saveUserRelayList(userRelayList);
        }
      }
    }
    return userRelayList;
  }

  Future<RelayInfo?> getRelayInfo(String url) async {
    Relay? relay = relays[url];
    if (relay != null) {
      relay.info ??= await RelayInfo.get(url);
      return relay.info;
    }
    return null;
  }
}
