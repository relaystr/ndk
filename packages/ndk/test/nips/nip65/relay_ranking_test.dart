import 'dart:math';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/shared/nips/nip65/relay_ranking.dart';
import 'package:ndk/domain_layer/usecases/jit_engine/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('relayRanking', () {
    List<UserRelayList> nip65Data = [];
    List<CoveragePubkey> searchingPubkeys = [];

    // 0-9 have good nip65 data
    // 10-19 have no nip65 data
    // 20-29 have random nip65 data
    for (var i = 0; i < 30; i++) {
      searchingPubkeys.add(CoveragePubkey('pubkeyUser$i', 2, 2));
    }

    for (var i = 0; i < 10; i++) {
      final event = Nip01Event(
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: 'pubkeyUser$i',
        kind: Nip65.kKind,
        content: "",
        tags: [
          ['r', 'wss://relayA.read', 'read'],
          ['r', 'wss://relayB.write', 'write'],
          ['r', 'wss://relayC.readwrite'],
          ['invalid'],
        ],
      );
      final nip65 = Nip65.fromEvent(event);
      final userRelayList = UserRelayList.fromNip65(nip65);
      nip65Data.add(userRelayList);
    }

    // add random nip65 events
    for (var i = 20; i < 30; i++) {
      final event = Nip01Event(
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: 'pubkeyUser$i',
        kind: Nip65.kKind,
        content: "",
        tags: getRandomTags(),
      );
      final nip65 = Nip65.fromEvent(event);
      final userRelayList = UserRelayList.fromNip65(nip65);
      nip65Data.add(userRelayList);
    }

    test('basic scoring test - readOnly', () {
      final result = rankRelays(
        searchingPubkeys: searchingPubkeys,
        direction: ReadWriteMarker.readOnly,
        eventData: nip65Data,
      );

      expect(result.notCoveredPubkeys.length, greaterThanOrEqualTo(10));
      expect(result.ranking.length, greaterThanOrEqualTo(10));

      // check that covered pubkeys are in the result
      for (var i = 0; i < 10; i++) {
        int foundPubkey = 0;
        for (var element in result.ranking) {
          // Count how many times this pubkey appears in coveredPubkeys
          foundPubkey += element.coveredPubkeys
              .where((cp) => cp.pubkey == searchingPubkeys[i].pubkey)
              .length;
        }
        expect(foundPubkey, 2);
      }

      // check that the notCoveredPubkeys are the ones that have no data
      for (var i = 10; i < 20; i++) {
        bool foundInNotCovered = result.notCoveredPubkeys
            .any((cp) => cp.pubkey == searchingPubkeys[i].pubkey);
        expect(foundInNotCovered, true);
      }
    });
  });
}

final _random = Random();
String getRandomString(int length) => String.fromCharCodes(
    Iterable.generate(length, (_) => _random.nextInt(26) + 97));

String getRandomReadWrite() {
  final options = ['read', 'write', 'readwrite'];
  return options[_random.nextInt(options.length)];
}

getRandomTags() {
  final tags = [
    [
      'r',
      'wss://relay-${getRandomString(3)}.${getRandomReadWrite()}',
      getRandomReadWrite()
    ],
    [
      'r',
      'wss://relay-${getRandomString(3)}.${getRandomReadWrite()}',
      getRandomReadWrite()
    ],
    ['r', 'wss://relay-${getRandomString(3)}.${getRandomReadWrite()}'],
  ];
  return tags;
}
