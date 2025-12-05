import 'package:ndk/domain_layer/usecases/nip_01_event_service/nip_01_event_service.dart';
import 'package:ndk/domain_layer/usecases/proof_of_work/proof_of_work.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';
import 'package:ndk/shared/nips/nip13/nip13.dart';

void main() {
  group('NIP-13 Proof of Work', () {
    group('countLeadingZeroBits', () {
      test('should count single hex digits correctly', () {
        // Test each hex digit (0-F) individually
        expect(Nip13.countLeadingZeroBits('0'), equals(4),
            reason: '0000 has 4 leading zeros');
        expect(Nip13.countLeadingZeroBits('1'), equals(3),
            reason: '0001 has 3 leading zeros');
        expect(Nip13.countLeadingZeroBits('2'), equals(2),
            reason: '0010 has 2 leading zeros');
        expect(Nip13.countLeadingZeroBits('3'), equals(2),
            reason: '0011 has 2 leading zeros');
        expect(Nip13.countLeadingZeroBits('4'), equals(1),
            reason: '0100 has 1 leading zero');
        expect(Nip13.countLeadingZeroBits('5'), equals(1),
            reason: '0101 has 1 leading zero');
        expect(Nip13.countLeadingZeroBits('6'), equals(1),
            reason: '0110 has 1 leading zero');
        expect(Nip13.countLeadingZeroBits('7'), equals(1),
            reason: '0111 has 1 leading zero');
        expect(Nip13.countLeadingZeroBits('8'), equals(0),
            reason: '1000 has 0 leading zeros');
        expect(Nip13.countLeadingZeroBits('9'), equals(0),
            reason: '1001 has 0 leading zeros');
        expect(Nip13.countLeadingZeroBits('a'), equals(0),
            reason: '1010 has 0 leading zeros');
        expect(Nip13.countLeadingZeroBits('b'), equals(0),
            reason: '1011 has 0 leading zeros');
        expect(Nip13.countLeadingZeroBits('c'), equals(0),
            reason: '1100 has 0 leading zeros');
        expect(Nip13.countLeadingZeroBits('d'), equals(0),
            reason: '1101 has 0 leading zeros');
        expect(Nip13.countLeadingZeroBits('e'), equals(0),
            reason: '1110 has 0 leading zeros');
        expect(Nip13.countLeadingZeroBits('f'), equals(0),
            reason: '1111 has 0 leading zeros');
      });

      test('should handle multi-digit hex strings correctly', () {
        // Test cases with multiple hex digits
        expect(Nip13.countLeadingZeroBits('00f'), equals(8),
            reason: '0000 0000 1111 has 8 leading zeros');
        expect(Nip13.countLeadingZeroBits('001'), equals(11),
            reason: '0000 0000 0001 has 11 leading zeros');
        expect(Nip13.countLeadingZeroBits('007'), equals(9),
            reason: '0000 0000 0111 has 9 leading zeros');
        expect(Nip13.countLeadingZeroBits('010'), equals(7),
            reason: '0000 0001 0000 has 7 leading zeros');
        expect(Nip13.countLeadingZeroBits('100'), equals(3),
            reason: '0001 0000 0000 has 3 leading zeros');
      });

      test('should handle NIP-13 specification examples', () {
        // Example from NIP-13 spec: "002f" should have 10 leading zero bits
        expect(Nip13.countLeadingZeroBits('002f'), equals(10),
            reason: 'NIP-13 spec states "002f" has 10 leading zero bits');

        // Real example from NIP-13 spec
        final specExampleId =
            "000006d8c378af1779d2feebc7603a125d99eca0ccf1085959b307f64e5dd358";
        final actualDifficulty = Nip13.countLeadingZeroBits(specExampleId);
        expect(actualDifficulty, equals(21),
            reason:
                'NIP-13 spec example should have 21 leading zero bits (000006 = 20 + 1 from "6")');
      });

      test('should handle edge cases', () {
        // Empty string (though this might not be a valid use case)
        expect(Nip13.countLeadingZeroBits(''), equals(0),
            reason: 'Empty string should return 0');

        // All zeros
        expect(Nip13.countLeadingZeroBits('0000'), equals(16),
            reason: '16 zero bits should return 16');
        expect(Nip13.countLeadingZeroBits('00000'), equals(20),
            reason: '20 zero bits should return 20');
      });
    });

    test('mineEvent should meet difficulty', () async {
      final keypair = Bip340.generatePrivateKey();

      final event = Nip01EventService.createEventCalculateId(
        pubKey: keypair.publicKey,
        kind: 1,
        tags: [],
        content: 'Hello, Nostr!',
        createdAt: 1234567890,
      );

      final minedEvent = await ProofOfWork.minePoW(
          event: event, targetDifficulty: 4, maxIterations: 100000);

      expect(
          ProofOfWork.checkPoWDifficulty(
              event: minedEvent, targetDifficulty: 2),
          isTrue);
    });

    test('should return null when no nonce tag present', () {
      final keypair = Bip340.generatePrivateKey();
      final eventWithoutNonce = Nip01EventService.createEventCalculateId(
        pubKey: keypair.publicKey,
        kind: 1,
        tags: [],
        content: 'Test event',
        createdAt: 1234567890,
      );

      final targetDifficulty =
          Nip13.getTargetDifficultyFromEvent(eventWithoutNonce);
      expect(targetDifficulty, isNull,
          reason: 'Should return null when no nonce tag present');
    });

    test('should handle malformed nonce tags gracefully', () {
      final keypair = Bip340.generatePrivateKey();
      final eventWithBadNonce = Nip01EventService.createEventCalculateId(
        pubKey: keypair.publicKey,
        kind: 1,
        tags: [
          ['nonce', '12345']
        ], // Missing difficulty
        content: 'Test event',
        createdAt: 1234567890,
      );

      final targetDifficulty =
          Nip13.getTargetDifficultyFromEvent(eventWithBadNonce);
      expect(targetDifficulty, isNull,
          reason: 'Should return null for malformed nonce tag');
    });

    test('check target difficulty', () async {
      final keypair = Bip340.generatePrivateKey();

      final event = Nip01EventService.createEventCalculateId(
        pubKey: keypair.publicKey,
        kind: 1,
        tags: [],
        content: 'Hello, Nostr!',
        createdAt: 1234567890,
      );

      final minedEvent =
          await ProofOfWork.minePoW(event: event, targetDifficulty: 4);

      final value = ProofOfWork.getTargetDifficultyFromEvent(minedEvent);

      expect(value, equals(4));
    });
  });

  test('validate event: greater POW', () {
    final minedEvent = Nip01EventModel.fromJson({
      "id": "00302f635d4e2059c5cdddca2c00b5f455ec6706cfd960a410acc3e9abe36100",
      "pubkey":
          "6d46059232af4d121456d1fff7fa8dadc32b02510e46e85b912b0585cf038574",
      "created_at": 1234567890,
      "kind": 1,
      "tags": [
        ["nonce", "3613431634", "10"]
      ],
      "content": "Hello, Nostr!",
      "sig": ""
    });

    final value = Nip13.validateEvent(minedEvent);

    expect(value, isTrue);

    final invalidEvent = minedEvent.copyWith(tags: [
      ['nonce', '123', '14']
    ]);

    final invalidValue = Nip13.validateEvent(invalidEvent);
    expect(invalidValue, isFalse);
  });

  test('validate event: id check', () async {
    final keypair = Bip340.generatePrivateKey();

    final event = Nip01EventService.createEventCalculateId(
      pubKey: keypair.publicKey,
      kind: 1,
      tags: [],
      content: 'Hello, Nostr!',
      createdAt: 1234567890,
    );

    final minedEvent =
        await ProofOfWork.minePoW(event: event, targetDifficulty: 10);

    final value = Nip13.validateEvent(minedEvent);

    expect(value, isTrue);

    final invalidEvent = minedEvent.copyWith(tags: [
      ['nonce', '123', '4']
    ]);

    final invalidValue = Nip01EventService.isIdValid(invalidEvent);
    expect(invalidValue, isFalse);
  });

  test('check commitment', () async {
    final keypair = Bip340.generatePrivateKey();

    final event = Nip01EventService.createEventCalculateId(
      pubKey: keypair.publicKey,
      kind: 1,
      tags: [],
      content: 'Hello, Nostr!',
      createdAt: 1234567890,
    );

    final minedEvent =
        await ProofOfWork.minePoW(event: event, targetDifficulty: 4);

    final commitment = Nip13.calculateCommitment(minedEvent.id);
    expect(commitment, greaterThan(0));
  });
}
