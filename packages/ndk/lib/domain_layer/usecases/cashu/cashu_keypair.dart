import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';

import '../../../shared/nips/nip01/helpers.dart';
import 'cashu_tools.dart';

class CashuKeypair {
  final String privateKey;
  final String publicKey;

  CashuKeypair({
    required this.privateKey,
    required this.publicKey,
  });

  static CashuKeypair generateCashuKeyPair() {
    // 32-byte private key
    final privKey = Helpers.getSecureRandomHex(32);

    // derive the public key as an EC point
    final pubKeyPoint = derivePublicKey(privKey);

    // convert the EC point to hex format (compressed)
    final pubKey = pubKeyPoint.getEncoded(true);
    final pubKeyHex = hex.encode(pubKey);

    return CashuKeypair(
      privateKey: privKey,
      publicKey: pubKeyHex,
    );
  }

  static ECPoint derivePublicKey(String privateKeyHex) {
    // hex private key to BigInt
    final privateKeyInt = BigInt.parse(privateKeyHex, radix: 16);

    final G = CashuTools.getG();

    // calculate public key: pubKey = privKey * G
    final publicKeyPoint = G * privateKeyInt;

    return publicKeyPoint!;
  }

  factory CashuKeypair.fromJson(Map<String, dynamic> json) {
    return CashuKeypair(
      privateKey: json['privateKey'] as String,
      publicKey: json['publicKey'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privateKey': privateKey,
      'publicKey': publicKey,
    };
  }
}
