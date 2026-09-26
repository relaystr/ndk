import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import 'cashu_test_tools.dart';

/// Re-setting the very same [CashuUserSeedphrase] that was passed to
/// `NdkConfig.cashuUserSeedphrase` must derive the same seed: the init path and
/// the update path have to agree on the language and the passphrase, otherwise
/// the deterministic secrets change and previously minted proofs become
/// unspendable.
void main() {
  group('Cashu.setCashuSeedPhrase', () {
    test('keeps the language of the init path', () async {
      final spanish = CashuSeed.generateSeedPhrase(language: Language.spanish);
      final userSeedPhrase = CashuUserSeedphrase(
        seedPhrase: spanish,
        language: Language.spanish,
      );

      final fromInit = CashuTestTools.mockHttpCashu(seedPhrase: userSeedPhrase);
      final updated = CashuTestTools.mockHttpCashu();
      await updated.setCashuSeedPhrase(userSeedPhrase);

      expect(
        updated.getCashuSeed().getSeedBytes(),
        fromInit.getCashuSeed().getSeedBytes(),
      );
    });

    test('keeps the passphrase of the init path', () async {
      final sentence = CashuSeed.generateSeedPhrase();
      final userSeedPhrase = CashuUserSeedphrase(
        seedPhrase: sentence,
        passphrase: 'cashu-passphrase',
      );

      final fromInit = CashuTestTools.mockHttpCashu(seedPhrase: userSeedPhrase);
      final updated = CashuTestTools.mockHttpCashu();
      await updated.setCashuSeedPhrase(userSeedPhrase);

      expect(
        updated.getCashuSeed().getSeedBytes(),
        fromInit.getCashuSeed().getSeedBytes(),
      );

      // guards the assertion above: dropping the passphrase really does derive a
      // different seed, so the passphrase is what the previous code lost
      final withoutPassphrase = CashuTestTools.mockHttpCashu(
        seedPhrase: CashuUserSeedphrase(seedPhrase: sentence),
      );
      expect(
        withoutPassphrase.getCashuSeed().getSeedBytes(),
        isNot(fromInit.getCashuSeed().getSeedBytes()),
      );
    });
  });
}
