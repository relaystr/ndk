import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';

///
/// pubkeys: the list of pubkeys where you want relays to
/// direction: the read/write direction to rank for
/// eventData: this list should contain nip65 events as well as kind3 events and tagHint events
/// connectedRelays: the list of relays that are already connected (they will be ranked higher)
/// pubkeyCoverage: the minimum coverage for each pubkey
/// rankingConfig: if you want to modify, boost certain scores
///
RelayRankingResult rankRelays({
  required List<String> pubkeys,
  required ReadWriteMarker direction,
  required List<Nip01Event> eventData,
  List<Relay> connectedRelays = const [],
  int pubkeyCoverage = 2,
  RelayRankingScoringConfig rankingScoringConfig =
      const RelayRankingScoringConfig(),
}) {
  if (pubkeys.isEmpty) {
    throw ArgumentError('pubkeys cannot be empty');
  }

  if (pubkeyCoverage < 1) {
    throw ArgumentError('pubkeyCoverage cannot be less than 1');
  }

  if (eventData.isEmpty) {
    throw ArgumentError('eventData cannot be empty');
  }

  throw UnimplementedError();
}

class RelayRankingScoringConfig {
  final int connectedRelaysScore;
  final int nip65Score;
  final int nip05Score;
  final int kind03Score;
  final int lastFetchedScore;
  final int tagHintScore;

  const RelayRankingScoringConfig({
    this.connectedRelaysScore = 60,
    this.nip65Score = 50,
    this.nip05Score = 40,
    this.kind03Score = 30,
    this.lastFetchedScore = 20,
    this.tagHintScore = 10,
  });
}

class RelayRankingResult {
  final List<RelayRanking> ranking;
  final List<NotCoveredPubkey> notCoveredPubkeys;

  RelayRankingResult({
    required this.ranking,
    required this.notCoveredPubkeys,
  });
}

class NotCoveredPubkey {
  final String pubkey;
  final int missingCoverage;
  final int desiredCoverage;

  NotCoveredPubkey({
    required this.pubkey,
    required this.desiredCoverage,
    required this.missingCoverage,
  });
}

class RelayRanking {
  final Relay relay;
  final int score;
  final List<String> coveredPubkeys;
  final ReadWriteMarker direction;

  RelayRanking({
    required this.relay,
    required this.score,
    required this.coveredPubkeys,
    required this.direction,
  });
}
