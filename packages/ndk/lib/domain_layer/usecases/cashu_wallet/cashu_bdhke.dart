import 'dart:math';

import 'package:pointycastle/export.dart';

import 'cashu_tools.dart';

typedef BlindMessageResult = (String B_, BigInt r);

class CashuBdhke {
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
}
