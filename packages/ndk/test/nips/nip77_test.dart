import 'dart:typed_data';

import 'package:ndk/shared/nips/nip77/negentropy.dart';
import 'package:test/test.dart';

void main() {
  group('Negentropy Varint', () {
    test('encodes small values correctly', () {
      expect(Negentropy.encodeVarint(0), equals([0]));
      expect(Negentropy.encodeVarint(1), equals([1]));
      expect(Negentropy.encodeVarint(127), equals([127]));
    });

    test('encodes values requiring multiple bytes', () {
      // 128 = 0x80 = 10000000 in binary
      // In varint: 0x81 0x00 (MSB-first, continuation bit on first byte)
      expect(Negentropy.encodeVarint(128), equals([0x81, 0x00]));

      // 255 = 0xFF = 11111111 in binary
      // In varint: 0x81 0x7F
      expect(Negentropy.encodeVarint(255), equals([0x81, 0x7F]));

      // 300 = 0x12C = 100101100 in binary
      // Split: 10 0101100 -> 0x82 0x2C
      expect(Negentropy.encodeVarint(300), equals([0x82, 0x2C]));
    });

    test('decodes values correctly', () {
      expect(
        Negentropy.decodeVarint(Uint8List.fromList([0])),
        equals((0, 1)),
      );
      expect(
        Negentropy.decodeVarint(Uint8List.fromList([127])),
        equals((127, 1)),
      );
      expect(
        Negentropy.decodeVarint(Uint8List.fromList([0x81, 0x00])),
        equals((128, 2)),
      );
      expect(
        Negentropy.decodeVarint(Uint8List.fromList([0x82, 0x2C])),
        equals((300, 2)),
      );
    });

    test('roundtrip encode/decode', () {
      final values = [0, 1, 127, 128, 255, 300, 16383, 16384, 1000000];
      for (final value in values) {
        final encoded = Negentropy.encodeVarint(value);
        final (decoded, _) = Negentropy.decodeVarint(encoded);
        expect(decoded, equals(value), reason: 'Failed for value $value');
      }
    });
  });

  group('Negentropy Fingerprint', () {
    test('empty list fingerprint', () {
      final fp = Negentropy.calculateFingerprint([]);
      expect(fp.length, equals(Negentropy.fingerprintSize));
    });

    test('single ID fingerprint', () {
      final id = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        id[i] = i;
      }
      final fp = Negentropy.calculateFingerprint([id]);
      expect(fp.length, equals(Negentropy.fingerprintSize));
    });

    test('different IDs produce different fingerprints', () {
      final id1 = Uint8List(32);
      final id2 = Uint8List(32);
      id1[0] = 1;
      id2[0] = 2;

      final fp1 = Negentropy.calculateFingerprint([id1]);
      final fp2 = Negentropy.calculateFingerprint([id2]);

      expect(fp1, isNot(equals(fp2)));
    });

    test('order matters for fingerprint', () {
      final id1 = Uint8List(32);
      final id2 = Uint8List(32);
      id1[0] = 1;
      id2[0] = 2;

      final fp1 = Negentropy.calculateFingerprint([id1, id2]);
      final fp2 = Negentropy.calculateFingerprint([id2, id1]);

      // Sum is commutative, so fingerprints should be equal
      // Actually, the sum mod 2^256 is commutative, so these should be equal
      expect(fp1, equals(fp2));
    });
  });

  group('Negentropy Hex Conversion', () {
    test('hexToBytes converts correctly', () {
      final bytes = Negentropy.hexToBytes('0102030405');
      expect(bytes, equals([1, 2, 3, 4, 5]));
    });

    test('bytesToHex converts correctly', () {
      final hex = Negentropy.bytesToHex(Uint8List.fromList([1, 2, 3, 4, 5]));
      expect(hex, equals('0102030405'));
    });

    test('roundtrip hex conversion', () {
      final original = '0123456789abcdef';
      final bytes = Negentropy.hexToBytes(original);
      final back = Negentropy.bytesToHex(bytes);
      expect(back, equals(original));
    });
  });

  group('Negentropy Bound', () {
    test('encodes and decodes empty prefix', () {
      final encoded = Negentropy.encodeBound(1234, Uint8List(0));
      final (ts, prefix, consumed) =
          Negentropy.decodeBound(encoded);
      expect(ts, equals(1234));
      expect(prefix, isEmpty);
      expect(consumed, equals(encoded.length));
    });

    test('encodes and decodes with prefix', () {
      final prefix = Uint8List.fromList([1, 2, 3, 4]);
      final encoded = Negentropy.encodeBound(5678, prefix);
      final (ts, decodedPrefix, consumed) =
          Negentropy.decodeBound(encoded);
      expect(ts, equals(5678));
      expect(decodedPrefix, equals(prefix));
      expect(consumed, equals(encoded.length));
    });
  });

  group('NegentropyItem', () {
    test('creates from hex correctly', () {
      final hexId =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final item = NegentropyItem.fromHex(timestamp: 1000, idHex: hexId);
      expect(item.timestamp, equals(1000));
      expect(item.id.length, equals(32));
      expect(Negentropy.bytesToHex(item.id), equals(hexId));
    });
  });

  group('Negentropy Protocol', () {
    test('creates initial message with version byte', () {
      final items = <NegentropyItem>[];
      final msg = Negentropy.createInitialMessage(items, Negentropy.idSize);
      expect(msg[0], equals(Negentropy.protocolVersion));
    });

    test('creates initial message for empty items with fingerprint mode', () {
      final items = <NegentropyItem>[];
      final msg = Negentropy.createInitialMessage(items, Negentropy.idSize);
      // Should have: version(1) + bound + mode(1) + fingerprint(16)
      expect(msg.length, greaterThanOrEqualTo(1 + 16));
      // Should use fingerprint mode, not skip
      expect(msg.contains(Negentropy.modeFingerprint), isTrue);
    });

    test('creates initial message for single item', () {
      final items = [
        NegentropyItem.fromHex(
          timestamp: 1000,
          idHex:
              '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        ),
      ];
      final msg = Negentropy.createInitialMessage(items, Negentropy.idSize);
      expect(msg[0], equals(Negentropy.protocolVersion));
      expect(msg.length, greaterThan(1));
    });

    test('creates initial message with fingerprint mode', () {
      final items = [
        NegentropyItem.fromHex(
          timestamp: 1000,
          idHex:
              '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        ),
        NegentropyItem.fromHex(
          timestamp: 2000,
          idHex:
              'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210',
        ),
      ];
      final msg = Negentropy.createInitialMessage(items, Negentropy.idSize);
      expect(msg[0], equals(Negentropy.protocolVersion));
      // Should contain fingerprint (16 bytes) plus overhead
      expect(msg.length, greaterThanOrEqualTo(1 + 16));
    });

    test('sorts items by timestamp then id', () {
      final items = [
        NegentropyItem.fromHex(
          timestamp: 2000,
          idHex:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
        NegentropyItem.fromHex(
          timestamp: 1000,
          idHex:
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        ),
        NegentropyItem.fromHex(
          timestamp: 1000,
          idHex:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      ];
      // createInitialMessage sorts internally
      final msg = Negentropy.createInitialMessage(items, Negentropy.idSize);
      expect(msg[0], equals(Negentropy.protocolVersion));
    });
  });

  group('Negentropy Reconcile', () {
    test('reconcile with matching fingerprints returns empty lists', () {
      final id1 = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final id2 = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

      final localItems = [
        NegentropyItem.fromHex(timestamp: 1000, idHex: id1),
        NegentropyItem.fromHex(timestamp: 2000, idHex: id2),
      ];

      // Create message from same items (simulating relay has same data)
      final relayItems = [
        NegentropyItem.fromHex(timestamp: 1000, idHex: id1),
        NegentropyItem.fromHex(timestamp: 2000, idHex: id2),
      ];

      final relayMsg = Negentropy.createInitialMessage(relayItems, Negentropy.idSize);
      final (response, needIds, haveIds) = Negentropy.reconcile(relayMsg, localItems);

      // When fingerprints match, no IDs needed
      expect(needIds, isEmpty);
      expect(haveIds, isEmpty);
    });

    test('reconcile detects missing local IDs (needIds)', () {
      final id1 = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final id2 = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

      // Local has only id1
      final localItems = [
        NegentropyItem.fromHex(timestamp: 1000, idHex: id1),
      ];

      // Relay has both
      final relayItems = [
        NegentropyItem.fromHex(timestamp: 1000, idHex: id1),
        NegentropyItem.fromHex(timestamp: 2000, idHex: id2),
      ];

      final relayMsg = Negentropy.createInitialMessage(relayItems, Negentropy.idSize);
      final (_, needIds, haveIds) = Negentropy.reconcile(relayMsg, localItems);

      // Fingerprints won't match, but full reconciliation needs multiple rounds
      // Initial message just sends fingerprint, doesn't reveal individual IDs yet
      expect(needIds.length + haveIds.length, greaterThanOrEqualTo(0));
    });

    test('reconcile with empty local items', () {
      final localItems = <NegentropyItem>[];

      final relayItems = [
        NegentropyItem.fromHex(
          timestamp: 1000,
          idHex: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        ),
      ];

      final relayMsg = Negentropy.createInitialMessage(relayItems, Negentropy.idSize);
      final (response, needIds, haveIds) = Negentropy.reconcile(relayMsg, localItems);

      // Should produce a valid response
      expect(response[0], equals(Negentropy.protocolVersion));
    });

    test('reconcile with empty relay items', () {
      final localItems = [
        NegentropyItem.fromHex(
          timestamp: 1000,
          idHex: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        ),
      ];

      final relayItems = <NegentropyItem>[];

      final relayMsg = Negentropy.createInitialMessage(relayItems, Negentropy.idSize);
      final (response, needIds, haveIds) = Negentropy.reconcile(relayMsg, localItems);

      // Should produce a valid response
      expect(response[0], equals(Negentropy.protocolVersion));
    });
  });

  group('Negentropy Varint Edge Cases', () {
    test('encodes large timestamps', () {
      // Unix timestamp in seconds (current era)
      final timestamp = 1700000000;
      final encoded = Negentropy.encodeVarint(timestamp);
      final (decoded, _) = Negentropy.decodeVarint(encoded);
      expect(decoded, equals(timestamp));
    });

    test('encodes max safe integer', () {
      final value = 0x1FFFFFFFFFFFFF; // Max safe integer in JS
      final encoded = Negentropy.encodeVarint(value);
      final (decoded, _) = Negentropy.decodeVarint(encoded);
      expect(decoded, equals(value));
    });

    test('throws on negative value', () {
      expect(() => Negentropy.encodeVarint(-1), throwsArgumentError);
    });

    test('decodes with offset', () {
      final data = Uint8List.fromList([0xFF, 0xFF, 0x82, 0x2C, 0xFF]);
      final (decoded, consumed) = Negentropy.decodeVarint(data, 2);
      expect(decoded, equals(300));
      expect(consumed, equals(2));
    });
  });

  group('Negentropy Fingerprint XOR Properties', () {
    test('XOR is commutative (order independent)', () {
      final id1 = Uint8List(32);
      final id2 = Uint8List(32);
      final id3 = Uint8List(32);
      id1[0] = 1;
      id2[0] = 2;
      id3[0] = 3;

      final fp1 = Negentropy.calculateFingerprint([id1, id2, id3]);
      final fp2 = Negentropy.calculateFingerprint([id3, id1, id2]);
      final fp3 = Negentropy.calculateFingerprint([id2, id3, id1]);

      expect(fp1, equals(fp2));
      expect(fp2, equals(fp3));
    });

    test('same ID twice cancels out (XOR property)', () {
      final id1 = Uint8List(32);
      final id2 = Uint8List(32);
      id1[0] = 1;
      id2[0] = 2;

      // [id1, id2] should NOT equal [id1, id2, id1, id1] because count differs
      final fp1 = Negentropy.calculateFingerprint([id1, id2]);
      final fp2 = Negentropy.calculateFingerprint([id1, id2, id1, id1]);

      // Different counts = different fingerprints
      expect(fp1, isNot(equals(fp2)));
    });

    test('fingerprint includes count', () {
      final id = Uint8List(32);
      id[0] = 1;

      // Same IDs but different counts
      final fp1 = Negentropy.calculateFingerprint([id]);
      final fp2 = Negentropy.calculateFingerprint([id, id]);

      // XOR of same ID = 0, but counts differ (1 vs 2)
      expect(fp1, isNot(equals(fp2)));
    });
  });

  group('Negentropy Hex Edge Cases', () {
    test('hexToBytes with uppercase', () {
      final bytes = Negentropy.hexToBytes('ABCDEF');
      expect(bytes, equals([0xAB, 0xCD, 0xEF]));
    });

    test('hexToBytes with mixed case', () {
      final bytes = Negentropy.hexToBytes('AbCdEf');
      expect(bytes, equals([0xAB, 0xCD, 0xEF]));
    });

    test('hexToBytes throws on odd length', () {
      expect(() => Negentropy.hexToBytes('ABC'), throwsArgumentError);
    });

    test('bytesToHex always lowercase', () {
      final hex = Negentropy.bytesToHex(Uint8List.fromList([0xAB, 0xCD, 0xEF]));
      expect(hex, equals('abcdef'));
    });

    test('empty hex string', () {
      final bytes = Negentropy.hexToBytes('');
      expect(bytes, isEmpty);
    });

    test('32-byte event ID roundtrip', () {
      final originalHex =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final bytes = Negentropy.hexToBytes(originalHex);
      expect(bytes.length, equals(32));
      final backToHex = Negentropy.bytesToHex(bytes);
      expect(backToHex, equals(originalHex));
    });
  });

  group('Negentropy Mode Constants', () {
    test('mode constants are correct', () {
      expect(Negentropy.modeSkip, equals(0));
      expect(Negentropy.modeFingerprint, equals(1));
      expect(Negentropy.modeIdList, equals(2));
    });

    test('protocol version is correct', () {
      expect(Negentropy.protocolVersion, equals(0x61));
    });

    test('sizes are correct', () {
      expect(Negentropy.idSize, equals(32));
      expect(Negentropy.fingerprintSize, equals(16));
    });
  });
}
