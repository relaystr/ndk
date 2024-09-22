import '../../../shared/helpers/relay_helper.dart';
import '../../../shared/logger/logger.dart';
import '../../entities/pubkey_mapping.dart';
import '../../entities/read_write.dart';
import '../../entities/read_write_marker.dart';
import '../../entities/relay_set.dart';
import '../../entities/user_relay_list.dart';
import '../../repositories/cache_manager.dart';
import '../relay_manager.dart';
import '../requests/requests.dart';
import '../user_relay_lists/user_relay_lists.dart';

class RelaySets {
  Requests requests;
  CacheManager cacheManager;
  RelayManager relayManager;
  UserRelayLists userRelayLists;

  RelaySets({
    required this.requests,
    required this.cacheManager,
    required this.relayManager,
    required this.userRelayLists,
  });

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
    await userRelayLists.loadMissingRelayListsFromNip65OrNip02(pubKeys,
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
      if (!pubKeysByRelayUrl[url]!.any((pubKey) =>
          minimumRelaysCoverageByPubkey[pubKey.pubKey] == null ||
          minimumRelaysCoverageByPubkey[pubKey.pubKey]!.length <
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
}
