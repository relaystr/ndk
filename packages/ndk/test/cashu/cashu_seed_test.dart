import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_seed.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  final mnemonic =
      "half depart obvious quality work element tank gorilla view sugar picture humble";

  final keysetId = "009a1f293253e41e";

  final expectedSecrets = {
    "secret_0":
        "485875df74771877439ac06339e284c3acfcd9be7abf3bc20b516faeadfe77ae",
    "secret_1":
        "8f2b39e8e594a4056eb1e6dbb4b0c38ef13b1b2c751f64f810ec04ee35b77270",
    "secret_2":
        "bc628c79accd2364fd31511216a0fab62afd4a18ff77a20deded7b858c9860c8",
    "secret_3":
        "59284fd1650ea9fa17db2b3acf59ecd0f2d52ec3261dd4152785813ff27a33bf",
    "secret_4":
        "576c23393a8b31cc8da6688d9c9a96394ec74b40fdaf1f693a6bb84284334ea0"
  };

  final expectedBlindingFactors = {
    "r_0": "ad00d431add9c673e843d4c2bf9a778a5f402b985b8da2d5550bf39cda41d679",
    "r_1": "967d5232515e10b81ff226ecf5a9e2e2aff92d66ebc3edf0987eb56357fd6248",
    "r_2": "b20f47bb6ae083659f3aa986bfa0435c55c6d93f687d51a01f26862d9b9a4899",
    "r_3": "fb5fca398eb0b1deb955a2988b5ac77d32956155f1c002a373535211a2dfdc29",
    "r_4": "5f09bfbfe27c439a597719321e061e2e40aad4a36768bb2bcc3de547c9644bf9"
  };

  group('CashuSeedTests', () {
    test("keysetIdToInt", () {
      final result = CashuSeed.keysetIdToInt("009a1f293253e41e");

      expect(result, equals(864559728));
    });

    test('deriveSecret', () async {
      final seed = CashuSeed(userSeedPhrase: mnemonic);
      for (int i = 0; i < 5; i++) {
        final result = seed.deriveSecret(counter: i, keysetId: keysetId);

        expect(result.secretHex, equals(expectedSecrets["secret_$i"]));
        expect(result.blindingHex, equals(expectedBlindingFactors["r_$i"]));
      }
    });

    test('throw without mnemonic', () async {
      final seed = CashuSeed();

      expect(
        () => seed.deriveSecret(counter: 0, keysetId: keysetId),
        throwsA(isA<Exception>()),
      );
    });

    test('setting mnemonic', () async {
      final seed = CashuSeed();
      seed.setSeedPhrase(seedPhrase: mnemonic);

      final result = seed.deriveSecret(counter: 0, keysetId: keysetId);

      expect(result.secretHex, equals(expectedSecrets["secret_0"]));
      expect(result.blindingHex, equals(expectedBlindingFactors["r_0"]));
    });

    test('generating seedPhrase', () async {
      final generated = CashuSeed.generateSeedPhrase(
        length: MnemonicLength.words24,
      );
      expect(generated.split(' ').length, equals(24));

      final seed = CashuSeed(userSeedPhrase: generated);
      final result = seed.deriveSecret(counter: 0, keysetId: keysetId);
      expect(result.secretHex.length, equals(64));
      expect(result.blindingHex.length, equals(64));
    });
  });
}
