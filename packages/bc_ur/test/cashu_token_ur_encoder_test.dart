import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_token.dart';
import '../lib/cashu_token_ur_encoder.dart';
import 'package:test/test.dart';

void main() {
  group('CashuTokenUrEncoder - Single Part', () {
    test('encode and decode simple token', () {
      // Create a simple test token
      final token = CashuToken(
        proofs: [
          CashuProof(
            amount: 8,
            secret: 'test-secret-123',
            unblindedSig:
                '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
            keysetId: '009a1f293253e41e',
          ),
        ],
        memo: 'test memo',
        unit: 'sat',
        mintUrl: 'https://testmint.example.com',
      );

      // Encode to UR
      final urString = CashuTokenUrEncoder.encodeSinglePart(token: token);

      // Verify it starts with ur:bytes/
      expect(urString.startsWith('ur:bytes/'), isTrue);

      // Decode back
      final decodedToken = CashuTokenUrEncoder.decodeSinglePart(urString);

      // Verify decoded token matches original
      expect(decodedToken, isNotNull);
      expect(decodedToken!.mintUrl, equals(token.mintUrl));
      expect(decodedToken.unit, equals(token.unit));
      expect(decodedToken.memo, equals(token.memo));
      expect(decodedToken.proofs.length, equals(1));
      expect(decodedToken.proofs[0].amount, equals(8));
      expect(decodedToken.proofs[0].secret, equals('test-secret-123'));
    });

    test('encode and decode token without memo', () {
      final token = CashuToken(
        proofs: [
          CashuProof(
            amount: 16,
            secret: 'another-secret',
            unblindedSig:
                '03b01869f528337e161a6768e480fcf9af32c76ff5dcf90bb4d1993c5c4e6e8e59',
            keysetId: '009a1f293253e41e',
          ),
        ],
        memo: '',
        unit: 'sat',
        mintUrl: 'https://mint.example.com',
      );

      final urString = CashuTokenUrEncoder.encodeSinglePart(token: token);
      final decodedToken = CashuTokenUrEncoder.decodeSinglePart(urString);

      expect(decodedToken, isNotNull);
      expect(decodedToken!.memo, equals(''));
      expect(decodedToken.proofs[0].amount, equals(16));
    });

    test('encode and decode token with multiple proofs', () {
      final token = CashuToken(
        proofs: [
          CashuProof(
            amount: 1,
            secret: 'secret-1',
            unblindedSig:
                '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
            keysetId: '009a1f293253e41e',
          ),
          CashuProof(
            amount: 2,
            secret: 'secret-2',
            unblindedSig:
                '03b01869f528337e161a6768e480fcf9af32c76ff5dcf90bb4d1993c5c4e6e8e59',
            keysetId: '009a1f293253e41e',
          ),
          CashuProof(
            amount: 4,
            secret: 'secret-3',
            unblindedSig:
                '02c0ee6e3ecf9f2e6aa06a4b0cf0b9c4c3e6c9b8d0a0f3a4c3d9e8b7a6c5d4e3f2',
            keysetId: '009a1f293253e41e',
          ),
        ],
        memo: 'multiple proofs',
        unit: 'sat',
        mintUrl: 'https://multimint.example.com',
      );

      final urString = CashuTokenUrEncoder.encodeSinglePart(token: token);
      final decodedToken = CashuTokenUrEncoder.decodeSinglePart(urString);

      expect(decodedToken, isNotNull);
      expect(decodedToken!.proofs.length, equals(3));
      expect(decodedToken.proofs[0].amount, equals(1));
      expect(decodedToken.proofs[1].amount, equals(2));
      expect(decodedToken.proofs[2].amount, equals(4));
    });

    test('decode invalid UR string returns null', () {
      final decodedToken =
          CashuTokenUrEncoder.decodeSinglePart('invalid-ur-string');
      expect(decodedToken, isNull);
    });

    test('decode UR with wrong type returns null', () {
      // This is a valid UR but with wrong type
      final decodedToken =
          CashuTokenUrEncoder.decodeSinglePart('ur:crypto-seed/oeadgdaxbt');
      expect(decodedToken, isNull);
    });
  });

  group('CashuTokenUrEncoder - Multi Part (Animated QR)', () {
    test('create multi-part encoder for large token', () {
      // Create a token with many proofs to ensure it needs multiple parts
      final proofs = List<CashuProof>.generate(
        10,
        (i) => CashuProof(
          amount: 1 << i, // Powers of 2: 1, 2, 4, 8, 16, etc.
          secret: 'secret-$i-with-some-long-text-to-make-it-larger-${"x" * 50}',
          unblindedSig:
              '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
          keysetId: '009a1f293253e41e',
        ),
      );

      final token = CashuToken(
        proofs: proofs,
        memo: 'large token requiring multiple QR codes',
        unit: 'sat',
        mintUrl: 'https://largemint.example.com',
      );

      // Create encoder with small fragment size to force multiple parts
      final encoder = CashuTokenUrEncoder.createMultiPartEncoder(
        token: token,
        maxFragmentLen: 100,
      );

      expect(encoder, isNotNull);
      expect(encoder.isSinglePart, isFalse);
    });

    test('encode and decode multi-part UR', () {
      // Create a token with several proofs
      final proofs = List<CashuProof>.generate(
        5,
        (i) => CashuProof(
          amount: 1 << i,
          secret: 'secret-$i-${"x" * 30}',
          unblindedSig:
              '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
          keysetId: '009a1f293253e41e',
        ),
      );

      final token = CashuToken(
        proofs: proofs,
        memo: 'multi-part test',
        unit: 'sat',
        mintUrl: 'https://mint.example.com',
      );

      // Create encoder with small fragment size
      final encoder = CashuTokenUrEncoder.createMultiPartEncoder(
        token: token,
        maxFragmentLen: 80,
      );

      // Create decoder
      final decoder = CashuTokenUrEncoder.createMultiPartDecoder();

      // Generate and feed parts until complete
      final parts = <String>[];
      while (!decoder.isComplete()) {
        final part = encoder.nextPart();
        parts.add(part);
        decoder.receivePart(part);

        // Prevent infinite loop
        if (parts.length > 100) {
          fail('Too many parts generated, something is wrong');
        }
      }

      // Verify we generated multiple parts
      expect(parts.length, greaterThan(1));

      // Decode the complete message
      final decodedToken =
          CashuTokenUrEncoder.decodeFromMultiPartDecoder(decoder);

      // Verify decoded token matches original
      expect(decodedToken, isNotNull);
      expect(decodedToken!.mintUrl, equals(token.mintUrl));
      expect(decodedToken.unit, equals(token.unit));
      expect(decodedToken.memo, equals(token.memo));
      expect(decodedToken.proofs.length, equals(5));
      expect(decodedToken.proofs[0].amount, equals(1));
      expect(decodedToken.proofs[4].amount, equals(16));
    });

    test('decoder tracks progress', () {
      final proofs = List<CashuProof>.generate(
        5,
        (i) => CashuProof(
          amount: 1 << i,
          secret: 'secret-$i-${"x" * 30}',
          unblindedSig:
              '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
          keysetId: '009a1f293253e41e',
        ),
      );

      final token = CashuToken(
        proofs: proofs,
        memo: 'progress test',
        unit: 'sat',
        mintUrl: 'https://mint.example.com',
      );

      final encoder = CashuTokenUrEncoder.createMultiPartEncoder(
        token: token,
        maxFragmentLen: 80,
      );

      final decoder = CashuTokenUrEncoder.createMultiPartDecoder();

      // Feed first part
      final firstPart = encoder.nextPart();
      decoder.receivePart(firstPart);

      // Check progress
      final progress = decoder.estimatedPercentComplete();
      expect(progress, greaterThan(0.0));
      expect(progress, lessThanOrEqualTo(1.0));

      // Complete the decoding
      while (!decoder.isComplete()) {
        final part = encoder.nextPart();
        decoder.receivePart(part);
      }

      expect(decoder.isComplete(), isTrue);
      expect(decoder.isSuccess(), isTrue);
    });

    test('decode incomplete multi-part returns null', () {
      final proofs = List<CashuProof>.generate(
        3,
        (i) => CashuProof(
          amount: 1,
          secret: 'secret-$i-${"x" * 30}',
          unblindedSig:
              '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
          keysetId: '009a1f293253e41e',
        ),
      );

      final token = CashuToken(
        proofs: proofs,
        memo: 'incomplete test',
        unit: 'sat',
        mintUrl: 'https://mint.example.com',
      );

      final encoder = CashuTokenUrEncoder.createMultiPartEncoder(
        token: token,
        maxFragmentLen: 50,
      );

      final decoder = CashuTokenUrEncoder.createMultiPartDecoder();

      // Feed only first part (not complete)
      final firstPart = encoder.nextPart();
      decoder.receivePart(firstPart);

      // Try to decode incomplete data
      final decodedToken =
          CashuTokenUrEncoder.decodeFromMultiPartDecoder(decoder);
      expect(decodedToken, isNull);
    });

    test('parts can be received in any order', () {
      final proofs = List<CashuProof>.generate(
        4,
        (i) => CashuProof(
          amount: 1 << i,
          secret: 'secret-$i-${"x" * 25}',
          unblindedSig:
              '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
          keysetId: '009a1f293253e41e',
        ),
      );

      final token = CashuToken(
        proofs: proofs,
        memo: 'order test',
        unit: 'sat',
        mintUrl: 'https://mint.example.com',
      );

      final encoder = CashuTokenUrEncoder.createMultiPartEncoder(
        token: token,
        maxFragmentLen: 70,
      );

      // Generate all parts
      final parts = <String>[];
      while (!encoder.isComplete) {
        parts.add(encoder.nextPart());
        if (parts.length > 50) break;
      }

      expect(parts.length, greaterThan(1));

      // Shuffle parts to simulate out-of-order reception
      final shuffledParts = List<String>.from(parts)..shuffle();

      // Decode shuffled parts
      final decoder = CashuTokenUrEncoder.createMultiPartDecoder();
      for (final part in shuffledParts) {
        decoder.receivePart(part);
        if (decoder.isComplete()) break;
      }

      expect(decoder.isComplete(), isTrue);

      final decodedToken =
          CashuTokenUrEncoder.decodeFromMultiPartDecoder(decoder);
      expect(decodedToken, isNotNull);
      expect(decodedToken!.proofs.length, equals(4));
    });
  });

  group('CashuTokenUrEncoder - Edge Cases', () {
    test('encode token with empty proofs list', () {
      final token = CashuToken(
        proofs: [],
        memo: '',
        unit: 'sat',
        mintUrl: 'https://mint.example.com',
      );

      final urString = CashuTokenUrEncoder.encodeSinglePart(token: token);
      final decodedToken = CashuTokenUrEncoder.decodeSinglePart(urString);

      expect(decodedToken, isNotNull);
      expect(decodedToken!.proofs.length, equals(0));
    });

    test('encode token with long memo', () {
      final longMemo = 'This is a very long memo ' * 10;
      final token = CashuToken(
        proofs: [
          CashuProof(
            amount: 8,
            secret: 'test-secret',
            unblindedSig:
                '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
            keysetId: '009a1f293253e41e',
          ),
        ],
        memo: longMemo,
        unit: 'sat',
        mintUrl: 'https://mint.example.com',
      );

      final urString = CashuTokenUrEncoder.encodeSinglePart(token: token);
      final decodedToken = CashuTokenUrEncoder.decodeSinglePart(urString);

      expect(decodedToken, isNotNull);
      expect(decodedToken!.memo, equals(longMemo));
    });

    test('encode token with special characters in secret', () {
      final token = CashuToken(
        proofs: [
          CashuProof(
            amount: 8,
            secret: '特殊字符-🎉-émojis-тест',
            unblindedSig:
                '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
            keysetId: '009a1f293253e41e',
          ),
        ],
        memo: 'unicode test 测试 🚀',
        unit: 'sat',
        mintUrl: 'https://mint.example.com',
      );

      final urString = CashuTokenUrEncoder.encodeSinglePart(token: token);
      final decodedToken = CashuTokenUrEncoder.decodeSinglePart(urString);

      expect(decodedToken, isNotNull);
      expect(decodedToken!.proofs[0].secret, equals('特殊字符-🎉-émojis-тест'));
      expect(decodedToken.memo, equals('unicode test 测试 🚀'));
    });
  });
}
