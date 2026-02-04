import 'package:ndk/domain_layer/entities/cashu/cashu_keyset.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_proof_select.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  List<CahsuMintKeyPair> generateWalletKeyPairs(int length) {
    return List.generate(length, (index) {
      int amount = 1 << index; // 2^index: 1, 2, 4, 8, 16, 32, etc.
      return CahsuMintKeyPair(amount: amount, pubkey: "pubkey${amount}");
    });
  }

  group('proof select', () {
    final List<CashuProof> myproofs = [
      CashuProof(
        amount: 50,
        keysetId: 'test-keyset',
        secret: "proofSecret50-0",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 4,
        keysetId: 'test-keyset',
        secret: "proofSecret4-0",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 2,
        keysetId: 'test-keyset',
        secret: "proofSecret2-0",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 50,
        keysetId: 'test-keyset',
        secret: "proofSecret50-1",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 4,
        keysetId: 'test-keyset',
        secret: "proofSecret4-1",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 2,
        keysetId: 'test-keyset',
        secret: "proofSecret2-1",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 101,
        keysetId: 'test-keyset',
        secret: "proofSecret101-0",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 1,
        keysetId: 'test-keyset',
        secret: "proofSecret1-0",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 1,
        keysetId: 'other-keyset',
        secret: "proofSecret1-1",
        unblindedSig: "",
      ),
      CashuProof(
        amount: 2,
        keysetId: 'other-keyset',
        secret: "proofSecret2-2",
        unblindedSig: "",
      ),
    ];

    List<CahsuKeyset> keysets = [
      CahsuKeyset(
        mintUrl: "debug",
        unit: "test",
        active: true,
        id: 'test-keyset',
        inputFeePPK: 1000,
        mintKeyPairs: generateWalletKeyPairs(10).toSet(),
        fetchedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      CahsuKeyset(
        mintUrl: "debug",
        unit: "test",
        active: false,
        id: 'other-keyset',
        inputFeePPK: 100,
        mintKeyPairs: generateWalletKeyPairs(2).toSet(),
        fetchedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    ];

    test('split test - exact', () async {
      final exact = CashuProofSelect.selectProofsForSpending(
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
          () => CashuProofSelect.selectProofsForSpending(
              proofs: myproofs, targetAmount: 9999999, keysets: keysets),
          throwsA(isA<Exception>()));
    });

    test('split test - combination', () {
      const target = 52;
      final combination = CashuProofSelect.selectProofsForSpending(
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
      final combination = CashuProofSelect.selectProofsForSpending(
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
      final combination = CashuProofSelect.selectProofsForSpending(
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
        CashuProof(
            amount: 10,
            keysetId: 'test-keyset',
            secret: "",
            unblindedSig: ""), // 1000 ppk
        CashuProof(
            amount: 20,
            keysetId: 'other-keyset',
            secret: "",
            unblindedSig: ""), // 100 ppk
        CashuProof(
            amount: 30,
            keysetId: 'test-keyset',
            secret: "",
            unblindedSig: ""), // 1000 ppk
      ];

      final fees = CashuProofSelect.calculateFees(mixedProofs, keysets);
      // 2100 ppk total = 3 sats (rounded up)
      expect(fees, 3);
    });

    test('fee calculation - breakdown by keyset', () {
      final mixedProofs = [
        CashuProof(
            amount: 10, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
        CashuProof(
            amount: 20, keysetId: 'other-keyset', secret: "", unblindedSig: ""),
        CashuProof(
            amount: 30, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
      ];

      final breakdown = CashuProofSelect.calculateFeesWithBreakdown(
        proofs: mixedProofs,
        keysets: keysets,
      );

      expect(breakdown['totalFees'], 3);
      expect(breakdown['totalPpk'], 2100);
      expect(breakdown['feesByKeyset']['test-keyset'], 2); // 2000 ppk = 2 sats
      expect(breakdown['feesByKeyset']['other-keyset'], 1); // 100 ppk = 1 sat
    });

    test('fee calculation - empty proofs', () {
      final fees = CashuProofSelect.calculateFees([], keysets);
      expect(fees, 0);

      final breakdown = CashuProofSelect.calculateFeesWithBreakdown(
        proofs: [],
        keysets: keysets,
      );
      expect(breakdown['totalFees'], 0);
      expect(breakdown['feesByKeyset'], isEmpty);
    });

    test('fee calculation - unknown keyset throws exception', () {
      final invalidProofs = [
        CashuProof(
            amount: 10,
            keysetId: 'unknown-keyset',
            secret: "",
            unblindedSig: ""),
      ];

      expect(
        () => CashuProofSelect.calculateFees(invalidProofs, keysets),
        throwsA(isA<Exception>()),
      );
    });

    test('proof sorting - amount priority', () {
      final unsortedProofs = [
        CashuProof(
            amount: 10, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
        CashuProof(
            amount: 50, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
        CashuProof(
            amount: 25, keysetId: 'test-keyset', secret: "", unblindedSig: ""),
      ];

      final sorted =
          CashuProofSelect.sortProofsOptimally(unsortedProofs, keysets);
      expect(sorted[0].amount, 50);
      expect(sorted[1].amount, 25);
      expect(sorted[2].amount, 10);
    });

    test('proof sorting - fee priority when amounts equal', () {
      final equalAmountProofs = [
        CashuProof(
            amount: 10,
            keysetId: 'test-keyset',
            secret: "",
            unblindedSig: ""), // 1000 ppk
        CashuProof(
            amount: 10,
            keysetId: 'other-keyset',
            secret: "",
            unblindedSig: ""), // 100 ppk
      ];

      final sorted =
          CashuProofSelect.sortProofsOptimally(equalAmountProofs, keysets);
      // Lower fee keyset should come first
      expect(sorted[0].keysetId, 'other-keyset');
      expect(sorted[1].keysetId, 'test-keyset');
    });

    test('active keyset selection', () {
      final activeKeyset = CashuProofSelect.getActiveKeyset(keysets);
      expect(activeKeyset?.id, 'test-keyset');
      expect(activeKeyset?.active, true);
    });

    test('selection with no keysets throws exception', () {
      expect(
        () => CashuProofSelect.selectProofsForSpending(
          proofs: myproofs,
          targetAmount: 50,
          keysets: [],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('selection prefers cheaper keysets', () {
      final cheaperFirst = CashuProofSelect.selectProofsForSpending(
        proofs: [
          CashuProof(
              amount: 50,
              keysetId: 'test-keyset',
              secret: "",
              unblindedSig: ""), // 1000 ppk
          CashuProof(
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
          (i) => CashuProof(
              amount: 1,
              keysetId: 'test-keyset',
              secret: "",
              unblindedSig: ""));

      expect(
        () => CashuProofSelect.selectProofsForSpending(
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
        CashuProof(
            amount: 10,
            keysetId: 'test-keyset',
            secret: "proofSecret10-0",
            unblindedSig: ""), // 1000 ppk
        CashuProof(
            amount: 20,
            keysetId: 'test-keyset',
            secret: "proofSecret20-0",
            unblindedSig: ""), // 1000 ppk
        CashuProof(
            amount: 30,
            keysetId: 'other-keyset',
            secret: "proofSecret30-0",
            unblindedSig: ""), // 100 ppk
        CashuProof(
            amount: 40,
            keysetId: 'other-keyset',
            secret: "proofSecret40-0",
            unblindedSig: ""), // 100 ppk
      ];

      final result = CashuProofSelect.selectProofsForSpending(
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
          (i) => CashuProof(
              amount: 1,
              keysetId: 'test-keyset',
              secret: "",
              unblindedSig: ""));

      // fee for each is 1 + 1 sat => never enough to spend

      expect(
          () => CashuProofSelect.selectProofsForSpending(
                proofs: singleSatProofs,
                targetAmount: 1,
                keysets: keysets,
              ),
          throwsA(isA<Exception>()));
    });

    test('large value - should converge quickly', () {
      // Create many medium-sized proofs that need to be combined for a large amount
      final largeValueProofs = [
        // Add some larger proofs
        ...List.generate(
            10,
            (i) => CashuProof(
                amount: 1000,
                keysetId: 'test-keyset',
                secret: "proof1000-$i",
                unblindedSig: "")),
        // Add medium proofs
        ...List.generate(
            20,
            (i) => CashuProof(
                amount: 100,
                keysetId: 'test-keyset',
                secret: "proof100-$i",
                unblindedSig: "")),
        // Add smaller proofs
        ...List.generate(
            30,
            (i) => CashuProof(
                amount: 10,
                keysetId: 'test-keyset',
                secret: "proof10-$i",
                unblindedSig: "")),
      ];

      // Target a large amount (8000 sats) - should converge without hitting max iterations
      final result = CashuProofSelect.selectProofsForSpending(
        proofs: largeValueProofs,
        targetAmount: 8000,
        keysets: keysets,
      );

      expect(result.selectedProofs.isNotEmpty, true);
      expect(result.totalSelected - result.fees, greaterThanOrEqualTo(8000));
    });

    test('very large value with smaller proofs - stress test', () {
      // This test reproduces the convergence issue
      final manyProofs = [
        ...List.generate(
            10,
            (i) => CashuProof(
                amount: 500,
                keysetId: 'test-keyset',
                secret: "proof500-$i",
                unblindedSig: "")),
        ...List.generate(
            50,
            (i) => CashuProof(
                amount: 50,
                keysetId: 'test-keyset',
                secret: "proof50-$i",
                unblindedSig: "")),
      ];

      // Target 7000 sats - this would previously fail to converge
      final result = CashuProofSelect.selectProofsForSpending(
        proofs: manyProofs,
        targetAmount: 7000,
        keysets: keysets,
      );

      expect(result.selectedProofs.isNotEmpty, true);
      expect(result.totalSelected - result.fees, greaterThanOrEqualTo(7000));
    });

    test('extreme large value - 50k sats', () {
      // Extreme test with very large target amount
      final extremeProofs = [
        ...List.generate(
            30,
            (i) => CashuProof(
                amount: 2000,
                keysetId: 'test-keyset',
                secret: "proof2000-$i",
                unblindedSig: "")),
        ...List.generate(
            100,
            (i) => CashuProof(
                amount: 100,
                keysetId: 'test-keyset',
                secret: "proof100-$i",
                unblindedSig: "")),
      ];

      // Target 50000 sats - should still converge quickly with optimized algorithm
      final result = CashuProofSelect.selectProofsForSpending(
        proofs: extremeProofs,
        targetAmount: 50000,
        keysets: keysets,
      );

      expect(result.selectedProofs.isNotEmpty, true);
      expect(result.totalSelected - result.fees, greaterThanOrEqualTo(50000));
      // Should converge in very few iterations thanks to greedy initial selection
    });

    test('performance benchmark - 200 proofs, 100k sats', () {
      // Performance test with many proofs
      final manyProofs = [
        ...List.generate(
            50,
            (i) => CashuProof(
                amount: 5000,
                keysetId: 'test-keyset',
                secret: "proof5000-$i",
                unblindedSig: "")),
        ...List.generate(
            150,
            (i) => CashuProof(
                amount: 100,
                keysetId: 'test-keyset',
                secret: "proof100-$i",
                unblindedSig: "")),
      ];

      final stopwatch = Stopwatch()..start();

      final result = CashuProofSelect.selectProofsForSpending(
        proofs: manyProofs,
        targetAmount: 100000,
        keysets: keysets,
      );

      stopwatch.stop();

      expect(result.selectedProofs.isNotEmpty, true);
      expect(result.totalSelected - result.fees, greaterThanOrEqualTo(100000));

      // Should be fast (under 50ms for 200 proofs)
      print(
          'Selection time for 200 proofs: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
