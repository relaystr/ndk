import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  group('dev tests', () {
    test('fund', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final mintUrl = 'http://127.0.0.1:8085';

      final fundResponse = await ndk.cashu.initiateFund(
        mintUrl: mintUrl,
        amount: 52,
        unit: 'sat',
        method: 'bolt11',
      );

      print(fundResponse);
    });

    test('parse mint info', () async {
      final mintUrl = 'http://127.0.0.1:8085';

      final HttpRequestDS httpRequestDS = HttpRequestDS(http.Client());

      final repo = CashuRepoImpl(client: httpRequestDS);

      final mintInfo = await repo.getMintInfo(mintUrl: mintUrl);

      print(mintInfo);
    });

    test('proof storage upsert test', () async {
      CacheManager cacheManager = MemCacheManager();

      final proof1 = CashuProof(
        keysetId: 'testKeysetId',
        amount: 10,
        secret: "secret1",
        unblindedSig: 'testSig1',
        state: CashuProofState.unspend,
      );

      final proof2 = CashuProof(
        keysetId: 'testKeysetId',
        amount: 2,
        secret: "secret2",
        unblindedSig: 'testSig2',
        state: CashuProofState.unspend,
      );

      final List<CashuProof> proofs = [
        proof1,
        proof2,
      ];

      await cacheManager.saveProofs(proofs: proofs, mintUrl: "testmint");

      proof1.state = CashuProofState.pending;

      await cacheManager.saveProofs(proofs: [proof1], mintUrl: "testmint");

      final loadedProofs = await cacheManager.getProofs(
        mintUrl: "testmint",
        state: CashuProofState.unspend,
      );

      expect(loadedProofs.length, equals(1));
      expect(loadedProofs[0].state, equals(CashuProofState.unspend));

      expect(loadedProofs[0].amount, equals(2));
    });
  }, skip: true);
}
