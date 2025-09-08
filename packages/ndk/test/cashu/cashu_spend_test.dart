import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
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
    test("spend - initiateSpend", () async {
      final cache = MemCacheManager();

      final client = HttpRequestDS(http.Client());
      final cashuRepo = CashuRepoImpl(client: client);
      final cashu = Cashu(cashuRepo: cashuRepo, cacheManager: cache);

      const fundAmount = 32;
      const fundUnit = "sat";

      final draftTransaction = await cashu.initiateFund(
        mintUrl: devMintUrl,
        amount: fundAmount,
        unit: fundUnit,
        method: "bolt11",
      );
      final transactionStream =
          cashu.retriveFunds(draftTransaction: draftTransaction);

      final transaction = await transactionStream.last;
      expect(transaction.state, WalletTransactionState.completed);

      final spendWithoutSplit = await cashu.initiateSpend(
        mintUrl: devMintUrl,
        amount: 3,
        unit: fundUnit,
      );

      final spendwithSplit = await cashu.initiateSpend(
        mintUrl: devMintUrl,
        amount: 1,
        unit: fundUnit,
      );

      expect(spendWithoutSplit.token.toV4TokenString(), isNotEmpty);
      expect(spendwithSplit.token.toV4TokenString(), isNotEmpty);

      final balance =
          await cashu.getBalanceMintUnit(unit: "sat", mintUrl: devMintUrl);
      expect(balance, equals(fundAmount - 4));

      final pendingProofs =
          await cache.getProofs(state: CashuProofState.pending);
      expect(pendingProofs, isEmpty);

      final spendProofs = await cache.getProofs(state: CashuProofState.spend);
      expect(spendProofs, isNotEmpty);
    });
  });
}
