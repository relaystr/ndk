import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  group('dev tests', () {
    test('proof storage upsert test - memCache', () async {
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
  });
}
