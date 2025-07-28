import 'dart:math';

import 'package:pointycastle/export.dart';

import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/cashu/wallet_cashu_keyset.dart';
import '../../entities/cashu/wallet_cashu_blinded_message.dart';
import '../../entities/cashu/wallet_cashu_blinded_signature.dart';
import '../../entities/cashu/wallet_cashu_proof.dart';
import 'cashu_tools.dart';

typedef BlindMessageResult = (String B_, BigInt r);

class CashuBdhke {
  static List<WalletCashuBlindedMessageItem> createBlindedMsgForAmounts({
    required String keysetId,
    required List<int> amounts,
  }) {
    List<WalletCashuBlindedMessageItem> items = [];

    for (final amount in amounts) {
      try {
        final secret = Helpers.getSecureRandomString(32);
        final (B_, r) = blindMessage(secret);

        if (B_.isEmpty) {
          continue;
        }

        final blindedMessage = WalletCashuBlindedMessage(
          id: keysetId,
          amount: amount,
          blindedMessage: B_,
        );

        items.add(WalletCashuBlindedMessageItem(
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
    // Alice picks secret x and computes Y = hash_to_curve(x)
    final ECPoint Y = CashuTools.hashToCurve(secret);

    final G = CashuTools.getG();

    // Alice generates random blinding factor r
    Random random = Random.secure();
    r ??= BigInt.from(random.nextInt(1000000)) + BigInt.one;

    // Alice sends to Bob: B_ = Y + rG (blinding)
    final ECPoint? blindedMessage = Y + (G * r);
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

  static List<WalletCashuProof> unblindSignatures({
    required List<WalletCashuBlindedSignature> mintSignatures,
    required List<WalletCashuBlindedMessageItem> blindedMessages,
    required WalletCahsuKeyset mintPublicKeys,
    required String keysetId,
  }) {
    List<WalletCashuProof> tokens = [];

    for (int i = 0; i < mintSignatures.length; i++) {
      final signature = mintSignatures[i];
      final blindedMsg = blindedMessages[i];

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

      tokens.add(WalletCashuProof(
        secret: blindedMsg.secret,
        amount: blindedMsg.amount,
        unblindedSig: CashuTools.ecPointToHex(unblindedSig),
        keysetId: keysetId,
      ));
    }

    return tokens;
  }
}
