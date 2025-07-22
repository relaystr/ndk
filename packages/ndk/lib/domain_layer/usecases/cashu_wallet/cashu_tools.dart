import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' hide Digest;

import 'package:convert/convert.dart';

import '../../../config/cashu_config.dart';
import '../../../shared/nips/nip01/bip340.dart';
import '../../entities/cashu/wallet_cahsu_keyset.dart';
import '../../entities/cashu/wallet_cashu_blinded_message.dart';

class CashuTools {
  static String composeUrl({
    required String mintUrl,
    required String path,
    String version = '${CashuConfig.NUT_VERSION}/',
  }) {
    return '$mintUrl/$version$path';
  }

  /// Splits an amount into a list of powers of two.
  /// eg, 5 will be split into [1, 4]
  static List<int> splitAmount(int value) {
    return [
      for (int i = 0; value > 0; i++, value >>= 1)
        if (value & 1 == 1) 1 << i
    ];
  }

  static ECPoint getG() {
    return ECCurve_secp256k1().G;
  }

  static ECPoint hashToCurve(String hash) {
    const maxAttempt = 65536;

    final hashBytes = Uint8List.fromList(utf8.encode(hash));
    Uint8List msgToHash = Uint8List.fromList(
        [...CashuConfig.DOMAIN_SEPARATOR_HashToCurve.codeUnits, ...hashBytes]);

    var digest = SHA256Digest();
    Uint8List msgHash = digest.process(msgToHash);

    for (int counter = 0; counter < maxAttempt; counter++) {
      Uint8List counterBytes = Uint8List(4)
        ..buffer.asByteData().setUint32(0, counter, Endian.little);
      Uint8List bytesToHash = Uint8List.fromList([...msgHash, ...counterBytes]);

      Uint8List hash = digest.process(bytesToHash);

      try {
        String pointXHex = '02${hex.encode(hash)}';
        ECPoint point = pointFromHexString(pointXHex);
        return point;
      } catch (_) {
        continue;
      }
    }

    throw Exception('Failed to find a valid point after $maxAttempt attempts');
  }

  static ECPoint pointFromHexString(String hexString) {
    final curve = ECCurve_secp256k1();
    final bytes = hex.decode(hexString);

    return curve.curve.decodePoint(bytes)!;
  }

  static String ecPointToHex(ECPoint point, {bool compressed = true}) {
    return point
        .getEncoded(compressed)
        .map(
          (byte) => byte.toRadixString(16).padLeft(2, '0'),
        )
        .join();
  }

  static String createMintSignature({
    required String quote,
    required List<WalletCashuBlindedMessage> blindedMessagesOutputs,
    required String privateKeyHex,
  }) {
    final StringBuffer messageBuffer = StringBuffer();

    // add quote id
    messageBuffer.write(quote);

    // add each B_ field(hex strings)
    for (final output in blindedMessagesOutputs) {
      messageBuffer.write(output.blindedMessage);
    }

    final String messageToSign = messageBuffer.toString();

    // hash the message
    final Uint8List messageBytes = utf8.encode(messageToSign);
    final Digest messageHash = sha256.convert(messageBytes);
    final String messageHashHex = messageHash.toString();

    final String signature = Bip340.sign(messageHashHex, privateKeyHex);

    return signature;
  }

  static Uint8List hexToBytes(String hex) {
    return Uint8List.fromList(
      List.generate(
        hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  static WalletCahsuKeyset? findActiveKeyset(
    List<WalletCahsuKeyset> keysets,
  ) {
    if (keysets.isEmpty) {
      return null;
    }
    try {
      return keysets.firstWhere((keyset) => keyset.active);
    } catch (_) {
      return null;
    }
  }
}
