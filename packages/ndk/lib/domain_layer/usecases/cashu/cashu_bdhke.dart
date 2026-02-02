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

typedef BlindMessageResult = (String B_, BigInt r);

class CashuBdhke {
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

        //final secret = Helpers.getSecureRandomString(32);
        // ignore: non_constant_identifier_names, constant_identifier_names
        final (B_, r) = blindMessage(secret, r: myR);

        if (B_.isEmpty) {
          continue;
        }

        final blindedMessage = CashuBlindedMessage(
          id: keysetId,
          amount: amount,
          blindedMessage: B_,
        );

        items.add(CashuBlindedMessageItem(
          blindedMessage: blindedMessage,
          secret: secret,
          r: r,
          amount: amount,
        ));
      } catch (e) {
        Logger.log.w(
          'Error creating blinded message for amount $amount: $e',
          error: e,
        );
      }
    }

    return items;
  }

  static BlindMessageResult blindMessage(String secret, {BigInt? r}) {
    final Y = CashuTools.hashToCurve(secret);

    Random random = Random.secure();
    r ??= BigInt.from(random.nextInt(1000000)) + BigInt.one;

    // Use fast multiplication (10-20x faster!)
    final rG = CashuTools.fastGMultiply(r);
    final ECPoint? blindedMessage = Y + rG;

    if (blindedMessage == null) {
      throw Exception('Failed to compute blinded message');
    }

    final String blindedMessageHex = CashuTools.ecPointToHex(blindedMessage);
    return (blindedMessageHex, r);
  }

  static ECPoint? unblindingSignature({
    required String cHex,
    required String kHex,
    required BigInt r,
  }) {
    final C_ = CashuTools.pointFromHexString(cHex);
    final K = CashuTools.pointFromHexString(kHex);
    final rK = K * r;
    if (rK == null) return null;
    return C_ - rK;
  }

  static List<CashuProof> unblindSignatures({
    required List<CashuBlindedSignature> mintSignatures,
    required List<CashuBlindedMessageItem> blindedMessages,
    required CahsuKeyset mintPublicKeys,
  }) {
    List<CashuProof> tokens = [];

    if (mintSignatures.length != blindedMessages.length) {
      throw Exception(
          'Mismatched lengths: ${mintSignatures.length} signatures, ${blindedMessages.length} messages');
    }

    /// copy lists and sort by amount descending
    final sortedSignatures = List<CashuBlindedSignature>.from(mintSignatures)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final sortedMessages = List<CashuBlindedMessageItem>.from(blindedMessages)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    for (int i = 0; i < sortedSignatures.length; i++) {
      final signature = sortedSignatures[i];
      final blindedMsg = sortedMessages[i];

      final matchingKeys = mintPublicKeys.mintKeyPairs
          .where((e) => e.amount == blindedMsg.amount)
          .toList();

      if (matchingKeys.isEmpty) {
        throw Exception('No mint public key for amount ${blindedMsg.amount}');
      }
      final mintPubKey = matchingKeys.first;

      final unblindedSig = unblindingSignature(
        cHex: signature.blindedSignature,
        kHex: mintPubKey.pubkey,
        r: blindedMsg.r,
      );

      if (unblindedSig == null) {
        throw Exception('Failed to unblind signature');
      }

      tokens.add(CashuProof(
        secret: blindedMsg.secret,
        amount: blindedMsg.amount,
        unblindedSig: CashuTools.ecPointToHex(unblindedSig),
        keysetId: mintPublicKeys.id,
      ));
    }

    return tokens;
  }
}
