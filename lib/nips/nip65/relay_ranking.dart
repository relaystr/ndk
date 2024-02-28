import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';

import 'package:dart_ndk/relay_jit_manager/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';

RelayRankingResult rankRelays({
  required List<CoveragePubkey> pubkeys,
  required ReadWriteMarker direction,
  required List<Nip65> eventData,
  // usually to boost already connected relays
  List<String> boostRelays = const [],
  // aka banned relays
  List<String> ignoreRelays = const [],
}) {}

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
