import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:bip32_keys/bip32_keys.dart';
import 'package:convert/convert.dart';

import '../../../domain_layer/repositories/cashu_key_derivation.dart';
import '../../../domain_layer/usecases/cashu/cashu_seed.dart';

enum DerivationType {
  secret(0),
  blindingFactor(1);

  final int value;
  const DerivationType(this.value);
}

class DartCashuKeyDerivation implements CashuKeyDerivation {
  static const int derivationPurpose = 129372;
  static const int derivationCoinType = 0;

  static final BigInt secp256k1N = BigInt.parse(
    'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
    radix: 16,
  );

  DartCashuKeyDerivation();

  @override
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required Uint8List seedBytes,
    required int counter,
    required String keysetId,
  }) async {
    // Validate keysetId format
    final isValidHex = RegExp(r'^[a-fA-F0-9]+$').hasMatch(keysetId);
    if (!isValidHex) {
      throw Exception('Keyset ID must be valid hex');
    }

    // Choose derivation method based on keyset version
    if (keysetId.startsWith('00')) {
      return _deriveDeprecatedWithSeed(
          seed: seedBytes, keysetId: keysetId, counter: counter);
    } else if (keysetId.startsWith('01')) {
      return _deriveModernWithSeed(
          seed: seedBytes, keysetId: keysetId, counter: counter);
    }

    throw Exception(
        'Unrecognized keyset ID version ${keysetId.substring(0, 2)}');
  }

  /// Modern derivation method with explicit seed parameter
  static CashuSeedDeriveSecretResult _deriveModernWithSeed({
    required Uint8List seed,
    required String keysetId,
    required int counter,
  }) {
    final secret = _deriveV01WithSeed(
      seed: seed,
      keysetId: keysetId,
      counter: counter,
      derivationType: DerivationType.secret,
    );

    final blinding = _deriveV01WithSeed(
      seed: seed,
      keysetId: keysetId,
      counter: counter,
      derivationType: DerivationType.blindingFactor,
    );

    return CashuSeedDeriveSecretResult(
      secretHex: hex.encode(secret),
      blindingHex: hex.encode(blinding),
    );
  }

  /// Modern derivation method with explicit seed parameter
  static Uint8List _deriveV01WithSeed({
    required Uint8List seed,
    required String keysetId,
    required int counter,
    required DerivationType derivationType,
  }) {
    // Build message: "Cashu_KDF_HMAC_SHA256" || keysetId || counter || type
    final messageBuilder = BytesBuilder();

    // Add domain separator
    messageBuilder.add(utf8.encode('Cashu_KDF_HMAC_SHA256'));

    // Add keyset ID (hex to bytes)
    messageBuilder.add(_hexToBytes(keysetId));

    // Add counter as big-endian 64-bit integer
    messageBuilder.add(_bigUint64BE(counter));

    // Add derivation type
    switch (derivationType) {
      case DerivationType.secret:
        messageBuilder.add([0x00]);
        break;
      case DerivationType.blindingFactor:
        messageBuilder.add([0x01]);
        break;
    }

    final message = messageBuilder.toBytes();

    // Compute HMAC-SHA256
    final hmacSha256 = Hmac(sha256, seed);
    final hmacDigest = Uint8List.fromList(hmacSha256.convert(message).bytes);

    // For blinding factor, ensure it's a valid secp256k1 scalar
    if (derivationType == DerivationType.blindingFactor) {
      final x = _bytesToBigInt(hmacDigest);

      // Optimization: single subtraction instead of modulo
      // Probability of HMAC >= SECP256K1_N is ~2^-128
      if (x >= secp256k1N) {
        return _bigIntToBytes(x - secp256k1N);
      }

      if (x == BigInt.zero) {
        throw Exception('Derived invalid blinding scalar r == 0');
      }
    }

    return hmacDigest;
  }

  /// Deprecated BIP32-based derivation with explicit seed parameter
  static CashuSeedDeriveSecretResult _deriveDeprecatedWithSeed({
    required Uint8List seed,
    required String keysetId,
    required int counter,
  }) {
    final masterKey = Bip32Keys.fromSeed(seed);

    final keysetIdInt = _keysetIdToIntStatic(keysetId);

    // Derive shared parent path once
    final sharedParent = masterKey.derivePath(
      "m/$derivationPurpose'/$derivationCoinType'/$keysetIdInt'/$counter'",
    );

    // Then derive final step separately
    final pathKeySecret = sharedParent.derivePath("0");
    final pathKeyBlinding = sharedParent.derivePath("1");

    final pathKeySecretHex = hex.encode(pathKeySecret.private!.toList());
    final pathKeyBlindingHex = hex.encode(pathKeyBlinding.private!.toList());

    return CashuSeedDeriveSecretResult(
      secretHex: pathKeySecretHex,
      blindingHex: pathKeyBlindingHex,
    );
  }

  static int _keysetIdToIntStatic(String keysetId) {
    BigInt number = BigInt.parse(keysetId, radix: 16);

    //BigInt modulus = BigInt.from(2).pow(31) - BigInt.one;
    /// precalculated for 2^31 - 1
    BigInt modulus = BigInt.from(2147483647);

    BigInt keysetIdInt = number % modulus;

    return keysetIdInt.toInt();
  }

  /// Convert hex string to bytes
  static Uint8List _hexToBytes(String hexString) {
    return Uint8List.fromList(hex.decode(hexString));
  }

  /// Convert bytes to BigInt (big-endian)
  static BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Convert BigInt to bytes (big-endian, 32 bytes)
  static Uint8List _bigIntToBytes(BigInt value) {
    final result = <int>[];
    var temp = value;

    while (temp > BigInt.zero) {
      result.insert(0, (temp & BigInt.from(0xff)).toInt());
      temp = temp >> 8;
    }

    // Pad to 32 bytes
    while (result.length < 32) {
      result.insert(0, 0);
    }

    return Uint8List.fromList(result);
  }

  /// Convert integer to big-endian 64-bit bytes - web-compatible
  static Uint8List _bigUint64BE(int value) {
    final buffer = Uint8List(8);

    // Manually split into high and low 32-bit parts
    // This works on both VM and Web
    final high = (value ~/ 0x100000000) & 0xFFFFFFFF;
    final low = value & 0xFFFFFFFF;

    // Write high 32 bits (big-endian)
    buffer[0] = (high >> 24) & 0xff;
    buffer[1] = (high >> 16) & 0xff;
    buffer[2] = (high >> 8) & 0xff;
    buffer[3] = high & 0xff;

    // Write low 32 bits (big-endian)
    buffer[4] = (low >> 24) & 0xff;
    buffer[5] = (low >> 16) & 0xff;
    buffer[6] = (low >> 8) & 0xff;
    buffer[7] = low & 0xff;

    return buffer;
  }
}
