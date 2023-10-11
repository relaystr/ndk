import 'dart:js_util';
import 'dart:math';

import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<Nip01Event> exampleEventData = [
    Nip01Event(
        pubKey: "alice",
        kind: Nip65.kind,
        tags: [
          ["r", "wss://example1.com"],
          ["r", "wss://example2.com"],
          ["r", "wss://alice.example.com", "write"],
        ],
        content: ""),
    Nip01Event(
        pubKey: "bob",
        kind: Nip65.kind,
        tags: [
          ["r", "wss://example2.com"],
          ["r", "wss://example3.com"],
          ["r", "wss://bob.example.com", "write"],
        ],
        content: ""),
    Nip01Event(
        pubKey: "carol",
        kind: Nip65.kind,
        tags: [
          ["r", "wss://example3.com"],
          ["r", "wss://example4.com"],
          ["r", "wss://carol.example.com", "write"],
        ],
        content: ""),
    Nip01Event(
        pubKey: "dave",
        kind: Nip65.kind,
        tags: [
          ["r", "wss://example4.com"],
          ["r", "wss://example5.com"],
          ["r", "wss://dave.example.com", "write"],
        ],
        content: ""),
    Nip01Event(
        pubKey: "singleRelay",
        kind: Nip65.kind,
        tags: [
          ["r", "wss://singleRelay.example"],
        ],
        content: ""),
  ];

  group('Relay Ranking', () {
    test('Rank relays with empty connectedRelays list', () async {
      final pubkeys = ['alice', 'bob', 'carol'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.readOnly,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
        rankingScoringConfig: RelayRankingScoringConfig(),
      );

      expect(result, isA<RelayRankingResult>());
      expect(result.ranking, isNotEmpty);
      expect(result.notCoveredPubkeys, isEmpty);
      expect(result.ranking.length, equals(5));
    });

    test('not covered pubkeys', () async {
      final pubkeys = ['alice', 'bob', 'carol', 'unknown'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.readOnly,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
        rankingScoringConfig: RelayRankingScoringConfig(),
      );
      expect(result.notCoveredPubkeys.length, equals(1));
      expect(result.notCoveredPubkeys[0].pubkey, equals('unknown'));
      expect(result.notCoveredPubkeys[0].desiredCoverage, equals(2));
    });

    test('partial coverage', () async {
      final pubkeys = ['singleRelay'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.readOnly,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
      );

      expect(result.notCoveredPubkeys.length, equals(1));
      expect(result.notCoveredPubkeys[0].desiredCoverage, equals(2));
      expect(result.notCoveredPubkeys[0].missingCoverage, equals(1));
    });
  });
}
