import '../../../domain_layer/entities/read_write_marker.dart';
import '../../../domain_layer/entities/user_relay_list.dart';
import '../../../domain_layer/usecases/jit_engine/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';

/// relay ranking
RelayRankingResult rankRelays({
  required List<CoveragePubkey> searchingPubkeys,
  required ReadWriteMarker direction,
  required List<UserRelayList> eventData,
  List<String> boostRelays = const [],
  List<String> ignoreRelays = const [],
  int foundBoost = 1,
  int boost = 10,
}) {
  // create a map of relay -> set of pubkeys it covers
  Map<String, Set<String>> relayCoverage = {};

  // build coverage map based on direction (read/write)
  for (final userRelay in eventData) {
    Iterable<String> relevantUrls;
    if (direction.isRead) {
      relevantUrls = userRelay.readUrls;
    } else {
      relevantUrls = userRelay.urls
          .where((url) => userRelay.relays[url]?.isWrite ?? false);
    }

    for (final relayUrl in relevantUrls) {
      if (ignoreRelays.contains(relayUrl)) continue;

      relayCoverage.putIfAbsent(relayUrl, () => <String>{});
      relayCoverage[relayUrl]!.add(userRelay.pubKey);
    }
  }

  // track coverage needed for each pubkey
  Map<String, int> remainingCoverage = {};
  for (final cp in searchingPubkeys) {
    remainingCoverage[cp.pubkey] = cp.desiredCoverage;
  }

  List<RelayRanking> selectedRelays = [];

  // greedy algorithm to find minimal set
  while (remainingCoverage.values.any((coverage) => coverage > 0)) {
    String? bestRelay;
    int bestScore = 0;
    Set<String> bestCoveredPubkeys = {};

    // find relay that covers the most uncovered pubkeys
    for (final relayUrl in relayCoverage.keys) {
      Set<String> coveredPubkeys = {};
      int score = 0;

      for (final pubkey in relayCoverage[relayUrl]!) {
        if ((remainingCoverage[pubkey] ?? 0) > 0) {
          coveredPubkeys.add(pubkey);
          score += 1;

          // apply boost if this relay is in boost list
          if (boostRelays.contains(relayUrl)) {
            score += boost;
          }
        }
      }

      // apply found boost for relays already selected
      if (selectedRelays.any((r) => r.relayUrl == relayUrl)) {
        score += foundBoost;
      }

      if (score > bestScore) {
        bestScore = score;
        bestRelay = relayUrl;
        bestCoveredPubkeys = coveredPubkeys;
      }
    }

    // if no relay can improve coverage, break
    if (bestRelay == null || bestScore == 0) break;

    // add the best relay to selection
    List<CoveragePubkey> coveredPubkeyObjects = [];
    for (final pubkey in bestCoveredPubkeys) {
      if ((remainingCoverage[pubkey] ?? 0) > 0) {
        coveredPubkeyObjects.add(
            CoveragePubkey(pubkey, 1, 0) // This relay covers this pubkey once
            );
        remainingCoverage[pubkey] = remainingCoverage[pubkey]! - 1;
      }
    }

    // check if this relay is already selected, if so update it
    int existingIndex =
        selectedRelays.indexWhere((r) => r.relayUrl == bestRelay);
    if (existingIndex != -1) {
      selectedRelays[existingIndex].score += bestScore;
      selectedRelays[existingIndex].coveredPubkeys.addAll(coveredPubkeyObjects);
    } else {
      selectedRelays.add(RelayRanking(
        relayUrl: bestRelay,
        score: bestScore,
        coveredPubkeys: coveredPubkeyObjects,
      ));
    }

    // remove this relay from future consideration for this iteration
    relayCoverage.remove(bestRelay);
  }

  // find pubkeys that couldn't be fully covered
  List<CoveragePubkey> notCoveredPubkeys = [];
  for (final cp in searchingPubkeys) {
    int remaining = remainingCoverage[cp.pubkey] ?? 0;
    if (remaining > 0) {
      notCoveredPubkeys
          .add(CoveragePubkey(cp.pubkey, cp.desiredCoverage, remaining));
    }
  }

  // sort relays by score
  selectedRelays.sort((a, b) => b.score.compareTo(a.score));

  return RelayRankingResult(
    ranking: selectedRelays,
    notCoveredPubkeys: notCoveredPubkeys,
  );
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
