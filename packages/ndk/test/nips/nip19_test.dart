import 'package:test/test.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

void main() {
  group('Nip19TLV', () {
    test('parseTLV should correctly parse valid TLV data', () {
      // Let's construct a simple TLV byte array for testing
      // Type 0, Length 2, Value [0x01, 0x02]
      // Type 1, Length 3, Value [0x03, 0x04, 0x05]
      final data = <int>[
        0, 2, 0x01, 0x02, // TLV 1
        1, 3, 0x03, 0x04, 0x05 // TLV 2
      ];

      final result = Nip19TLV.parseTLV(data);

      expect(result.length, 2);

      expect(result[0].type, 0);
      expect(result[0].length, 2);
      expect(result[0].value, [0x01, 0x02]);

      expect(result[1].type, 1);
      expect(result[1].length, 3);
      expect(result[1].value, [0x03, 0x04, 0x05]);
    });

    test('parseTLV should return empty list for empty data', () {
      final data = <int>[];
      final result = Nip19TLV.parseTLV(data);
      expect(result.isEmpty, true);
    });

    test('parseTLV should handle TLV with zero length value', () {
      // Type 0, Length 0, Value []
      final data = <int>[0, 0];
      final result = Nip19TLV.parseTLV(data);

      expect(result.length, 1);
      expect(result[0].type, 0);
      expect(result[0].length, 0);
      expect(result[0].value, []);
    });

    test('parseTLV should throw if data is incomplete (missing length)', () {
      final data = <int>[0]; // Type 0, but no length or value
      expect(() => Nip19TLV.parseTLV(data), throwsA(isA<FormatException>()));
    });

    test('parseTLV should throw if data is incomplete (missing value)', () {
      final data = <int>[0, 5]; // Type 0, Length 5, but no value
      expect(() => Nip19TLV.parseTLV(data), throwsA(isA<FormatException>()));
    });

    test('parseTLV should throw if length exceeds data bounds', () {
      final data = <int>[
        0,
        5,
        1,
        2
      ]; // Type 0, Length 5, but only 2 bytes of value
      expect(() => Nip19TLV.parseTLV(data), throwsA(isA<FormatException>()));
    });

    test('Nip19.decode for nprofile should return pubkey from TLV type 0', () {
      const nprofileBech32 =
          "nprofile1qqsrq7p2sv3m0jvtzuk952hhyp4ms2puv4d7dhwwzyfnvydq8403zacdqda04";
      const expectedPubkey =
          "30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177";

      final decodedPubkey = Nip19.decode(nprofileBech32);
      expect(decodedPubkey, expectedPubkey);
    });

    test('Nip19.decode for nevent should return event ID from TLV type 0', () {
      const neventBech32 =
          "nevent1qqs9z324hvhh98z9q5yrdlekh4cx446jeazxwd2d2hkehs48v72prts3w73r6";
      const expectedEventId =
          "514555bb2f729c45050836ff36bd706ad752cf4467354d55ed9bc2a7679411ae";

      final decodedEventId = Nip19.decode(neventBech32);
      expect(decodedEventId, expectedEventId);
    });
  });
}
