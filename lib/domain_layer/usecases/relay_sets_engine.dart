// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:core';

import 'package:ndk/data_layer/repositories/cache_manager/mem_cache_manager.dart';
import 'package:ndk/domain_layer/entities/contact_list.dart';
import 'package:ndk/domain_layer/entities/pubkey_mapping.dart';
import 'package:ndk/domain_layer/entities/read_write.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/repositories/cache_manager.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';
import 'package:ndk/presentation_layer/global_state.dart';
import 'package:ndk/presentation_layer/request_response.dart';
import 'package:ndk/shared/logger/logger.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

import '../../presentation_layer/ndk_request.dart';
import '../../shared/helpers/relay_helper.dart';
import '../entities/filter.dart';
import '../entities/nip_65.dart';
import '../entities/relay_set.dart';
import '../entities/request_state.dart';
import '../entities/user_relay_list.dart';
import '../repositories/event_verifier.dart';

class RelaySetsEngine {
  static const int DEFAULT_STREAM_IDLE_TIMEOUT = 5;

  late GlobalState globalState;

  RelayManager relayManager;
  late CacheManager cacheManager;

  RelaySetsEngine(
      { required this.relayManager,
        CacheManager? cacheManager,
      EventVerifier? eventVerifier,
      GlobalState? globalState}) {
    this.cacheManager = cacheManager ?? MemCacheManager();
    this.globalState = globalState ?? GlobalState();
  }

  // ====================================================================================================================

  bool doRelayRequest(String id, RelayRequestState request) {
    if (relayManager.isWebSocketOpen(request.url) &&
        (!relayManager.blockedRelays.contains(request.url))) {
      try {
        List<dynamic> list = ["REQ", id];
        list.addAll(request.filters.map((filter) => filter.toMap()));
        relayManager.send(request.url, jsonEncode(list));
        return true;
      } catch (e) {
        print(e);
      }
    } else {
      print(
          "COULD NOT SEND REQUEST TO ${request.url} since socket seems to be not open");

      relayManager.reconnectRelay(request.url);
    }
    return false;
  }

  // =====================================================================================

  Future<void> doNostrRequestWithRelaySet(
      RequestState state,
      {bool splitRequestsByPubKeyMappings = true}) async {
    if (state.unresolvedFilters.isEmpty || state.request.relaySet==null) {
      return;
    }
    // TODO support more than 1 filter
    RelaySet relaySet = state.request.relaySet!;
    Filter filter = state.unresolvedFilters.first;
    if (splitRequestsByPubKeyMappings) {
      relaySet.splitIntoRequests(filter, state);
      print(
          "request for ${filter.authors != null ? filter.authors!.length : 0} authors with kinds: ${filter.kinds} made requests to ${state.requests.length} relays");

      if (state.requests.isEmpty && relaySet.fallbackToBootstrapRelays) {
        print(
            "making fallback requests to ${relayManager.bootstrapRelays.length} bootstrap relays for ${filter.authors != null ? filter.authors!.length : 0} authors with kinds: ${filter.kinds}");
        for (var url in relayManager.bootstrapRelays) {
          state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
        }
      }
    } else {
      for (var url in relaySet.urls) {
        state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
      }
    }
    globalState.inFlightRequests[state.id] = state;
    Map<int?, int> kindsMap = {};
    globalState.inFlightRequests.forEach((key, request) {
      int? kind;
      if (request.requests.isNotEmpty &&
          request.requests.values.first.filters.first.kinds != null &&
          request.requests.values.first.filters.first.kinds!.isNotEmpty) {
        kind = request.requests.values.first.filters.first.kinds!.first;
      }
      int? count = kindsMap[kind];
      count ??= 0;
      count++;
      kindsMap[kind] = count;
    });
    print(
        "----------------NOSTR REQUESTS: ${globalState.inFlightRequests.length} || $kindsMap");
    for (MapEntry<String, RelayRequestState> entry
        in state.requests.entries) {
      doRelayRequest(state.id, entry.value);
    }
  }

  Future<NdkResponse> query(
      Filter filter,
      RelaySet? relaySet, {
      int idleTimeout = RelaySetsEngine.DEFAULT_STREAM_IDLE_TIMEOUT,
      bool splitRequestsByPubKeyMappings = true,
    }) async {
      RequestState state = RequestState(NdkRequest.query(
          Helpers.getRandomString(10),
          filters: [filter],
          relaySet: relaySet
      ));
    await _doQuery(state);
    return NdkResponse(state.id, state.stream);
  }

  Future<void> _doQuery(RequestState state) async{
    handleRequest(state);
    state.networkController.stream.listen((event) {
      state.controller.add(event);
    }, onDone: () {
      state.controller.close();
    }, onError:  (error) {
      Logger.log.e("⛔ $error ");
    });
  }

  Future<void> handleRequest(RequestState state) async {
    await relayManager.seedRelaysConnected;

    if (state.request.relaySet!=null) {
      return await doNostrRequestWithRelaySet(state);
    }
    if (state.request.relays!=null && state.request.relays!.isNotEmpty) {
      for (var url in state.request.relays!) {
        state.addRequest(
            url, RelaySet.sliceFilterAuthors(state.request.filters.first));
      }
    } else {
      for (var url in relayManager.relays.keys) {
        state.addRequest(
            url, RelaySet.sliceFilterAuthors(state.request.filters.first));
      }
    }
    globalState.inFlightRequests[state.id] = state;

    /**********************************************************/
    Map<int?, int> kindsMap = {};
    globalState.inFlightRequests.forEach((key, request) {
      int? kind;
      if (request.requests.isNotEmpty &&
          request.requests.values.first.filters.first.kinds != null &&
          request.requests.values.first.filters.first.kinds!.isNotEmpty) {
        kind = request.requests.values.first.filters.first.kinds!.first;
      }
      int? count = kindsMap[kind];
      count ??= 0;
      count++;
      kindsMap[kind] = count;
    });
    print(
        "----------------NOSTR REQUESTS: ${globalState.inFlightRequests.length} || $kindsMap");
    /**********************************************************/

    List<String> notSent = [];
    for (MapEntry<String, RelayRequestState> entry
        in state.requests.entries) {
      if (!doRelayRequest(state.id, entry.value)) {
        notSent.add(entry.key);
      }
    }
    for (var url in notSent) {
      state.requests.remove(url);
    }
  }

  Future<NdkResponse> requestRelays(Iterable<String> urls, Filter filter,
      {int timeout = DEFAULT_STREAM_IDLE_TIMEOUT,
      bool closeOnEOSE = true,
      Function()? onTimeout}) async {
    String id = Helpers.getRandomString(10);
    RequestState state = RequestState(closeOnEOSE
        ? NdkRequest.query(id, filters: [filter]) : NdkRequest.subscription(
            id, filters: [],
          ));

    for (var url in urls) {
      state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
    }
    globalState.inFlightRequests[state.id] = state;

    List<String> notSent = [];
    Map<int?, int> kindsMap = {};
    globalState.inFlightRequests.forEach((key, request) {
      int? kind;
      if (request.requests.isNotEmpty &&
          request.requests.values.first.filters.first.kinds != null &&
          request.requests.values.first.filters.first.kinds!.isNotEmpty) {
        kind = request.requests.values.first.filters.first.kinds!.first;
      }
      int? count = kindsMap[kind];
      count ??= 0;
      count++;
      kindsMap[kind] = count;
    });
    print(
        "----------------NOSTR REQUESTS: ${globalState.inFlightRequests.length} || $kindsMap");
    for (MapEntry<String, RelayRequestState> entry
        in state.requests.entries) {
      if (!doRelayRequest(state.id, entry.value)) {
        notSent.add(entry.key);
      }
    }
    for (var url in notSent) {
      state.requests.remove(url);
    }

    return NdkResponse(state.id, state.stream);
  }

  /// relay -> list of pubKey mappings
  Future<RelaySet> calculateRelaySet(
      {required String name,
      required String ownerPubKey,
      required List<String> pubKeys,
      required RelayDirection direction,
      required int relayMinCountPerPubKey,
      Function(String, int, int)? onProgress}) async {
    RelaySet byScore = await _relaysByPopularity(
        name: name,
        ownerPubKey: ownerPubKey,
        pubKeys: pubKeys,
        direction: direction,
        relayMinCountPerPubKey: relayMinCountPerPubKey,
        onProgress: onProgress);

    /// try by score
    if (byScore.relaysMap.isNotEmpty) {
      return byScore;
    }

    /// if everything fails just return a map of all currently registered connected relays for each pubKeys
    return RelaySet(
        name: name,
        pubKey: ownerPubKey,
        relayMinCountPerPubkey: relayMinCountPerPubKey,
        direction: direction,
        relaysMap: relayManager.allConnectedRelays(pubKeys),
        notCoveredPubkeys: []);
  }

  /// - get missing relay lists for pubKeys from nip65 or nip02 (todo nip05)
  /// - construct a map of relays and pubKeys that use it in some marker direction (write for outbox feed)
  /// - sort this map by descending amount of pubKeys per relay
  /// - starting from the top relay (biggest count of pubKeys) iterate down and:
  ///   - check if relay is connected or can connect
  ///   - for each pubKey mapped for given relay check if you already have minimum amount of relay coverage (use auxiliary map to remember this)
  ///     - if not add this relay to list of best relays
  Future<RelaySet> _relaysByPopularity(
      {required String name,
      required String ownerPubKey,
      required List<String> pubKeys,
      required RelayDirection direction,
      required int relayMinCountPerPubKey,
      Function(String stepName, int count, int total)? onProgress}) async {
    await loadMissingRelayListsFromNip65OrNip02(pubKeys,
        onProgress: onProgress);
    Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl =
        await _buildPubKeysMapFromRelayLists(pubKeys, direction);

    Map<String, Set<String>> minimumRelaysCoverageByPubkey = {};
    Map<String, List<PubkeyMapping>> bestRelays = {};
    if (onProgress != null) {
      Logger.log.d("Calculating best relays...");
      onProgress.call("Calculating best relays",
          minimumRelaysCoverageByPubkey.length, pubKeysByRelayUrl.length);
    }
    Map<String, int> notCoveredPubkeys = {};
    for (var pubKey in pubKeys) {
      notCoveredPubkeys[pubKey] = relayMinCountPerPubKey;
    }
    for (String url in pubKeysByRelayUrl.keys) {
      if (relayManager.blockedRelays.contains(cleanRelayUrl(url))) {
        continue;
      }
      if (!pubKeysByRelayUrl[url]!.any((pub_key) =>
          minimumRelaysCoverageByPubkey[pub_key.pubKey] == null ||
          minimumRelaysCoverageByPubkey[pub_key.pubKey]!.length <
              relayMinCountPerPubKey)) {
        continue;
      }
      bool connectable = await relayManager.reconnectRelay(url);
      Logger.log.d("tried to reconnect to $url = $connectable");
      if (!connectable) {
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
          // if (kDebugMode) {
          //   print("Adding $url to bestRelays since $pubKey was needed");
          // }
          bestRelays[url]!.add(pubKey);
          int count =
              notCoveredPubkeys[pubKey.pubKey] ?? relayMinCountPerPubKey;
          notCoveredPubkeys[pubKey.pubKey] = count - 1;
        }
      }
      if (onProgress != null) {
        // print(
        //     "Calculating best relays minimumRelaysCoverageByPubkey.length:${minimumRelaysCoverageByPubkey
        //         .length} pubKeysByRelayUrl.length: ${pubKeys.length}");
        onProgress.call("Calculating best relays",
            minimumRelaysCoverageByPubkey.length, pubKeys.length);
      }
    }

    notCoveredPubkeys.removeWhere((key, value) => value <= 0);

    return RelaySet(
        name: name,
        pubKey: ownerPubKey,
        relayMinCountPerPubkey: relayMinCountPerPubKey,
        direction: direction,
        relaysMap: bestRelays,
        notCoveredPubkeys: notCoveredPubkeys.entries
            .map(
              (entry) => NotCoveredPubKey(entry.key, entry.value),
            )
            .toList());
  }

  Future<void> loadMissingRelayListsFromNip65OrNip02(List<String> pubKeys,
      {Function(String stepName, int count, int total)? onProgress,
      bool forceRefresh = false}) async {
    List<String> missingPubKeys = [];
    for (var pubKey in pubKeys) {
      UserRelayList? userRelayList = cacheManager.loadUserRelayList(pubKey);
      if (userRelayList == null || forceRefresh) {
        // TODO check if not too old (time passed since last refreshed timestamp)
        missingPubKeys.add(pubKey);
      }
    }
    Map<String, UserRelayList> fromNip65s = {};
    Map<String, UserRelayList> fromNip02Contacts = {};
    Set<ContactList> contactLists = {};
    Set<String> found = {};

    if (missingPubKeys.isNotEmpty) {
      print("loading missing relay lists ${missingPubKeys.length}");
      if (onProgress != null) {
        onProgress.call(
            "loading missing relay lists", 0, missingPubKeys.length);
      }
      try {
        RequestState requestState = RequestState(NdkRequest.query(Helpers.getRandomString(10),
            filters: [
              Filter(
                  authors: missingPubKeys,
                  kinds: [Nip65.KIND, ContactList.KIND])
            ],
            timeout: missingPubKeys.length > 1 ? 10 : 3));

        await _doQuery(requestState);
        await for (final event in (requestState.stream)) {
          switch (event.kind) {
            case Nip65.KIND:
              Nip65 nip65 = Nip65.fromEvent(event);
              if (nip65.relays.isNotEmpty) {
                UserRelayList fromNip65 = UserRelayList.fromNip65(nip65);
                if (fromNip65s[event.pubKey] == null ||
                    fromNip65s[event.pubKey]!.createdAt < event.createdAt) {
                  fromNip65s[event.pubKey] = fromNip65;
                }
                if (onProgress != null) {
                  found.add(event.pubKey);
                  onProgress.call("loading missing relay lists", found.length,
                      missingPubKeys.length);
                }
              }
            case ContactList.KIND:
              ContactList contactList = ContactList.fromEvent(event);
              contactLists.add(contactList);
              if (event.content.isNotEmpty) {
                if (fromNip02Contacts[event.pubKey] == null ||
                    fromNip02Contacts[event.pubKey]!.createdAt <
                        event.createdAt) {
                  fromNip02Contacts[event.pubKey] =
                      UserRelayList.fromNip02EventContent(event);
                }
                if (onProgress != null) {
                  found.add(event.pubKey);
                  onProgress.call("loading missing relay lists", found.length,
                      missingPubKeys.length);
                }
              }
          }
        }
      } catch (e) {
        print(e);
      }
      Set<UserRelayList> relayLists = Set.of(fromNip65s.values);
      // Only add kind3 contents relays if there is no Nip65 for given pubKey.
      // This is because kind3 contents relay should be deprecated, and if we have a nip65 list should be considered more up-to-date.
      for (MapEntry<String, UserRelayList> entry in fromNip02Contacts.entries) {
        if (!fromNip65s.containsKey(entry.key)) {
          relayLists.add(entry.value);
        }
      }
      await cacheManager.saveUserRelayLists(relayLists.toList());

      // also save to cache any fresher contact list
      List<ContactList> contactListsSave = [];
      for (ContactList contactList in contactLists) {
        ContactList? existing =
            cacheManager.loadContactList(contactList.pubKey);
        if (existing == null || existing.createdAt < contactList.createdAt) {
          contactListsSave.add(contactList);
        }
      }
      await cacheManager.saveContactLists(contactListsSave);

      if (onProgress != null) {
        onProgress.call(
            "loading missing relay lists", found.length, missingPubKeys.length);
      }
    }
    print("Loaded ${found.length} relay lists");
  }

  _buildPubKeysMapFromRelayLists(
      List<String> pubKeys, RelayDirection direction) async {
    Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl = {};
    int foundCount = 0;
    for (String pubKey in pubKeys) {
      UserRelayList? userRelayList = cacheManager.loadUserRelayList(pubKey);
      if (userRelayList != null) {
        if (userRelayList.relays.isNotEmpty) {
          foundCount++;
        }
        for (var entry in userRelayList.relays.entries) {
          _handleRelayUrlForPubKey(
              pubKey, direction, entry.key, entry.value, pubKeysByRelayUrl);
        }
      } else {
        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await cacheManager.saveUserRelayList(UserRelayList(
            pubKey: pubKey,
            relays: {},
            createdAt: now,
            refreshedTimestamp: now));
      }
    }
    print(
        "Have lists of relays for $foundCount/${pubKeys.length} pubKeys ${foundCount < pubKeys.length ? "(missing ${pubKeys.length - foundCount})" : ""}");

    /// sort by pubKeys count for each relay descending
    List<MapEntry<String, Set<PubkeyMapping>>> sortedEntries =
        pubKeysByRelayUrl.entries.toList()

          /// todo: use more stuff to improve sorting
          ..sort((a, b) {
            int rr = b.value.length.compareTo(a.value.length);
            if (rr == 0) {
              // if amount of pubKeys is equal check for webSocket connected, and prioritize connected
              bool aC = relayManager.isWebSocketOpen(a.key);
              bool bC = relayManager.isWebSocketOpen(b.key);
              if (aC != bC) {
                return aC ? -1 : 1;
              }
              return 0;
            }
            return rr;
          });

    return Map<String, Set<PubkeyMapping>>.fromEntries(sortedEntries);
  }

  _handleRelayUrlForPubKey(
      String pubKey,
      RelayDirection direction,
      String url,
      ReadWriteMarker marker,
      Map<String, Set<PubkeyMapping>> pubKeysByRelayUrl) {
    String? cleanUrl = cleanRelayUrl(url);
    if (cleanUrl != null) {
      if (direction.matchesMarker(marker)) {
        Set<PubkeyMapping>? set = pubKeysByRelayUrl[cleanUrl];
        if (set == null) {
          pubKeysByRelayUrl[cleanUrl] = {};
        }
        pubKeysByRelayUrl[cleanUrl]!
            .add(PubkeyMapping(pubKey: pubKey, rwMarker: marker));
      }
    }
  }

  // Future<RequestResponse> requestRelays(List<String> list, Filter filter,
  //     {int? timeout}) async {
  //   RequestState state = RequestState(
  //       NdkRequest.query("-", filters: [filter], timeout: timeout));
  //   RequestResponse response = RequestResponse(state.stream);
  //   await _doQuery(state);
  //   return response;
  // }
}
