import 'package:bip39_mnemonic/bip39_mnemonic.dart';

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
