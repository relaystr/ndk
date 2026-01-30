import 'package:bip39_mnemonic/bip39_mnemonic.dart';
export 'package:bip39_mnemonic/bip39_mnemonic.dart'
    show Language, MnemonicLength;

class CashuUserSeedphrase {
  final String seedPhrase;
  final Language language;
  final String passphrase;

  CashuUserSeedphrase({
    required this.seedPhrase,
    this.language = Language.english,
    this.passphrase = '',
  });
}
