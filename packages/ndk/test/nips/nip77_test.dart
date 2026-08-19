import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ndk/shared/nips/nip77/negentropy.dart';
import 'package:test/test.dart';

Uint8List _id(int i) => Uint8List.fromList(sha256.convert([i]).bytes);

List<NegentropyItem> _items(
  int count, {
  int baseTimestamp = 1700000000,
  int step = 17,
}) =>
    [
      for (var i = 0; i < count; i++)
        NegentropyItem(timestamp: baseTimestamp + i * step, id: _id(i)),
    ];

/// Drives a full reconciliation to convergence and returns what the initiator
/// learned.
({List<String> needIds, List<String> haveIds, int rounds}) _syncToCompletion(
  List<NegentropyItem> initiator,
  List<NegentropyItem> responder, {
  int maxRounds = 50,
}) {
  final needIds = <String>[];
  final haveIds = <String>[];
  var message = NegentropyEncoder.createInitialMessage(initiator);

  for (var round = 1; round <= maxRounds; round++) {
    final response = NegentropyEncoder.respond(message, responder);
    if (response.length == 1) {
      return (needIds: needIds, haveIds: haveIds, rounds: round);
    }

    final (next, newNeed, newHave) = NegentropyEncoder.reconcile(
      response,
      initiator,
    );
    needIds.addAll(newNeed);
    haveIds.addAll(newHave);

    if (next.length == 1) {
      return (needIds: needIds, haveIds: haveIds, rounds: round);
    }
    message = next;
  }

  fail('reconciliation did not converge within $maxRounds rounds');
}

void main() {
  group('NegentropyEncoder Varint', () {
    test('encodes small values correctly', () {
      expect(NegentropyEncoder.encodeVarint(0), equals([0]));
      expect(NegentropyEncoder.encodeVarint(1), equals([1]));
      expect(NegentropyEncoder.encodeVarint(127), equals([127]));
    });

    test('encodes values requiring multiple bytes', () {
      // 128 = 0x80 = 10000000 in binary
      // In varint: 0x81 0x00 (MSB-first, continuation bit on first byte)
      expect(NegentropyEncoder.encodeVarint(128), equals([0x81, 0x00]));

      // 255 = 0xFF = 11111111 in binary
      // In varint: 0x81 0x7F
      expect(NegentropyEncoder.encodeVarint(255), equals([0x81, 0x7F]));

      // 300 = 0x12C = 100101100 in binary
      // Split: 10 0101100 -> 0x82 0x2C
      expect(NegentropyEncoder.encodeVarint(300), equals([0x82, 0x2C]));
    });

    test('decodes values correctly', () {
      expect(
        NegentropyEncoder.decodeVarint(Uint8List.fromList([0])),
        equals((0, 1)),
      );
      expect(
        NegentropyEncoder.decodeVarint(Uint8List.fromList([127])),
        equals((127, 1)),
      );
      expect(
        NegentropyEncoder.decodeVarint(Uint8List.fromList([0x81, 0x00])),
        equals((128, 2)),
      );
      expect(
        NegentropyEncoder.decodeVarint(Uint8List.fromList([0x82, 0x2C])),
        equals((300, 2)),
      );
    });

    test('roundtrip encode/decode', () {
      final values = [0, 1, 127, 128, 255, 300, 16383, 16384, 1000000];
      for (final value in values) {
        final encoded = NegentropyEncoder.encodeVarint(value);
        final (decoded, _) = NegentropyEncoder.decodeVarint(encoded);
        expect(decoded, equals(value), reason: 'Failed for value $value');
      }
    });

    test('throws on truncated varint', () {
      expect(
        () => NegentropyEncoder.decodeVarint(Uint8List.fromList([0x81])),
        throwsArgumentError,
      );
      expect(
        () => NegentropyEncoder.decodeVarint(Uint8List(0)),
        throwsArgumentError,
      );
    });

    test('throws when the varint exceeds the supported range', () {
      final tooBig = Uint8List.fromList([
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0x7F,
      ]);
      expect(() => NegentropyEncoder.decodeVarint(tooBig), throwsArgumentError);
    });
  });

  group('NegentropyEncoder Fingerprint', () {
    // Golden values from an independent implementation of the
    // Negentropy V1 fingerprint algorithm (sum of IDs mod 2^256 as
    // little-endian integers, concatenated with a varint count, SHA-256,
    // first 16 bytes). IDs are sha256([i]).
    test('matches the spec for known ID sets', () {
      final expected = {
        0: '7f9c9e31ac8256ca2f258583df262dbc',
        1: 'c7ff0bfd6010fdb4d1e3220933f1e183',
        3: 'c67390ff1b306527670a720b71c13133',
        8: 'a8c30ae01b85dbf46744d5eaafbd8229',
      };

      expected.forEach((count, hex) {
        final ids = [for (var i = 0; i < count; i++) _id(i)];
        expect(
          NegentropyEncoder.bytesToHex(
            NegentropyEncoder.calculateFingerprint(ids),
          ),
          equals(hex),
          reason: 'fingerprint of $count IDs',
        );
      });
    });

    test('empty list fingerprint', () {
      final fp = NegentropyEncoder.calculateFingerprint([]);
      expect(fp.length, equals(NegentropyEncoder.fingerprintSize));
    });

    test('single ID fingerprint', () {
      final id = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        id[i] = i;
      }
      final fp = NegentropyEncoder.calculateFingerprint([id]);
      expect(fp.length, equals(NegentropyEncoder.fingerprintSize));
    });

    test('different IDs produce different fingerprints', () {
      final id1 = Uint8List(32);
      final id2 = Uint8List(32);
      id1[0] = 1;
      id2[0] = 2;

      final fp1 = NegentropyEncoder.calculateFingerprint([id1]);
      final fp2 = NegentropyEncoder.calculateFingerprint([id2]);

      expect(fp1, isNot(equals(fp2)));
    });

    test('is order independent', () {
      final fp1 = NegentropyEncoder.calculateFingerprint([
        _id(0),
        _id(1),
        _id(2),
      ]);
      final fp2 = NegentropyEncoder.calculateFingerprint([
        _id(2),
        _id(0),
        _id(1),
      ]);
      final fp3 = NegentropyEncoder.calculateFingerprint([
        _id(1),
        _id(2),
        _id(0),
      ]);

      expect(fp1, equals(fp2));
      expect(fp2, equals(fp3));
    });

    test('carries between limbs of the 256 bit accumulator', () {
      final allOnes = Uint8List(32)..fillRange(0, 32, 0xFF);
      final one = Uint8List(32)..[0] = 1;

      // 2^256 - 1 + 1 wraps to zero, which is the accumulator of an empty
      // range, so only the element count separates the two fingerprints.
      final wrapped = NegentropyEncoder.calculateFingerprint([allOnes, one]);
      final zeroes = NegentropyEncoder.calculateFingerprint([
        Uint8List(32),
        Uint8List(32),
      ]);

      expect(wrapped, equals(zeroes));
    });

    test('fingerprint includes the element count', () {
      final id = Uint8List(32)..[0] = 1;

      final fp1 = NegentropyEncoder.calculateFingerprint([id]);
      final fp2 = NegentropyEncoder.calculateFingerprint([id, id]);

      expect(fp1, isNot(equals(fp2)));
    });
  });

  group('NegentropyEncoder Hex Conversion', () {
    test('hexToBytes converts correctly', () {
      final bytes = NegentropyEncoder.hexToBytes('0102030405');
      expect(bytes, equals([1, 2, 3, 4, 5]));
    });

    test('bytesToHex converts correctly', () {
      final hex = NegentropyEncoder.bytesToHex(
        Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      expect(hex, equals('0102030405'));
    });

    test('roundtrip hex conversion', () {
      final original = '0123456789abcdef';
      final bytes = NegentropyEncoder.hexToBytes(original);
      final back = NegentropyEncoder.bytesToHex(bytes);
      expect(back, equals(original));
    });
  });

  group('NegentropyEncoder Bound', () {
    test('encodes and decodes empty prefix', () {
      final encoded = NegentropyEncoder.encodeBound(1234, Uint8List(0));
      final (ts, prefix, consumed) = NegentropyEncoder.decodeBound(encoded);
      expect(ts, equals(1234));
      expect(prefix, isEmpty);
      expect(consumed, equals(encoded.length));
    });

    test('encodes and decodes with prefix', () {
      final prefix = Uint8List.fromList([1, 2, 3, 4]);
      final encoded = NegentropyEncoder.encodeBound(5678, prefix);
      final (ts, decodedPrefix, consumed) = NegentropyEncoder.decodeBound(
        encoded,
      );
      expect(ts, equals(5678));
      expect(decodedPrefix, equals(prefix));
      expect(consumed, equals(encoded.length));
    });

    test('delta encodes timestamps against the previous bound', () {
      // 1 + (1700000100 - 1700000000) == 101
      final encoded = NegentropyEncoder.encodeBound(
        1700000100,
        Uint8List(0),
        lastTimestamp: 1700000000,
      );
      expect(encoded, equals([101, 0]));

      final (ts, _, _) = NegentropyEncoder.decodeBound(encoded, 0, 1700000000);
      expect(ts, equals(1700000100));
    });

    test('encodes the infinity timestamp as zero', () {
      final encoded = NegentropyEncoder.encodeBound(
        NegentropyEncoder.infiniteTimestamp,
        Uint8List(0),
        lastTimestamp: 1700000000,
      );
      expect(encoded, equals([0, 0]));

      final (ts, _, _) = NegentropyEncoder.decodeBound(encoded, 0, 1700000000);
      expect(ts, equals(NegentropyEncoder.infiniteTimestamp));
    });

    test('rejects decreasing timestamps', () {
      expect(
        () => NegentropyEncoder.encodeBound(
          100,
          Uint8List(0),
          lastTimestamp: 200,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an over-long ID prefix', () {
      expect(
        () => NegentropyEncoder.encodeBound(1, Uint8List(33)),
        throwsArgumentError,
      );
      expect(
        () => NegentropyEncoder.decodeBound(
          Uint8List.fromList([2, 33, ...List.filled(33, 0)]),
        ),
        throwsArgumentError,
      );
    });
  });

  group('NegentropyItem', () {
    test('creates from hex correctly', () {
      final hexId =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final item = NegentropyItem.fromHex(timestamp: 1000, idHex: hexId);
      expect(item.timestamp, equals(1000));
      expect(item.id.length, equals(32));
      expect(NegentropyEncoder.bytesToHex(item.id), equals(hexId));
    });

    test('rejects IDs that are not 32 bytes', () {
      expect(
        () => NegentropyItem.fromHex(timestamp: 1000, idHex: 'aabb'),
        throwsArgumentError,
      );
    });
  });

  group('NegentropyEncoder wire format', () {
    // Golden messages produced by an independent implementation written
    // directly from the Negentropy Protocol V1 spec.
    test('initial message for an empty set is an empty ID list', () {
      final msg = NegentropyEncoder.createInitialMessage([]);
      expect(NegentropyEncoder.bytesToHex(msg), equals('6100000200'));
    });

    test('initial message for a small set is an ID list to infinity', () {
      final msg = NegentropyEncoder.createInitialMessage(_items(3));
      expect(
        NegentropyEncoder.bytesToHex(msg),
        equals(
          '610000020'
          '36e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d'
          '4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a'
          'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986',
        ),
      );
    });

    test('initial message for a large set is 16 fingerprint buckets', () {
      final msg = NegentropyEncoder.createInitialMessage(_items(40));
      expect(
        NegentropyEncoder.bytesToHex(msg),
        equals(
          '6186aacfe2340001c67390ff1b306527670a720b71c1313334000168e8aac011'
          '05aee8cbd5cef6d861d7853400017bdb8c88ea5c2575d64d4485c5f31d3b3400'
          '01e57703823294d3e1bfb1fd48ad02e7fa340001e466c5e561f2086830cb942e'
          '2012120e340001bcdad9758968b3e8858c463f277cd4e5340001abe26abb02d3'
          'f24122bdc508a9f01ce2340001305acbaa7248174e19fc580550fa6b38230001'
          'b5a057a5e1965d648738943acd9358162300011431730cce1783fa1dc714ffd0'
          '2b8bfa23000171b0f1f0f5efe008d9fd5520268ed05f230001650d16d7641d13'
          '18a09f3f69df601c66230001bcee68120de574cb63cdea05aa0073d223000105'
          'd71f04b1dbcda58cc3537b15242d3e230001681e53ebcdfd0c76e7a3e5ea3a8e'
          '993000000134fa1dc1e9052ea5984b6577a21e845e',
        ),
      );
    });

    test('uses minimal ID prefixes when timestamps collide', () {
      final items = [
        for (var i = 0; i < 40; i++)
          NegentropyItem(timestamp: 1700000000, id: _id(i)),
      ];
      final msg = NegentropyEncoder.createInitialMessage(items);
      expect(
        NegentropyEncoder.bytesToHex(msg),
        equals(
          '6186aacfe201011f01d3a291a13bdbbeb688fe4cc887490b0501012f013fa762'
          '0c1c5d8ea725f9108aeaf0e3e90101450178df7268a706b6e4c1c4a4b6f1fde7'
          'd501014d01332bd0d364a1fa4bbd02ebaa5cb67dcf010168015fe304b8584ee2'
          '855a6e920dbcf4749d01017c01c53c0157c33f9daf1c30c235a5675f8f01018f'
          '01eee7e11a36e2a542730dce9bcc18a71c01019d011b716da103785d9b2dfea6'
          '88dcff74850101bb0147f429640cd3b84a1fbd8c2250308b5d0101bd01b67cb5'
          '757a57df84ba13fb802c75dd380101c5017b717ab4b889d84ff3959ffea49912'
          'a60101db0184c7dac297950e8a907cd6d62efc4db60101e5011c5852a1e50dde'
          'c660884334b4d878840102e7cf0138175aae4678cc025c5e508d6c02868c0101'
          'f2013fa8bc22ac8d2b55f1fbec0f8ceb7991000001373a6e8fb77cfad502c265'
          '359d45e7e0',
        ),
      );
    });

    test('rejects an unknown protocol version', () {
      expect(
        () => NegentropyEncoder.reconcile(
          Uint8List.fromList([0x62, 0x00, 0x00, 0x02, 0x00]),
          [],
        ),
        throwsArgumentError,
      );
    });

    test('rejects an unknown mode', () {
      expect(
        () => NegentropyEncoder.reconcile(
          Uint8List.fromList([0x61, 0x00, 0x00, 0x07]),
          [],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a truncated ID list', () {
      expect(
        () => NegentropyEncoder.reconcile(
          Uint8List.fromList([0x61, 0x00, 0x00, 0x02, 0x02, 0xAA]),
          [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('NegentropyEncoder Reconcile', () {
    test('identical sets converge with nothing to exchange', () {
      final result = _syncToCompletion(_items(3), _items(3));
      expect(result.needIds, isEmpty);
      expect(result.haveIds, isEmpty);
    });

    test('reports IDs only the responder has as needIds', () {
      final result = _syncToCompletion(_items(1), _items(3));

      expect(result.haveIds, isEmpty);
      expect(
        result.needIds.toSet(),
        equals({
          NegentropyEncoder.bytesToHex(_id(1)),
          NegentropyEncoder.bytesToHex(_id(2)),
        }),
      );
    });

    test('reports IDs only the initiator has as haveIds', () {
      final result = _syncToCompletion(_items(3), _items(1));

      expect(result.needIds, isEmpty);
      expect(
        result.haveIds.toSet(),
        equals({
          NegentropyEncoder.bytesToHex(_id(1)),
          NegentropyEncoder.bytesToHex(_id(2)),
        }),
      );
    });

    test('empty initiator needs everything', () {
      final result = _syncToCompletion([], _items(5));
      expect(result.haveIds, isEmpty);
      expect(result.needIds, hasLength(5));
    });

    test('empty responder needs nothing back', () {
      final result = _syncToCompletion(_items(5), []);
      expect(result.needIds, isEmpty);
      expect(result.haveIds, hasLength(5));
    });

    // ndk#718: against a relay holding 53 of 236 cached events the answer is
    // 183 to send and 0 to fetch.
    test('large partially overlapping sets reconcile exactly', () {
      final local = _items(236);
      final remote = [for (var i = 0; i < 53; i++) local[i * 4]];

      final result = _syncToCompletion(local, remote);

      expect(result.needIds, isEmpty);
      expect(result.haveIds, hasLength(183));
      expect(
        result.haveIds.toSet(),
        equals(
          local
              .where((item) => !remote.contains(item))
              .map((item) => NegentropyEncoder.bytesToHex(item.id))
              .toSet(),
        ),
      );
    });

    test('sets differing at both ends reconcile exactly', () {
      final local = _items(50);
      final remote = [
        ..._items(50).skip(20),
        for (var i = 0; i < 10; i++)
          NegentropyItem(timestamp: 1800000000 + i, id: _id(200 + i)),
      ];

      final result = _syncToCompletion(local, remote);

      expect(result.needIds, hasLength(10));
      expect(result.haveIds, hasLength(20));
    });

    test('sets sharing a timestamp reconcile exactly', () {
      final local = [
        for (var i = 0; i < 60; i++)
          NegentropyItem(timestamp: 1700000000, id: _id(i)),
      ];
      final remote = [
        for (var i = 20; i < 80; i++)
          NegentropyItem(timestamp: 1700000000, id: _id(i)),
      ];

      final result = _syncToCompletion(local, remote);

      expect(result.haveIds, hasLength(20));
      expect(result.needIds, hasLength(20));
    });

    test('duplicate local items do not confuse reconciliation', () {
      final local = [..._items(5), ..._items(5)];
      final result = _syncToCompletion(local, _items(5));

      expect(result.needIds, isEmpty);
      expect(result.haveIds, isEmpty);
    });

    test('random set pairs reconcile exactly', () {
      final random = Random(0x77);

      for (var trial = 0; trial < 40; trial++) {
        final universe = [
          for (var i = 0; i < 250; i++)
            NegentropyItem(
              // A small timestamp spread guarantees collisions, which is what
              // exercises the ID-prefix bounds.
              timestamp: 1700000000 + random.nextInt(20),
              id: _id(i),
            ),
        ];

        final local = <NegentropyItem>[];
        final remote = <NegentropyItem>[];
        for (final item in universe) {
          if (random.nextInt(3) != 0) local.add(item);
          if (random.nextInt(3) != 0) remote.add(item);
        }

        final localIds =
            local.map((i) => i.id).map(NegentropyEncoder.bytesToHex);
        final remoteIds =
            remote.map((i) => i.id).map(NegentropyEncoder.bytesToHex);

        final result = _syncToCompletion(local, remote);

        expect(
          result.haveIds.toSet(),
          equals(localIds.toSet().difference(remoteIds.toSet())),
          reason: 'trial $trial haveIds',
        );
        expect(
          result.needIds.toSet(),
          equals(remoteIds.toSet().difference(localIds.toSet())),
          reason: 'trial $trial needIds',
        );
      }
    });

    test('a converged reconciliation returns only the version byte', () {
      final message = NegentropyEncoder.createInitialMessage(_items(3));
      final response = NegentropyEncoder.respond(message, _items(3));
      final (next, _, _) = NegentropyEncoder.reconcile(response, _items(3));

      expect(next, equals([NegentropyEncoder.protocolVersion]));
    });
  });

  group('NegentropyEncoder Varint Edge Cases', () {
    test('encodes large timestamps', () {
      // Unix timestamp in seconds (current era)
      final timestamp = 1700000000;
      final encoded = NegentropyEncoder.encodeVarint(timestamp);
      final (decoded, _) = NegentropyEncoder.decodeVarint(encoded);
      expect(decoded, equals(timestamp));
    });

    test('encodes max safe integer', () {
      final value = 0x1FFFFFFFFFFFFF; // Max safe integer in JS
      final encoded = NegentropyEncoder.encodeVarint(value);
      final (decoded, _) = NegentropyEncoder.decodeVarint(encoded);
      expect(decoded, equals(value));
    });

    test('throws on negative value', () {
      expect(() => NegentropyEncoder.encodeVarint(-1), throwsArgumentError);
    });

    test('decodes with offset', () {
      final data = Uint8List.fromList([0xFF, 0xFF, 0x82, 0x2C, 0xFF]);
      final (decoded, consumed) = NegentropyEncoder.decodeVarint(data, 2);
      expect(decoded, equals(300));
      expect(consumed, equals(2));
    });
  });

  group('NegentropyEncoder Hex Edge Cases', () {
    test('hexToBytes with uppercase', () {
      final bytes = NegentropyEncoder.hexToBytes('ABCDEF');
      expect(bytes, equals([0xAB, 0xCD, 0xEF]));
    });

    test('hexToBytes with mixed case', () {
      final bytes = NegentropyEncoder.hexToBytes('AbCdEf');
      expect(bytes, equals([0xAB, 0xCD, 0xEF]));
    });

    test('hexToBytes throws on odd length', () {
      expect(() => NegentropyEncoder.hexToBytes('ABC'), throwsArgumentError);
    });

    test('bytesToHex always lowercase', () {
      final hex = NegentropyEncoder.bytesToHex(
        Uint8List.fromList([0xAB, 0xCD, 0xEF]),
      );
      expect(hex, equals('abcdef'));
    });

    test('empty hex string', () {
      final bytes = NegentropyEncoder.hexToBytes('');
      expect(bytes, isEmpty);
    });

    test('32-byte event ID roundtrip', () {
      final originalHex =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final bytes = NegentropyEncoder.hexToBytes(originalHex);
      expect(bytes.length, equals(32));
      final backToHex = NegentropyEncoder.bytesToHex(bytes);
      expect(backToHex, equals(originalHex));
    });
  });

  group('NegentropyEncoder Mode Constants', () {
    test('mode constants are correct', () {
      expect(NegentropyEncoder.modeSkip, equals(0));
      expect(NegentropyEncoder.modeFingerprint, equals(1));
      expect(NegentropyEncoder.modeIdList, equals(2));
    });

    test('protocol version is correct', () {
      expect(NegentropyEncoder.protocolVersion, equals(0x61));
    });

    test('sizes are correct', () {
      expect(NegentropyEncoder.idSize, equals(32));
      expect(NegentropyEncoder.fingerprintSize, equals(16));
    });
  });
}
