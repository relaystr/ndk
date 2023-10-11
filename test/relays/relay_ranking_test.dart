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

  group('relay ranking basic tests', () {
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

    test('results contain covered pubkeys', () async {
      final pubkeys = ['alice', 'bob', 'carol'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.readOnly,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
      );

      final example1 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example1.com';
      });
      final example2 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example2.com';
      });
      final example3 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example3.com';
      });

      expect(example1.coveredPubkeys, contains('alice'));
      expect(example1.coveredPubkeys, contains('alice'));

      expect(example2.coveredPubkeys, contains('bob'));
      expect(example3.coveredPubkeys, contains('bob'));

      expect(example3.coveredPubkeys, contains('carol'));
    });
  });

  group('read write direction', () {
    test('write only', () async {
      final pubkeys = ['alice', 'bob', 'carol'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.writeOnly,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
      );

      // check that all directions are write
      result.ranking.forEach((element) {
        expect(element.direction, equals(ReadWriteMarker.writeOnly));
      });
    });

    test('read only', () async {
      final pubkeys = ['alice', 'bob', 'carol'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.readOnly,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
      );

      // check that all directions are write
      result.ranking.forEach((element) {
        expect(element.direction, equals(ReadWriteMarker.readOnly));
      });
    });

    test('read/write', () async {
      final pubkeys = ['alice', 'bob', 'carol'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.readWrite,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
      );

      // check that all directions are write
      result.ranking.forEach((element) {
        expect(element.direction, equals(ReadWriteMarker.readWrite));
      });
    });
  });

  group('exceptions', () {
    test('empty pubkeys', () async {
      expect(
        () => rankRelays(
          pubkeys: [],
          direction: ReadWriteMarker.readWrite,
          eventData: exampleEventData,
          connectedRelays: [],
          pubkeyCoverage: 2,
        ),
        throwsA(Exception),
      );
    });
    test('empty event data', () async {
      expect(
        () => rankRelays(
          pubkeys: ["something"],
          direction: ReadWriteMarker.readWrite,
          eventData: [],
          connectedRelays: [],
          pubkeyCoverage: 2,
        ),
        throwsA(Exception),
      );
    });
    test('coverage < 1', () async {
      expect(
        () => rankRelays(
          pubkeys: ["something"],
          direction: ReadWriteMarker.readWrite,
          eventData: exampleEventData,
          connectedRelays: [],
          pubkeyCoverage: 0,
        ),
        throwsA(Exception),
      );
    });
  });

  group('scoring', () {
    test('consistency', () async {
      final pubkeys = ['alice', 'bob', 'carol', 'dave'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.readOnly,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
        rankingScoringConfig: const RelayRankingScoringConfig(),
      );

      final example1 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example1.com';
      });
      final example2 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example2.com';
      });
      final example3 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example3.com';
      });
      final example5 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example5.com';
      });

      expect(example2.score, equals(example3.score));
      expect(example1.score, equals(example5.score));
      expect(example1.score, lessThan(example2.score));
    });
  });

  group('scoring', () {
    test('consistency', () async {
      final pubkeys = ['alice', 'bob', 'carol', 'dave'];
      final result = rankRelays(
        pubkeys: pubkeys,
        direction: ReadWriteMarker.readOnly,
        eventData: exampleEventData,
        connectedRelays: [],
        pubkeyCoverage: 2,
        rankingScoringConfig: const RelayRankingScoringConfig(),
      );

      final example1 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example1.com';
      });
      final example2 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example2.com';
      });
      final example3 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example3.com';
      });
      final example5 = result.ranking.firstWhere((element) {
        return element.relay.url == 'wss://example5.com';
      });

      expect(example2.score, equals(example3.score));
      expect(example1.score, equals(example5.score));
      expect(example1.score, lessThan(example2.score));
    });
  });
}
