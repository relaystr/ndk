import 'package:dart_ndk/models/pubkey_mapping.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';

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
  int score;
  final List<PubkeyMapping> coveredPubkeys;

  // overwrite == operator
  @override
  bool operator ==(covariant RelayRanking other) {
    return relay == other.relay;
  }

  @override
  int get hashCode => relay.hashCode;

  RelayRanking({
    required this.relay,
    required this.score,
    required this.coveredPubkeys,
  });
}
