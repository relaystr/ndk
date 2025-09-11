import 'dart:typed_data';

import 'package:bip32_keys/bip32_keys.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart';

class CashuSeedDeriveSecretResult {
  final String secretHex;
  final String blindingHex;

  CashuSeedDeriveSecretResult({
    required this.secretHex,
    required this.blindingHex,
  });
}

class CashuSeed {
  static const int derivationPurpose = 129372;
  static const int derivationCoinType = 0;

  Mnemonic? _userSeedPhrase;

  CashuSeed({
    String? userSeedPhrase,
  }) {
    if (userSeedPhrase != null) {
      setSeedPhrase(seedPhrase: userSeedPhrase);
    }
  }

  /// set the user seed phrase
  /// throws an exception if the seed phrase is invalid
  void setSeedPhrase({
    required String seedPhrase,
    Language language = Language.english,
    String passphrase = '',
  }) {
    _userSeedPhrase = Mnemonic.fromSentence(
      seedPhrase,
      language,
      passphrase: passphrase,
    );
  }

  /// generate a new seed phrase
  /// optionally specify the language, passphrase and length
  /// returns the generated seed phrase
  static String generateSeedPhrase({
    Language language = Language.english,
    String passphrase = '',
    MnemonicLength length = MnemonicLength.words24,
  }) {
    final seed = Mnemonic.generate(
      language,
      length: length,
      passphrase: passphrase,
    );
    return seed.sentence;
  }

  void _seedCheck() {
    if (_userSeedPhrase == null) {
      throw Exception('Seed phrase is not set');
    }
  }

  static int keysetIdToInt(String keysetId) {
    BigInt number = BigInt.parse(keysetId, radix: 16);

    //BigInt modulus = BigInt.from(2).pow(31) - BigInt.one;
    /// precalculated for 2^31 - 1
    BigInt modulus = BigInt.from(2147483647);

    BigInt keysetIdInt = number % modulus;

    return keysetIdInt.toInt();
  }

  /// derive a secret and blinding factor from the seed phrase
  /// using the keysetId and counter
  /// throws an exception if the seed phrase is not set
  /// returns a [CashuSeedDeriveSecretResult] containing the secret and blinding factor in hex format
  CashuSeedDeriveSecretResult deriveSecret({
    required int counter,
    required String keysetId,
  }) {
    _seedCheck();

    final keysetIdInt = keysetIdToInt(keysetId);

    final mnemonicUnit8List = Uint8List.fromList(_userSeedPhrase!.seed);

    final masterKey = Bip32Keys.fromSeed(
      mnemonicUnit8List,
    );

    final pathKeySecret = masterKey.derivePath(
      "m/$derivationPurpose'/$derivationCoinType'/$keysetIdInt'/$counter'/0",
    );

    final pathKeyBlinding = masterKey.derivePath(
      "m/$derivationPurpose'/$derivationCoinType'/$keysetIdInt'/$counter'/1",
    );

    final pathKeySecretHex = hex.encode(pathKeySecret.private!.toList());

    final pathKeyBlindingHex = hex.encode(pathKeyBlinding.private!.toList());

    return CashuSeedDeriveSecretResult(
      secretHex: pathKeySecretHex,
      blindingHex: pathKeyBlindingHex,
    );
  }
}
