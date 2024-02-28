import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';

import 'package:dart_ndk/relay_jit_manager/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';

RelayRankingResult rankRelays({
  required List<CoveragePubkey> searchingPubkeys,
  required ReadWriteMarker direction,
  required List<Nip65> eventData,
  // usually to boost already connected relays
  List<String> boostRelays = const [],
  // aka banned relays
  List<String> ignoreRelays = const [],
  // on found value
  int foundBoost = 1,
  // boost value
  int boost = 2,
  // ignore value
  int ignore = -2,
}) {
  // string is the relay url
  Map<String, TestRelayHit> relayHits = {};

  // count for each event data (pubkey)

  for (var event in eventData) {
    // not interested in this pubkey
    if (!searchingPubkeys.contains(event.pubKey)) {
      continue;
    }

    for (var relay in event.relays.keys) {
      if (ignoreRelays.contains(relay)) {
        continue;
      }
      // check for direction
      if (event.relays[relay] != direction) {
        continue;
      }

      // check if relay is already in relayHits
      if (!relayHits.containsKey(relay)) {
        relayHits[relay]!.hitPubkeys.add(event.pubKey);
        relayHits[relay]!.score += foundBoost;
      } else {
        relayHits[relay] = TestRelayHit(
          score: foundBoost,
          hitPubkeys: [event.pubKey],
        );
      }
    }
  }

  // boost already connected relays
  for (var relay in boostRelays) {
    if (relayHits.containsKey(relay)) {
      relayHits[relay]!.score += boost;
    }
  }

  // assemble result
  //todo:
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
