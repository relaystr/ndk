import 'package:ndk/domain_layer/entities/cashu/wallet_cashu_keyset.dart';
import 'package:ndk/domain_layer/entities/cashu/wallet_cashu_proof.dart';
import 'package:ndk/domain_layer/usecases/cashu_wallet/cashu_wallet_proof_select.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  List<WalletCahsuMintKeyPair> generateWalletKeyPairs(int length) {
    return List.generate(length, (index) {
      int amount = 1 << index; // 2^index: 1, 2, 4, 8, 16, 32, etc.
      return WalletCahsuMintKeyPair(amount: amount, pubkey: "pubkey${amount}");
    });
  }

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
      WalletCashuProof(
        amount: 1,
        keysetId: 'test-keyset',
        secret: "",
        unblindedSig: "",
      ),
      WalletCashuProof(
        amount: 1,
        keysetId: 'other-keyset',
        secret: "",
        unblindedSig: "",
      ),
      WalletCashuProof(
        amount: 2,
        keysetId: 'other-keyset',
        secret: "",
        unblindedSig: "",
      ),
    ];

    List<WalletCahsuKeyset> keysets = [
      WalletCahsuKeyset(
        mintURL: "debug",
        unit: "test",
        active: true,
        id: 'test-keyset',
        inputFeePPK: 1000,
        mintKeyPairs: generateWalletKeyPairs(10).toSet(),
        fetchedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      WalletCahsuKeyset(
        mintURL: "debug",
        unit: "test",
        active: false,
        id: 'other-keyset',
        inputFeePPK: 100,
        mintKeyPairs: generateWalletKeyPairs(2).toSet(),
        fetchedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    ];

    test('split test - exact', () async {
      final exact = CashuWalletProofSelect.selectProofsForSpending(
        proofs: myproofs,
        keysets: keysets,
        targetAmount: 50,
      );
      expect(exact.selectedProofs.length, 2); // exact + fees
      expect(exact.fees, 2);
      expect(exact.selectedProofs.first.amount, 50);
      expect(exact.selectedProofs.last.keysetId, "other-keyset");

      expect(exact.totalSelected, 52);
      expect(exact.needsSplit, false);
    });

    test('split test - insufficient', () {
      expect(
          () => CashuWalletProofSelect.selectProofsForSpending(
              proofs: myproofs, targetAmount: 9999999, keysets: keysets),
          throwsA(isA<Exception>()));
    });

    test('split test - combination', () {
      const target = 52;
      final combination = CashuWalletProofSelect.selectProofsForSpending(
        proofs: myproofs,
        keysets: keysets,
        targetAmount: target,
      );
      expect(combination.selectedProofs.length, 2);
      expect(combination.fees, 2);
      expect(combination.selectedProofs.first.amount, 50);
      expect(combination.selectedProofs.last.amount, 4);

      expect(combination.totalSelected - combination.fees, target);
      expect(combination.needsSplit, false);
    });

    test('split test - combination - greedy', () {
      const target = 103;
      final combination = CashuWalletProofSelect.selectProofsForSpending(
        proofs: myproofs,
        keysets: keysets,
        targetAmount: target,
      );
      expect(combination.selectedProofs.length, 2);
      expect(combination.fees, 2);
      expect(combination.totalSelected - combination.fees, target);
      expect(combination.needsSplit, false);
    });

    test('split test - combination - split needed', () {
      const target = 123;
      final combination = CashuWalletProofSelect.selectProofsForSpending(
        proofs: myproofs,
        keysets: keysets,
        targetAmount: target,
      );
      expect(combination.needsSplit, true);
      expect(combination.totalSelected > target, isTrue);
      expect(
          combination.totalSelected -
              combination.splitAmount -
              combination.fees,
          target);
    });

    test('fee calculation - mixed keysets', () {
      final mixedProofs = [
        WalletCashuProof(
            amount: 10,
            keysetId: 'test-keyset',
            secret: "",
            unblindedSig: ""), // 1000 ppk
        WalletCashuProof(
            amount: 20,
            keysetId: 'other-keyset',
            secret: "",
            unblindedSig: ""), // 100 ppk
        WalletCashuProof(
            amount: 30,
            keysetId: 'test-keyset',
            secret: "",
            unblindedSig: ""), // 1000 ppk
      ];

      final fees = CashuWalletProofSelect.calculateFees(mixedProofs, keysets);
      // 2100 ppk total = 3 sats (rounded up)
      expect(fees, 3);
    });

    test('fee calculation - breakdown by keyset', () {
      final mixedProofs = [
        WalletCashuProof(
            amount: 10, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
        WalletCashuProof(
            amount: 20, keysetId: 'other-keyset', secret: "", unblindedSig: ""),
        WalletCashuProof(
            amount: 30, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
      ];

      final breakdown = CashuWalletProofSelect.calculateFeesWithBreakdown(
        proofs: mixedProofs,
        keysets: keysets,
      );

      expect(breakdown['totalFees'], 3);
      expect(breakdown['totalPpk'], 2100);
      expect(breakdown['feesByKeyset']['test-keyset'], 2); // 2000 ppk = 2 sats
      expect(breakdown['feesByKeyset']['other-keyset'], 1); // 100 ppk = 1 sat
    });

    test('fee calculation - empty proofs', () {
      final fees = CashuWalletProofSelect.calculateFees([], keysets);
      expect(fees, 0);

      final breakdown = CashuWalletProofSelect.calculateFeesWithBreakdown(
        proofs: [],
        keysets: keysets,
      );
      expect(breakdown['totalFees'], 0);
      expect(breakdown['feesByKeyset'], isEmpty);
    });

    test('fee calculation - unknown keyset throws exception', () {
      final invalidProofs = [
        WalletCashuProof(
            amount: 10,
            keysetId: 'unknown-keyset',
            secret: "",
            unblindedSig: ""),
      ];

      expect(
        () => CashuWalletProofSelect.calculateFees(invalidProofs, keysets),
        throwsA(isA<Exception>()),
      );
    });

    test('proof sorting - amount priority', () {
      final unsortedProofs = [
        WalletCashuProof(
            amount: 10, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
        WalletCashuProof(
            amount: 50, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
        WalletCashuProof(
            amount: 25, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
      ];

      final sorted =
          CashuWalletProofSelect.sortProofsOptimally(unsortedProofs, keysets);
      expect(sorted[0].amount, 50);
      expect(sorted[1].amount, 25);
      expect(sorted[2].amount, 10);
    });

    test('proof sorting - fee priority when amounts equal', () {
      final equalAmountProofs = [
        WalletCashuProof(
            amount: 10,
            keysetId: 'test-keyset',
            secret: "",
            unblindedSig: ""), // 1000 ppk
        WalletCashuProof(
            amount: 10,
            keysetId: 'other-keyset',
            secret: "",
            unblindedSig: ""), // 100 ppk
      ];

      final sorted = CashuWalletProofSelect.sortProofsOptimally(
          equalAmountProofs, keysets);
      // Lower fee keyset should come first
      expect(sorted[0].keysetId, 'other-keyset');
      expect(sorted[1].keysetId, 'test-keyset');
    });

    test('active keyset selection', () {
      final activeKeyset = CashuWalletProofSelect.getActiveKeyset(keysets);
      expect(activeKeyset?.id, 'test-keyset');
      expect(activeKeyset?.active, true);
    });

    test('selection with no keysets throws exception', () {
      expect(
        () => CashuWalletProofSelect.selectProofsForSpending(
          proofs: myproofs,
          targetAmount: 50,
          keysets: [],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('selection prefers cheaper keysets', () {
      final cheaperFirst = CashuWalletProofSelect.selectProofsForSpending(
        proofs: [
          WalletCashuProof(
              amount: 50,
              keysetId: 'test-keyset',
              secret: "",
              unblindedSig: ""), // 1000 ppk
          WalletCashuProof(
              amount: 50,
              keysetId: 'other-keyset',
              secret: "",
              unblindedSig: ""), // 100 ppk
        ],
        targetAmount: 49,
        keysets: keysets,
      );

      // Should prefer the cheaper keyset when amounts are equal
      expect(cheaperFirst.selectedProofs.length, 1);
      expect(cheaperFirst.selectedProofs.first.keysetId, 'other-keyset');
      expect(cheaperFirst.fees, 1); // 100 ppk = 1 sat
    });

    test('maximum iterations exceeded', () {
      final manySmallProofs = List.generate(
          20,
          (i) => WalletCashuProof(
              amount: 1,
              keysetId: 'test-keyset',
              secret: "",
              unblindedSig: ""));

      expect(
        () => CashuWalletProofSelect.selectProofsForSpending(
          proofs: manySmallProofs,
          targetAmount: 50,
          keysets: keysets,
          maxIterations: 3,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('fee breakdown accuracy', () {
      final mixedProofs = [
        WalletCashuProof(
            amount: 10,
            keysetId: 'test-keyset',
            secret: "",
            unblindedSig: ""), // 1000 ppk
        WalletCashuProof(
            amount: 20,
            keysetId: 'test-keyset',
            secret: "",
            unblindedSig: ""), // 1000 ppk
        WalletCashuProof(
            amount: 30,
            keysetId: 'other-keyset',
            secret: "",
            unblindedSig: ""), // 100 ppk
        WalletCashuProof(
            amount: 40,
            keysetId: 'other-keyset',
            secret: "",
            unblindedSig: ""), // 100 ppk
      ];

      final result = CashuWalletProofSelect.selectProofsForSpending(
        proofs: mixedProofs,
        targetAmount: 90,
        keysets: keysets,
      );

      // Total: 2200 ppk = 3 sats
      expect(result.fees, 3);
      expect(result.feesByKeyset['test-keyset'], 2); // 2000 ppk = 2 sats
      expect(result.feesByKeyset['other-keyset'], 1); // 200 ppk = 1 sat
      expect(result.totalSelected, 100);
      expect(result.needsSplit, true);
      expect(result.splitAmount, 7); // 100 - 90 - 3 = 7
    });

    test('single sat amounts with high fees - impossible', () {
      final singleSatProofs = List.generate(
          11,
          (i) => WalletCashuProof(
              amount: 1,
              keysetId: 'test-keyset',
              secret: "",
              unblindedSig: ""));

      // fee for each is 1 + 1 sat => never enough to spend

      expect(
          () => CashuWalletProofSelect.selectProofsForSpending(
                proofs: singleSatProofs,
                targetAmount: 1,
                keysets: keysets,
              ),
          throwsA(isA<Exception>()));
    });
  });
}
