import 'dart:convert';
import 'package:test/test.dart';
import 'package:bech32/bech32.dart';
import 'package:hex/hex.dart';
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

    test('Nip19.encodeNoteId should encode note ID correctly', () {
      const noteId =
          'a12ff3d33a94fa408d71e2435e6382700647f0cd3c0c09d56ec2cc64d5164b43';

      final encoded = Nip19.encodeNoteId(noteId);

      expect(encoded.startsWith('note1'), true);

      // Verify we can decode it back
      final decoded = Nip19.decode(encoded);
      expect(decoded, noteId);
    });

    group('toString methods', () {
      test('Naddr.toString should return formatted string', () {
        final naddr = Naddr(
          identifier: 'test-id',
          pubkey:
              '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c',
          kind: 30023,
          relays: ['wss://relay.example.com'],
        );

        final str = naddr.toString();
        expect(str.contains('test-id'), true);
        expect(
            str.contains(
                '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c'),
            true);
        expect(str.contains('30023'), true);
        expect(str.contains('wss://relay.example.com'), true);
      });

      test('Nevent.toString should return formatted string', () {
        final nevent = Nevent(
          eventId:
              'a12ff3d33a94fa408d71e2435e6382700647f0cd3c0c09d56ec2cc64d5164b43',
          author:
              '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa',
          kind: 1,
          relays: ['wss://nos.lol/'],
        );

        final str = nevent.toString();
        expect(
            str.contains(
                'a12ff3d33a94fa408d71e2435e6382700647f0cd3c0c09d56ec2cc64d5164b43'),
            true);
        expect(
            str.contains(
                '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa'),
            true);
        expect(str.contains('1'), true);
        expect(str.contains('wss://nos.lol/'), true);
      });

      test('Nprofile.toString should return formatted string', () {
        final nprofile = Nprofile(
          pubkey:
              '30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177',
          relays: ['wss://relay.example.com'],
        );

        final str = nprofile.toString();
        expect(
            str.contains(
                '30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177'),
            true);
        expect(str.contains('wss://relay.example.com'), true);
      });
    });

    group('validation errors', () {
      test('encodeNevent should throw on invalid event ID length', () {
        // Use valid hex but wrong length (30 bytes instead of 32)
        expect(
          () => Nip19.encodeNevent(
              eventId:
                  'a12ff3d33a94fa408d71e2435e6382700647f0cd3c0c09d56ec2cc64d516'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('encodeNevent should throw on relay URL too long', () {
        final longRelay = 'wss://${'a' * 300}.com';
        expect(
          () => Nip19.encodeNevent(
            eventId:
                'a12ff3d33a94fa408d71e2435e6382700647f0cd3c0c09d56ec2cc64d5164b43',
            relays: [longRelay],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('encodeNevent should throw on invalid author length', () {
        // Use valid hex but wrong length (30 bytes instead of 32)
        expect(
          () => Nip19.encodeNevent(
            eventId:
                'a12ff3d33a94fa408d71e2435e6382700647f0cd3c0c09d56ec2cc64d5164b43',
            author:
                '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('encodeNaddr should throw on invalid pubkey length', () {
        // Use valid hex but wrong length (30 bytes instead of 32)
        expect(
          () => Nip19.encodeNaddr(
            identifier: 'test',
            pubkey:
                '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85',
            kind: 30023,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('encodeNaddr should throw on relay URL too long', () {
        final longRelay = 'wss://${'a' * 300}.com';
        expect(
          () => Nip19.encodeNaddr(
            identifier: 'test',
            pubkey:
                '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c',
            kind: 30023,
            relays: [longRelay],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('encodeNprofile should throw on invalid pubkey length', () {
        // Use valid hex but wrong length (30 bytes instead of 32)
        expect(
          () => Nip19.encodeNprofile(
              pubkey:
                  '30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('encodeNprofile should throw on relay URL too long', () {
        final longRelay = 'wss://${'a' * 300}.com';
        expect(
          () => Nip19.encodeNprofile(
            pubkey:
                '30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177',
            relays: [longRelay],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('decodeNaddr should throw on missing identifier', () {
        // Create naddr with pubkey (type 2) and kind (type 3) but NO identifier (type 0)
        final pubkeyBytes = HEX.decode(
            '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c');
        final tlvData = <int>[
          2, 32, // type 2 (pubkey), length 32
          ...pubkeyBytes, // pubkey value
          3, 4, // type 3 (kind), length 4
          0, 0, 0x75, 0x17, // kind 30023 in big-endian
        ];
        final bech32Data = Nip19.convertBits(tlvData, 8, 5, true);
        final encoder = Bech32Encoder();
        final naddr = encoder.convert(
          Bech32('naddr', bech32Data),
          'naddr'.length + bech32Data.length + 10,
        );

        expect(
          () => Nip19.decodeNaddr(naddr),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('decodeNprofile should throw on invalid HRP', () {
        // Try to decode an nevent as nprofile
        const neventBech32 =
            "nevent1qqs9z324hvhh98z9q5yrdlekh4cx446jeazxwd2d2hkehs48v72prts3w73r6";
        expect(
          () => Nip19.decodeNprofile(neventBech32),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('decodeNevent should throw on invalid HRP', () {
        // Try to decode an nprofile as nevent
        const nprofileBech32 =
            "nprofile1qqsrq7p2sv3m0jvtzuk952hhyp4ms2puv4d7dhwwzyfnvydq8403zacdqda04";
        expect(
          () => Nip19.decodeNevent(nprofileBech32),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('decodeNaddr should throw on invalid HRP', () {
        // Try to decode an nevent as naddr
        const neventBech32 =
            "nevent1qqs9z324hvhh98z9q5yrdlekh4cx446jeazxwd2d2hkehs48v72prts3w73r6";
        expect(
          () => Nip19.decodeNaddr(neventBech32),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('decode validation - missing required fields', () {
      test('decodeNprofile should throw on missing pubkey field', () {
        // Create a valid nprofile with only a relay (type 1), no pubkey (type 0)
        final relayUrl = 'wss://relay.com';
        final tlvData = <int>[
          1, relayUrl.length, // type 1, length
          ...utf8.encode(relayUrl), // relay URL
        ];
        final bech32Data = Nip19.convertBits(tlvData, 8, 5, true);
        final encoder = Bech32Encoder();
        final nprofile = encoder.convert(
          Bech32('nprofile', bech32Data),
          'nprofile'.length + bech32Data.length + 10,
        );

        expect(
          () => Nip19.decodeNprofile(nprofile),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('decodeNevent should throw on missing event ID field', () {
        // Create a valid nevent with only a relay (type 1), no event ID (type 0)
        final relayUrl = 'wss://relay.com';
        final tlvData = <int>[
          1, relayUrl.length, // type 1, length
          ...utf8.encode(relayUrl), // relay URL
        ];
        final bech32Data = Nip19.convertBits(tlvData, 8, 5, true);
        final encoder = Bech32Encoder();
        final nevent = encoder.convert(
          Bech32('nevent', bech32Data),
          'nevent'.length + bech32Data.length + 10,
        );

        expect(
          () => Nip19.decodeNevent(nevent),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('decodeNaddr should throw on missing pubkey field', () {
        // Create naddr with identifier (type 0) and kind (type 3) but no pubkey (type 2)
        final identifier = 'test';
        final tlvData = <int>[
          0, identifier.length, // type 0 (identifier), length
          ...utf8.encode(identifier), // identifier value
          3, 4, // type 3 (kind), length 4
          0, 0, 0x75, 0x17, // kind 30023 in big-endian
        ];
        final bech32Data = Nip19.convertBits(tlvData, 8, 5, true);
        final encoder = Bech32Encoder();
        final naddr = encoder.convert(
          Bech32('naddr', bech32Data),
          'naddr'.length + bech32Data.length + 10,
        );

        expect(
          () => Nip19.decodeNaddr(naddr),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('decodeNaddr should throw on missing kind field', () {
        // Create naddr with identifier and pubkey but no kind
        final pubkeyBytes = HEX.decode(
            '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c');
        final identifier = 'test';
        final tlvData = <int>[
          0, identifier.length, // type 0 (identifier), length
          ...utf8.encode(identifier), // identifier value
          2, 32, // type 2 (pubkey), length 32
          ...pubkeyBytes, // pubkey value
        ];
        final bech32Data = Nip19.convertBits(tlvData, 8, 5, true);
        final encoder = Bech32Encoder();
        final naddr = encoder.convert(
          Bech32('naddr', bech32Data),
          'naddr'.length + bech32Data.length + 10,
        );

        expect(
          () => Nip19.decodeNaddr(naddr),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
