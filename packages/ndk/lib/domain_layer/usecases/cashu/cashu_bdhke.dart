import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../../shared/logger/logger.dart';

import '../../entities/cashu/cashu_keyset.dart';
import '../../entities/cashu/cashu_blinded_message.dart';
import '../../entities/cashu/cashu_blinded_signature.dart';
import '../../entities/cashu/cashu_proof.dart';

import '../../repositories/cashu_key_derivation.dart';
import 'cashu_cache_decorator.dart';
import 'cashu_seed.dart';
import 'cashu_tools.dart';

typedef BlindMessageResult = (String blindedMessageHex, BigInt r);

class CashuBdhke {
  static final BigInt _secp256k1N = BigInt.parse(
    'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
    radix: 16,
  );

  static Future<List<CashuBlindedMessageItem>> createBlindedMsgForAmounts({
    required String keysetId,
    required List<int> amounts,
    required CashuCacheDecorator cacheManager,
    required CashuSeed cashuSeed,
    required String mintUrl,
    required CashuKeyDerivation cashuSeedSecretGenerator,
  }) async {
    List<CashuBlindedMessageItem> items = [];

    final seedBytes = Uint8List.fromList(cashuSeed.getSeedBytes());

    for (final amount in amounts) {
      try {
        final myCount = await cacheManager.getAndIncrementDerivationCounter(
          keysetId: keysetId,
          mintUrl: mintUrl,
        );

        final mySecret = await cashuSeedSecretGenerator.deriveSecret(
          seedBytes: seedBytes,
          counter: myCount,
          keysetId: keysetId,
        );

        final secret = mySecret.secretHex;

        final myR = BigInt.parse(mySecret.blindingHex, radix: 16);

        final (blindedMessageHex, r) = blindMessage(secret, r: myR);

        if (blindedMessageHex.isEmpty) {
          continue;
        }

        final blindedMessage = CashuBlindedMessage(
          id: keysetId,
          amount: amount,
          blindedMessage: blindedMessageHex,
        );

        items.add(
          CashuBlindedMessageItem(
            blindedMessage: blindedMessage,
            secret: secret,
            r: r,
            amount: amount,
          ),
        );
      } catch (e) {
        Logger.log.w(
          () => 'Error creating blinded message for amount $amount: $e',
          error: e,
        );
      }
    }

    return items;
  }

  /// Blinds [secret] for Cashu's blind-signature protocol.
  ///
  /// Hashes the secret to a curve point and adds [r] times the secp256k1
  /// generator. If [r] is omitted, a secure random scalar is generated.
  /// Returns the blinded point as hex together with the factor [r], which is
  /// required to unblind the mint's signature.
  static BlindMessageResult blindMessage(String secret, {BigInt? r}) {
    final Y = CashuTools.hashToCurve(secret);

    r ??= _randomBlindingFactor();

    // Use fast multiplication (10-20x faster!)
    final rG = CashuTools.fastGMultiply(r);
    final ECPoint? blindedMessage = Y + rG;

    if (blindedMessage == null) {
      throw Exception('Failed to compute blinded message');
    }

    final String blindedMessageHex = CashuTools.ecPointToHex(blindedMessage);
    return (blindedMessageHex, r);
  }

  /// Generates a uniform secp256k1 scalar in the range `1..n-1`.
  ///
  /// Samples 256-bit candidates from a secure random source and rejects zero
  /// or candidates greater than or equal to the secp256k1 curve order.
  static BigInt _randomBlindingFactor() {
    final random = Random.secure();
    while (true) {
      var candidate = BigInt.zero;
      for (var i = 0; i < 32; i++) {
        candidate = (candidate << 8) | BigInt.from(random.nextInt(256));
      }
      if (candidate > BigInt.zero && candidate < _secp256k1N) {
        return candidate;
      }
    }
  }

  static ECPoint? unblindingSignature({
    required String cHex,
    required String kHex,
    required BigInt r,
  }) {
    final cPoint = CashuTools.pointFromHexString(cHex);
    final K = CashuTools.pointFromHexString(kHex);
    final rK = K * r;
    if (rK == null) return null;
    return cPoint - rK;
  }

  static List<CashuProof> unblindSignatures({
    required List<CashuBlindedSignature> mintSignatures,
    required List<CashuBlindedMessageItem> blindedMessages,
    required CahsuKeyset mintPublicKeys,
  }) {
    List<CashuProof> tokens = [];

    if (mintSignatures.length != blindedMessages.length) {
      throw Exception(
        'Mismatched lengths: ${mintSignatures.length} signatures, ${blindedMessages.length} messages',
      );
    }

    final keysByAmount = <int, CahsuMintKeyPair>{};
    for (final keyPair in mintPublicKeys.mintKeyPairs) {
      keysByAmount[keyPair.amount] = keyPair;
    }

    /// copy lists and sort by amount descending
    final sortedSignatures = List<CashuBlindedSignature>.from(mintSignatures)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final sortedMessages = List<CashuBlindedMessageItem>.from(blindedMessages)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    for (int i = 0; i < sortedSignatures.length; i++) {
      final signature = sortedSignatures[i];
      final blindedMsg = sortedMessages[i];

      final mintPubKey = keysByAmount[blindedMsg.amount];

      if (mintPubKey == null) {
        throw Exception('No mint public key for amount ${blindedMsg.amount}');
      }

      final unblindedSig = unblindingSignature(
        cHex: signature.blindedSignature,
        kHex: mintPubKey.pubkey,
        r: blindedMsg.r,
      );

      if (unblindedSig == null) {
        throw Exception('Failed to unblind signature');
      }

      tokens.add(
        CashuProof(
          secret: blindedMsg.secret,
          amount: blindedMsg.amount,
          unblindedSig: CashuTools.ecPointToHex(unblindedSig),
          keysetId: mintPublicKeys.id,
        ),
      );
    }

    return tokens;
  }
}
