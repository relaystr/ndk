import '../../entities/cashu/cashu_keyset.dart';
import '../../entities/cashu/cashu_blinded_message.dart';
import '../../entities/cashu/cashu_proof.dart';
import '../../repositories/cashu_key_derivation.dart';
import '../../repositories/cashu_repo.dart';

import 'cashu_bdhke.dart';
import 'cashu_cache_decorator.dart';
import 'cashu_seed.dart';
import 'cashu_tools.dart';

class ProofSelectionResult {
  final List<CashuProof> selectedProofs;
  final int totalSelected;
  final int fees;

  /// amount that needs to be split
  final int splitAmount;
  final bool needsSplit;

  /// breakdown by keyset
  final Map<String, int> feesByKeyset;

  ProofSelectionResult({
    required this.selectedProofs,
    required this.totalSelected,
    required this.fees,
    required this.splitAmount,
    required this.needsSplit,
    required this.feesByKeyset,
  });
}

class SplitResult {
  final List<CashuProof> exactProofs;
  final List<CashuProof> changeProofs;

  SplitResult({
    required this.exactProofs,
    required this.changeProofs,
  });
}

class CashuProofSelect {
  final CashuRepo _cashuRepo;

  final CashuKeyDerivation _cashuSeedSecretGenerator;

  CashuProofSelect({
    required CashuRepo cashuRepo,
    required CashuKeyDerivation cashuSeedSecretGenerator,
  })  : _cashuRepo = cashuRepo,
        _cashuSeedSecretGenerator = cashuSeedSecretGenerator;

  /// Find keyset by ID from list
  static CahsuKeyset? _findKeysetById(
      List<CahsuKeyset> keysets, String keysetId) {
    try {
      return keysets.firstWhere((keyset) => keyset.id == keysetId);
    } catch (e) {
      return null;
    }
  }

  /// Calculate fees for a list of proofs across multiple keysets
  static int calculateFees(
    List<CashuProof> proofs,
    List<CahsuKeyset> keysets,
  ) {
    if (proofs.isEmpty) return 0;

    int sumFees = 0;
    for (final proof in proofs) {
      final keyset = _findKeysetById(keysets, proof.keysetId);
      if (keyset != null) {
        sumFees += keyset.inputFeePPK;
      } else {
        throw Exception(
            'Keyset not found for proof with keyset ID: ${proof.keysetId}');
      }
    }

    /// Round up: (sumFees + 999) // 1000
    /// @see nut02
    return ((sumFees + 999) ~/ 1000);
  }

  /// Calculate fees with breakdown by keyset
  static Map<String, dynamic> calculateFeesWithBreakdown({
    required List<CashuProof> proofs,
    required List<CahsuKeyset> keysets,
  }) {
    if (proofs.isEmpty) {
      return {
        'totalFees': 0,
        'feesByKeyset': <String, int>{},
        'ppkByKeyset': <String, int>{},
      };
    }

    final Map<String, int> feesByKeyset = {};
    final Map<String, int> ppkByKeyset = {};
    int totalPpk = 0;

    // Group proofs by keyset and calculate fees
    for (final proof in proofs) {
      final keysetId = proof.keysetId;
      final keyset = _findKeysetById(keysets, keysetId);

      if (keyset == null) {
        throw Exception('Keyset not found for proof with keyset ID: $keysetId');
      }

      final inputFeePpk = keyset.inputFeePPK;
      ppkByKeyset[keysetId] = (ppkByKeyset[keysetId] ?? 0) + inputFeePpk;
      totalPpk += inputFeePpk;
    }

    // Convert PPK to actual fees (single rounding approach)
    final totalFees = ((totalPpk + 999) ~/ 1000);

    // Calculate individual keyset fees for breakdown (informational)
    for (final entry in ppkByKeyset.entries) {
      final keysetFee = ((entry.value + 999) ~/ 1000);
      feesByKeyset[entry.key] = keysetFee;
    }

    return {
      'totalFees': totalFees,
      'feesByKeyset': feesByKeyset,
      'ppkByKeyset': ppkByKeyset,
      'totalPpk': totalPpk,
    };
  }

  /// Get the active keyset for creating new outputs
  static CahsuKeyset? getActiveKeyset(List<CahsuKeyset> keysets) {
    try {
      return keysets.firstWhere((keyset) => keyset.active);
    } catch (e) {
      return null; // No active keyset found
    }
  }

  /// Sort proofs optimally considering both amount and fees
  static List<CashuProof> sortProofsOptimally(
    List<CashuProof> proofs,
    List<CahsuKeyset> keysets,
  ) {
    return List<CashuProof>.from(proofs)
      ..sort((a, b) {
        // Primary: prefer larger amounts
        final amountComparison = b.amount.compareTo(a.amount);
        if (amountComparison != 0) return amountComparison;

        // Secondary: prefer lower fee keysets
        final keysetA = _findKeysetById(keysets, a.keysetId);
        final keysetB = _findKeysetById(keysets, b.keysetId);
        final feeA = keysetA?.inputFeePPK ?? 0;
        final feeB = keysetB?.inputFeePPK ?? 0;

        // Lower fees first
        final feeComparison = feeA.compareTo(feeB);
        if (feeComparison != 0) return feeComparison;

        // Tertiary: prefer active keysets
        final activeA = keysetA?.active ?? false;
        final activeB = keysetB?.active ?? false;
        return activeB
            .toString()
            .compareTo(activeA.toString()); // true comes before false
      });
  }

  /// Swaps proofs in target amount and change
  Future<SplitResult> performSplit({
    required String mint,
    required List<CashuProof> proofsToSplit,
    required int targetAmount,
    required int changeAmount,
    required List<CahsuKeyset> keysets,
    required CashuCacheDecorator cacheManagerCashu,
    required CashuSeed cashuSeed,
  }) async {
    final activeKeyset = getActiveKeyset(keysets);

    if (activeKeyset == null) {
      throw Exception('No active keyset found for mint: $mint');
    }

    if (targetAmount <= 0 || changeAmount < 0) {
      throw Exception('Invalid target or change amount');
    }

    // split the amounts by power of 2
    final targetAmountsSplit = CashuTools.splitAmount(targetAmount);

    final changeAmountsSplit = CashuTools.splitAmount(changeAmount);

    final outputs = [
      // amount we want to spend
      ...targetAmountsSplit,

      // change to keep
      ...changeAmountsSplit,
    ];

    final blindedMessagesOutputs = await CashuBdhke.createBlindedMsgForAmounts(
      keysetId: activeKeyset.id,
      amounts: outputs,
      cacheManager: cacheManagerCashu,
      cashuSeed: cashuSeed,
      mintUrl: mint,
      cashuSeedSecretGenerator: _cashuSeedSecretGenerator,
    );

    // sort to increase privacy
    blindedMessagesOutputs.sort(
      (a, b) => a.amount.compareTo(b.amount),
    );

    final blindedSignatures = await _cashuRepo.swap(
      mintUrl: mint,
      proofs: proofsToSplit,
      outputs: blindedMessagesOutputs
          .map(
            (e) => CashuBlindedMessage(
              amount: e.amount,
              id: e.blindedMessage.id,
              blindedMessage: e.blindedMessage.blindedMessage,
            ),
          )
          .toList(),
    );

    final myUnblindedTokens = CashuBdhke.unblindSignatures(
      mintSignatures: blindedSignatures,
      blindedMessages: blindedMessagesOutputs,
      mintPublicKeys: activeKeyset,
    );

    final List<CashuProof> exactProofs = [];
    final List<CashuProof> changeProofs = [];

    List<int> targetAmountsWorkingList = List.from(targetAmountsSplit);
    for (final proof in myUnblindedTokens) {
      if (targetAmountsWorkingList.contains(proof.amount)) {
        exactProofs.add(proof);
        targetAmountsWorkingList.remove(proof.amount);
      } else {
        changeProofs.add(proof);
      }
    }

    return SplitResult(
      /// first proofs is exact amount
      exactProofs: exactProofs,

      /// change
      changeProofs: changeProofs,
    );
  }

  /// Selects proofs for spending target amount with multiple keysets
  static ProofSelectionResult selectProofsForSpending({
    required List<CashuProof> proofs,
    required int targetAmount,
    required List<CahsuKeyset> keysets,
    int maxIterations = 15,
  }) {
    if (keysets.isEmpty) {
      throw Exception('No keysets provided');
    }

    final sortedProofs = sortProofsOptimally(proofs, keysets);

    // For large amounts, skip exact match search (it's exponential and slow)
    // Only try exact match for smaller amounts with fewer proofs
    if (targetAmount < 1000 && proofs.length <= 15) {
      final exactMatch =
          _findExactMatchWithFees(sortedProofs, targetAmount, keysets);
      if (exactMatch.isNotEmpty) {
        final feeData =
            calculateFeesWithBreakdown(proofs: exactMatch, keysets: keysets);
        return ProofSelectionResult(
          selectedProofs: exactMatch,
          totalSelected: exactMatch.fold(0, (sum, proof) => sum + proof.amount),
          fees: feeData['totalFees'],
          splitAmount: 0,
          needsSplit: false,
          feesByKeyset: feeData['feesByKeyset'],
        );
      }
    }

    // Use optimized greedy selection
    return _selectGreedy(
      sortedProofs: sortedProofs,
      targetAmount: targetAmount,
      keysets: keysets,
    );
  }

  /// Fast greedy selection - optimized for performance
  static ProofSelectionResult _selectGreedy({
    required List<CashuProof> sortedProofs,
    required int targetAmount,
    required List<CahsuKeyset> keysets,
  }) {
    // Use index-based selection to avoid expensive list operations
    final selected = <int>[]; // indices into sortedProofs
    final used = <bool>[]; // track which proofs are used
    for (int i = 0; i < sortedProofs.length; i++) {
      used.add(false);
    }

    int currentTotal = 0;
    int estimatedFees = 0;

    // Greedy selection: keep adding largest available proofs until we exceed target + fees
    for (int i = 0; i < sortedProofs.length; i++) {
      if (used[i]) continue;

      final proof = sortedProofs[i];
      final proofKeyset = _findKeysetById(keysets, proof.keysetId);
      if (proofKeyset == null) continue;

      // Quick fee estimate (will calculate exactly later)
      final proofFeePPK = proofKeyset.inputFeePPK;
      final proofFeeEstimate = (proofFeePPK + 999) ~/ 1000;

      final projectedTotal = currentTotal + proof.amount;
      final projectedFees = estimatedFees + proofFeeEstimate;

      selected.add(i);
      used[i] = true;
      currentTotal = projectedTotal;
      estimatedFees = projectedFees;

      // Check if we have enough
      if (currentTotal >= targetAmount + estimatedFees) {
        break;
      }
    }

    // Now calculate exact fees with selected proofs
    final selectedProofs = selected.map((i) => sortedProofs[i]).toList();
    final feeData =
        calculateFeesWithBreakdown(proofs: selectedProofs, keysets: keysets);
    final exactFees = feeData['totalFees'];
    final exactTotal =
        selectedProofs.fold(0, (sum, proof) => sum + proof.amount);

    // Check if we need more proofs (fees were underestimated)
    if (exactTotal < targetAmount + exactFees) {
      // Add one more proof
      for (int i = 0; i < sortedProofs.length; i++) {
        if (!used[i]) {
          selectedProofs.add(sortedProofs[i]);
          used[i] = true;
          break;
        }
      }

      // Recalculate
      final newFeeData =
          calculateFeesWithBreakdown(proofs: selectedProofs, keysets: keysets);
      final newFees = newFeeData['totalFees'];
      final newTotal =
          selectedProofs.fold(0, (sum, proof) => sum + proof.amount);

      if (newTotal < targetAmount + newFees) {
        throw Exception(
            'Insufficient funds: need $targetAmount + fees ($newFees), have $newTotal selected');
      }

      final splitAmount = newTotal - targetAmount - newFees;
      return ProofSelectionResult(
        selectedProofs: selectedProofs,
        totalSelected: newTotal,
        fees: newFees,
        splitAmount: splitAmount.toInt(),
        needsSplit: splitAmount > 0,
        feesByKeyset: newFeeData['feesByKeyset'],
      );
    }

    // We have enough
    final splitAmount = exactTotal - targetAmount - exactFees;
    return ProofSelectionResult(
      selectedProofs: selectedProofs,
      totalSelected: exactTotal,
      fees: exactFees,
      splitAmount: splitAmount.toInt(),
      needsSplit: splitAmount > 0,
      feesByKeyset: feeData['feesByKeyset'],
    );
  }

  /// Find exact match including fees across multiple keysets
  static List<CashuProof> _findExactMatchWithFees(
    List<CashuProof> proofs,
    int targetAmount,
    List<CahsuKeyset> keysets,
  ) {
    // Check single proof exact match
    for (final proof in proofs) {
      final singleProofFee = calculateFees([proof], keysets);
      if (proof.amount == targetAmount + singleProofFee) {
        return [proof];
      }
    }

    // Check combinations with fee consideration
    return _findExactCombinationWithFees(proofs, targetAmount, keysets,
        maxProofs: 5);
  }

  /// Find exact combination accounting for fees across multiple keysets
  static List<CashuProof> _findExactCombinationWithFees(
    List<CashuProof> proofs,
    int targetAmount,
    List<CahsuKeyset> keysets, {
    int maxProofs = 3, // Reduced from 5 for performance
  }) {
    // Stricter limits for performance
    if (proofs.length > 15) return [];

    for (int len = 2; len <= maxProofs && len <= proofs.length; len++) {
      final combination =
          _findCombinationOfLengthWithFees(proofs, targetAmount, keysets, len);
      if (combination.isNotEmpty) return combination;
    }

    return [];
  }

  /// Find combination of specific length with fee consideration
  static List<CashuProof> _findCombinationOfLengthWithFees(
    List<CashuProof> proofs,
    int targetAmount,
    List<CahsuKeyset> keysets,
    int length,
  ) {
    List<CashuProof> result = [];

    void backtrack(int start, List<CashuProof> current, int currentSum) {
      if (current.length == length) {
        final fees = calculateFees(current, keysets);
        if (currentSum == targetAmount + fees) {
          result = List.from(current);
        }
        return;
      }

      for (int i = start; i < proofs.length; i++) {
        // Estimate if this combination could work
        final estimatedFees = calculateFees([...current, proofs[i]], keysets);
        if (currentSum + proofs[i].amount <=
            targetAmount + estimatedFees + 100) {
          // Small buffer
          current.add(proofs[i]);
          backtrack(i + 1, current, currentSum + proofs[i].amount);
          current.removeLast();

          if (result.isNotEmpty) return;
        }
      }
    }

    backtrack(0, [], 0);
    return result;
  }
}
