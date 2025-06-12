import '../../../domain_layer/entities/read_write_marker.dart';
import '../../../domain_layer/entities/user_relay_list.dart';
import '../../../domain_layer/usecases/jit_engine/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';

/// relay ranking
RelayRankingResult rankRelays({
  required List<CoveragePubkey> searchingPubkeys,
  required ReadWriteMarker direction,
  required List<UserRelayList> eventData,
  // usually to boost already connected relays
  List<String> boostRelays = const [],
  // aka banned relays
  List<String> ignoreRelays = const [],
  // on found value
  int foundBoost = 1,
  // boost value
  int boost = 10,
}) {
  // string is the relay url
  Map<String, TestRelayHit> relayHits = {};

  // string is the pubkey
  Map<String, CoveragePubkey> searchingPubkeysMap = {
    for (final e in searchingPubkeys) e.pubkey: e,
  };

  // track which pubkey-relay combinations already processed
  Set<String> processedCombinations = {};

  // count for each event data (pubkey)
  for (final event in eventData) {
    // not interested in this pubkey
    if (searchingPubkeys.any((element) => element.pubkey == event.pubKey) ==
        false) {
      continue;
    }

    for (final relay in event.relays.keys) {
      if (ignoreRelays.contains(relay)) {
        continue;
      }
      // check for direction
      if (!event.relays[relay]!.isPartialMatch(direction)) {
        continue;
      }

      // create unique key for this pubkey-relay combination
      String combinationKey = "${event.pubKey}:$relay";

      // skip if we've already processed this combination
      if (processedCombinations.contains(combinationKey)) {
        continue;
      }

      // check if a new relay is needed
      if (searchingPubkeysMap[event.pubKey]!.missingCoverage <= 0) {
        continue;
      }

      // Mark this combination as processed
      processedCombinations.add(combinationKey);

      // check if relay is already in relayHits
      if (relayHits.containsKey(relay)) {
        relayHits[relay]!.hitPubkeys.add(event.pubKey);
        relayHits[relay]!.score += foundBoost;
      } else {
        relayHits[relay] = TestRelayHit(
          score: foundBoost,
          hitPubkeys: [event.pubKey],
        );
      }
      // decrease missing coverage
      searchingPubkeysMap[event.pubKey]!.missingCoverage -= 1;
    }
  }

  // boost already connected relays
  for (final relay in boostRelays) {
    if (relayHits.containsKey(relay)) {
      relayHits[relay]!.score += boost;
    }
  }

  // assemble result
  List<RelayRanking> ranking = [];
  List<CoveragePubkey> notCoveredPubkeys = [];

  // not covered pubkeys
  for (final pubkey in searchingPubkeysMap.entries) {
    if (pubkey.value.missingCoverage > 0) {
      notCoveredPubkeys.add(pubkey.value);
    }
  }

  // populate ranking
  for (final relayHit in relayHits.entries) {
    if (relayHit.value.score > 0) {
      ranking.add(
        RelayRanking(
          relayUrl: relayHit.key,
          score: relayHit.value.score,
          coveredPubkeys: searchingPubkeys
              .where((element) =>
                  relayHit.value.hitPubkeys.contains(element.pubkey))
              .toList(),
        ),
      );
    }
  }

  return RelayRankingResult(
    ranking: ranking,
    notCoveredPubkeys: notCoveredPubkeys,
  );
}

class TestRelayHit {
  int score = 0;
  List<String> hitPubkeys = [];
  TestRelayHit({required this.score, required this.hitPubkeys});
}

class RelayRankingResult {
  final List<RelayRanking> ranking;
  final List<CoveragePubkey> notCoveredPubkeys;

  RelayRankingResult({
    required this.ranking,
    required this.notCoveredPubkeys,
  });
}

class RelayRanking {
  final String relayUrl;
  int score;
  final List<CoveragePubkey> coveredPubkeys;

  RelayRanking({
    required this.relayUrl,
    required this.score,
    required this.coveredPubkeys,
  });
}
