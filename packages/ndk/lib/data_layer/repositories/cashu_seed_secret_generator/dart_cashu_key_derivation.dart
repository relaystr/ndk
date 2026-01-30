import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:bip32_keys/bip32_keys.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart';

import '../../../domain_layer/repositories/cashu_seed_secret.dart';
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

  final Uint8List? _seed;
  Bip32Keys? _cachedMasterKey;

  DartCashuKeyDerivation({Uint8List? seed}) : _seed = seed;

  @override
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required Mnemonic mnemonic,
    required int counter,
    required String keysetId,
  }) async {
    // Validate keysetId format
    final isValidHex = RegExp(r'^[a-fA-F0-9]+$').hasMatch(keysetId);
    if (!isValidHex) {
      throw Exception('Keyset ID must be valid hex');
    }

    final seed = Uint8List.fromList(mnemonic.seed);

    // Choose derivation method based on keyset version
    if (keysetId.startsWith('00')) {
      return _deriveDeprecatedWithSeed(
          seed: seed, keysetId: keysetId, counter: counter);
    } else if (keysetId.startsWith('01')) {
      return _deriveModernWithSeed(
          seed: seed, keysetId: keysetId, counter: counter);
    }

    throw Exception(
        'Unrecognized keyset ID version ${keysetId.substring(0, 2)}');
  }

  /// Derive both secret and blinding factor
  CashuSeedDeriveSecretResult deriveSecretAndBlinding({
    required String keysetId,
    required int counter,
  }) {
    if (_seed == null) {
      throw Exception('Seed must be provided');
    }

    final isValidHex = RegExp(r'^[a-fA-F0-9]+$').hasMatch(keysetId);

    if (!isValidHex) {
      throw Exception('Keyset ID must be valid hex');
    }

    if (keysetId.startsWith('00')) {
      return _deriveDeprecated(keysetId: keysetId, counter: counter);
    } else if (keysetId.startsWith('01')) {
      return _deriveModern(keysetId: keysetId, counter: counter);
    }

    throw Exception(
        'Unrecognized keyset ID version ${keysetId.substring(0, 2)}');
  }

  /// Derive blinding factor only
  Uint8List deriveBlindingFactor({
    required String keysetId,
    required int counter,
  }) {
    final isValidHex = RegExp(r'^[a-fA-F0-9]+$').hasMatch(keysetId);

    if (!isValidHex) {
      throw Exception('Keyset ID must be valid hex');
    }

    if (keysetId.startsWith('00')) {
      return _derive(
        keysetId: keysetId,
        counter: counter,
        derivationType: DerivationType.blindingFactor,
      );
    } else if (keysetId.startsWith('01')) {
      return _deriveV01(
        keysetId: keysetId,
        counter: counter,
        derivationType: DerivationType.blindingFactor,
      );
    }

    throw Exception(
        'Unrecognized keyset ID version ${keysetId.substring(0, 2)}');
  }

  /// Modern derivation method (version 01) - returns both
  CashuSeedDeriveSecretResult _deriveModern({
    required String keysetId,
    required int counter,
  }) {
    return _deriveModernWithSeed(
        seed: _seed!, keysetId: keysetId, counter: counter);
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

  /// Modern derivation method (version 01) - single derivation
  Uint8List _deriveV01({
    required String keysetId,
    required int counter,
    required DerivationType derivationType,
  }) {
    return _deriveV01WithSeed(
      seed: _seed!,
      keysetId: keysetId,
      counter: counter,
      derivationType: derivationType,
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

  /// Deprecated BIP32-based derivation (version 00) - returns both
  CashuSeedDeriveSecretResult _deriveDeprecated({
    required String keysetId,
    required int counter,
  }) {
    return _deriveDeprecatedWithSeed(
        seed: _seed!, keysetId: keysetId, counter: counter);
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

  /// Deprecated BIP32-based derivation (version 00) - single derivation
  Uint8List _derive({
    required String keysetId,
    required int counter,
    required DerivationType derivationType,
  }) {
    // Cache master key to avoid recomputing
    _cachedMasterKey ??= Bip32Keys.fromSeed(_seed!);

    final keysetIdInt = _keysetIdToInt(keysetId);

    final derivationPath =
        "m/$derivationPurpose'/$derivationCoinType'/$keysetIdInt'/$counter'/${derivationType.value}";

    final derived = _cachedMasterKey!.derivePath(derivationPath);

    if (derived.private == null) {
      throw Exception('Could not derive private key');
    }

    return Uint8List.fromList(derived.private!.toList());
  }

  /// Convert keyset ID to integer for BIP32 derivation
  int _keysetIdToInt(String keysetId) {
    return _keysetIdToIntStatic(keysetId);
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

  /// Convert integer to big-endian 64-bit bytes
  static Uint8List _bigUint64BE(int value) {
    final buffer = Uint8List(8);
    final byteData = ByteData.sublistView(buffer);
    byteData.setUint64(0, value, Endian.big);
    return buffer;
  }
}
