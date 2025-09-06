import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import 'cashu_test_tools.dart';

const devMintUrl = 'https://dev.mint.camelus.app';
const failingMintUrl = 'https://mint.example.com';
const mockMintUrl = "htps://mock.mint";

void main() {
  setUp(() {});

  group('spend tests - exceptions ', () {
    test("spend - amount", () {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      expect(
        () async => await ndk.cashu.initiateSpend(
          mintUrl: mockMintUrl,
          amount: -54444,
          unit: 'sat',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test("spend - no unit for mint", () {
      final cashu = CashuTestTools.mockHttpCashu();

      expect(
        () async => await cashu.initiateSpend(
          mintUrl: mockMintUrl,
          amount: 50,
          unit: 'voidunit',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test("spend - not enouth funds", () async {
      final cache = MemCacheManager();

      await cache.saveKeyset(
        CahsuKeyset(
          id: 'testKeyset',
          mintUrl: mockMintUrl,
          unit: 'sat',
          active: true,
          inputFeePPK: 0,
          mintKeyPairs: {
            CahsuMintKeyPair(
              amount: 1,
              pubkey: 'testPubKey-1',
            ),
            CahsuMintKeyPair(
              amount: 2,
              pubkey: 'testPubKey-2',
            ),
            CahsuMintKeyPair(
              amount: 4,
              pubkey: 'testPubKey-2',
            ),
          },
        ),
      );

      await cache.saveProofs(
        proofs: [
          CashuProof(
            keysetId: 'testKeyset',
            amount: 1,
            secret: 'testSecret-32',
            unblindedSig: '',
          )
        ],
        mintUrl: mockMintUrl,
      );

      final cashu = CashuTestTools.mockHttpCashu(customCache: cache);

      expect(
        () async => await cashu.initiateSpend(
          mintUrl: mockMintUrl,
          amount: 4,
          unit: 'sat',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('spend', () {
    test("spend - initiateSpend", () async {});
  });
}
