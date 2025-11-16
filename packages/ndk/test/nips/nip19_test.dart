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

    test('Nip19.decodeNaddr should decode naddr correctly', () {
      const naddrBech32 =
          "naddr1qqxnzd3cx5urqv3nxymngdphqgsyvrp9u6p0mfur9dfdru3d853tx9mdjuhkphxuxgfwmryja7zsvhqrqsqqql8kavfpw3";
      const expectedIdentifier = '1685802317447';
      const expectedPubkey =
          '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c';
      const expectedKind = 31990;

      final decoded = Nip19.decodeNaddr(naddrBech32);

      expect(decoded.identifier, expectedIdentifier);
      expect(decoded.pubkey, expectedPubkey);
      expect(decoded.kind, expectedKind);
      expect(decoded.relays, null);
    });

    test('Nip19.decodeNevent should decode nevent with all fields', () {
      const neventBech32 =
          "nevent1qqs2ztln6vaff7jq34c7ys67vwp8qpj87rxncrqf64hv9nry65tykscppemhxue69uhkummn9ekx7mp0qgs8d3c64cayj8canmky0jap0c3fekjpzwsthdhx4cthd4my8c5u47srqsqqqqqpkmyhxk";
      const expectedEventId =
          'a12ff3d33a94fa408d71e2435e6382700647f0cd3c0c09d56ec2cc64d5164b43';
      const expectedAuthor =
          '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa';
      const expectedKind = 1;
      const expectedRelays = ['wss://nos.lol/'];

      final decoded = Nip19.decodeNevent(neventBech32);

      expect(decoded.eventId, expectedEventId);
      expect(decoded.author, expectedAuthor);
      expect(decoded.kind, expectedKind);
      expect(decoded.relays, expectedRelays);
    });

    test('Nip19.encodeNevent should encode nevent with all fields', () {
      const eventId =
          'a12ff3d33a94fa408d71e2435e6382700647f0cd3c0c09d56ec2cc64d5164b43';
      const author =
          '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa';
      const kind = 1;
      const relays = ['wss://nos.lol/'];

      final nevent = Nip19.encodeNevent(
        eventId: eventId,
        author: author,
        kind: kind,
        relays: relays,
      );

      expect(nevent.startsWith('nevent1'), true);

      // Verify round trip
      final decoded = Nip19.decodeNevent(nevent);
      expect(decoded.eventId, eventId);
      expect(decoded.author, author);
      expect(decoded.kind, kind);
      expect(decoded.relays, relays);
    });

    test('Nip19.decodeNprofile should decode nprofile correctly', () {
      const nprofileBech32 =
          "nprofile1qqsq2he9m8jnddkaalh8jsp7uv9sq5gpj304tuv08pynkw8wcqgfu8gd96anq";
      const expectedPubkey =
          "055f25d9e536b6ddefee79403ee30b005101945f55f18f38493b38eec0109e1d";

      final decoded = Nip19.decodeNprofile(nprofileBech32);

      expect(decoded.pubkey, expectedPubkey);
      // Relays may or may not be present
    });

    test('Nip19.encodeNprofile should encode nprofile and round trip', () {
      const pubkey =
          '30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177';
      const relays = ['wss://relay.example.com', 'wss://relay2.example.com'];

      final nprofile = Nip19.encodeNprofile(
        pubkey: pubkey,
        relays: relays,
      );

      expect(nprofile.startsWith('nprofile1'), true);

      // Verify round trip
      final decoded = Nip19.decodeNprofile(nprofile);
      expect(decoded.pubkey, pubkey);
      expect(decoded.relays, relays);
    });
  });
}
