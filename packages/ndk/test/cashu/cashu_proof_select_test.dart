import 'package:ndk/domain_layer/entities/cashu/wallet_cashu_proof.dart';
import 'package:ndk/domain_layer/usecases/cashu_wallet/cashu_wallet_proof_select.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  group('proof select', () {
    final List<WalletCashuProof> myproofs = [
      WalletCashuProof(
        amount: 50,
        keysetId: 'test-keyset',
        secret: "",
        unblindedSig: "",
      ),
      WalletCashuProof(
        amount: 4,
        keysetId: 'test-keyset',
        secret: "",
        unblindedSig: "",
      ),
      WalletCashuProof(
        amount: 2,
        keysetId: 'test-keyset',
        secret: "",
        unblindedSig: "",
      ),
      WalletCashuProof(
        amount: 50,
        keysetId: 'test-keyset',
        secret: "",
        unblindedSig: "",
      ),
      WalletCashuProof(
        amount: 4,
        keysetId: 'test-keyset',
        secret: "",
        unblindedSig: "",
      ),
      WalletCashuProof(
        amount: 2,
        keysetId: 'test-keyset',
        secret: "",
        unblindedSig: "",
      ),
      WalletCashuProof(
        amount: 101,
        keysetId: 'test-keyset',
        secret: "",
        unblindedSig: "",
      ),
    ];

    test('split test - exact', () async {
      final exact =
          CashuWalletProofSelect.selectProofsForSpending(myproofs, 50);
      expect(exact.selectedProofs.length, 1);
      expect(exact.selectedProofs.first.amount, 50);
      expect(exact.totalSelected, 50);
      expect(exact.needsSplit, false);
    });

    test('split test - insufficient', () {
      expect(
          () =>
              CashuWalletProofSelect.selectProofsForSpending(myproofs, 9999999),
          throwsA(isA<Exception>()));
    });

    test('split test - combination', () {
      const target = 52;
      final combination =
          CashuWalletProofSelect.selectProofsForSpending(myproofs, target);
      expect(combination.selectedProofs.length, 2);
      expect(combination.totalSelected, target);
      expect(combination.needsSplit, false);
    });

    test('split test - combination - greedy', () {
      const target = 103;
      final combination =
          CashuWalletProofSelect.selectProofsForSpending(myproofs, target);
      expect(combination.selectedProofs.length, 2);
      expect(combination.totalSelected, target);
      expect(combination.needsSplit, false);
    });

    test('split test - combination - split needed', () {
      const target = 1;
      final combination =
          CashuWalletProofSelect.selectProofsForSpending(myproofs, target);
      expect(combination.needsSplit, true);
      expect(combination.totalSelected > target, isTrue);
      expect(combination.totalSelected - combination.splitAmount, target);
    });
  });
}
