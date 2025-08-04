import '../../entities/cashu/wallet_cashu_keyset.dart';
import '../../entities/cashu/wallet_cashu_blinded_message.dart';
import '../../entities/cashu/wallet_cashu_proof.dart';
import '../../repositories/cashu_repo.dart';
import 'cashu_bdhke.dart';
import 'cashu_tools.dart';

class ProofSelectionResult {
  final List<WalletCashuProof> selectedProofs;
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
  final List<WalletCashuProof> exactProofs;
  final List<WalletCashuProof> changeProofs;

  SplitResult({
    required this.exactProofs,
    required this.changeProofs,
  });
}

class CashuWalletProofSelect {
  final CashuRepo _cashuRepo;

  CashuWalletProofSelect({
    required CashuRepo cashuRepo,
  }) : _cashuRepo = cashuRepo;

  /// Find keyset by ID from list
  static WalletCahsuKeyset? _findKeysetById(
      List<WalletCahsuKeyset> keysets, String keysetId) {
    try {
      return keysets.firstWhere((keyset) => keyset.id == keysetId);
    } catch (e) {
      return null;
    }
  }

  /// Calculate fees for a list of proofs across multiple keysets
  static int calculateFees(
    List<WalletCashuProof> proofs,
    List<WalletCahsuKeyset> keysets,
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
    required List<WalletCashuProof> proofs,
    required List<WalletCahsuKeyset> keysets,
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
  static WalletCahsuKeyset? getActiveKeyset(List<WalletCahsuKeyset> keysets) {
    try {
      return keysets.firstWhere((keyset) => keyset.active);
    } catch (e) {
      return null; // No active keyset found
    }
  }

  /// Sort proofs optimally considering both amount and fees
  static List<WalletCashuProof> sortProofsOptimally(
    List<WalletCashuProof> proofs,
    List<WalletCahsuKeyset> keysets,
  ) {
    return List<WalletCashuProof>.from(proofs)
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
    required List<WalletCashuProof> proofsToSplit,
    required int targetAmount,
    required int changeAmount,
    required List<WalletCahsuKeyset> keysets,
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

    final blindedMessagesOutputs = CashuBdhke.createBlindedMsgForAmounts(
      keysetId: activeKeyset.id,
      amounts: outputs,
    );

    final blindedSignatures = await _cashuRepo.swap(
      mintUrl: mint,
      proofs: proofsToSplit,
      outputs: blindedMessagesOutputs
          .map(
            (e) => WalletCashuBlindedMessage(
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

    return SplitResult(
      /// first proofs is exact amount
      exactProofs: myUnblindedTokens.take(targetAmountsSplit.length).toList(),

      /// change
      changeProofs: myUnblindedTokens.skip(changeAmountsSplit.length).toList(),
    );
  }

  /// Selects proofs for spending target amount with multiple keysets
  static ProofSelectionResult selectProofsForSpending({
    required List<WalletCashuProof> proofs,
    required int targetAmount,
    required List<WalletCahsuKeyset> keysets,
    int maxIterations = 15,
  }) {
    if (keysets.isEmpty) {
      throw Exception('No keysets provided');
    }

    final sortedProofs = sortProofsOptimally(proofs, keysets);

    // First try to find exact match (including fees)
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

    // Iterative selection accounting for fees
    return _selectWithFeeIteration(
      sortedProofs: sortedProofs,
      targetAmount: targetAmount,
      keysets: keysets,
      maxIterations: maxIterations,
    );
  }

  /// Iteratively select proofs accounting for fees across multiple keysets
  static ProofSelectionResult _selectWithFeeIteration({
    required List<WalletCashuProof> sortedProofs,
    required int targetAmount,
    required List<WalletCahsuKeyset> keysets,
    required int maxIterations,
  }) {
    final selected = <WalletCashuProof>[];
    int iteration = 0;

    while (iteration < maxIterations) {
      iteration++;

      final currentTotal = selected.fold(0, (sum, proof) => sum + proof.amount);
      final feeData =
          calculateFeesWithBreakdown(proofs: selected, keysets: keysets);
      final currentFees = feeData['totalFees'];
      final requiredTotal = targetAmount + currentFees;

      if (currentTotal >= requiredTotal) {
        // We have enough!
        final splitAmount = currentTotal - targetAmount - currentFees;
        return ProofSelectionResult(
          selectedProofs: selected,
          totalSelected: currentTotal,
          fees: currentFees,
          splitAmount: splitAmount.toInt(),
          needsSplit: splitAmount > 0,
          feesByKeyset: feeData['feesByKeyset'],
        );
      }

      // Need more inputs
      final shortage = requiredTotal - currentTotal;

      // Find next best proof to add (prefer efficient proofs)
      WalletCashuProof? nextProof = _selectNextOptimalProof(
        sortedProofs,
        selected,
        shortage.toInt(),
        keysets,
      );

      if (nextProof == null) {
        final availableTotal =
            sortedProofs.fold(0, (sum, proof) => sum + proof.amount);

        throw Exception(
            'Insufficient funds: need $targetAmount + fees ($currentFees), have $availableTotal available');
      }

      selected.add(nextProof);
    }

    throw Exception(
        'Fee calculation did not converge after $maxIterations iterations');
  }

  /// Select the next optimal proof considering amount and fee efficiency
  static WalletCashuProof? _selectNextOptimalProof(
    List<WalletCashuProof> sortedProofs,
    List<WalletCashuProof> alreadySelected,
    int shortage,
    List<WalletCahsuKeyset> keysets,
  ) {
    WalletCashuProof? bestProof;
    double bestEfficiency = -1;

    for (final proof in sortedProofs) {
      if (alreadySelected.contains(proof)) continue;

      final keyset = _findKeysetById(keysets, proof.keysetId);
      if (keyset == null) continue;

      // Calculate efficiency: amount per fee unit
      final feePpk = keyset.inputFeePPK;
      final feeInSats = ((feePpk + 999) ~/ 1000);
      final efficiency =
          feeInSats > 0 ? proof.amount / feeInSats : proof.amount.toDouble();

      // Prefer proofs that can cover the shortage efficiently
      if (proof.amount >= shortage && efficiency > bestEfficiency) {
        bestProof = proof;
        bestEfficiency = efficiency;
      }
    }

    // If no proof can cover shortage, pick the most efficient one
    if (bestProof == null) {
      for (final proof in sortedProofs) {
        if (alreadySelected.contains(proof)) continue;

        final keyset = _findKeysetById(keysets, proof.keysetId);
        if (keyset == null) continue;

        final feePpk = keyset.inputFeePPK;
        final feeInSats = ((feePpk + 999) ~/ 1000);
        final efficiency =
            feeInSats > 0 ? proof.amount / feeInSats : proof.amount.toDouble();

        if (efficiency > bestEfficiency) {
          bestProof = proof;
          bestEfficiency = efficiency;
        }
      }
    }

    return bestProof;
  }

  /// Find exact match including fees across multiple keysets
  static List<WalletCashuProof> _findExactMatchWithFees(
    List<WalletCashuProof> proofs,
    int targetAmount,
    List<WalletCahsuKeyset> keysets,
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
  static List<WalletCashuProof> _findExactCombinationWithFees(
    List<WalletCashuProof> proofs,
    int targetAmount,
    List<WalletCahsuKeyset> keysets, {
    int maxProofs = 5,
  }) {
    if (proofs.length > 20) return [];

    for (int len = 2; len <= maxProofs && len <= proofs.length; len++) {
      final combination =
          _findCombinationOfLengthWithFees(proofs, targetAmount, keysets, len);
      if (combination.isNotEmpty) return combination;
    }

    return [];
  }

  /// Find combination of specific length with fee consideration
  static List<WalletCashuProof> _findCombinationOfLengthWithFees(
    List<WalletCashuProof> proofs,
    int targetAmount,
    List<WalletCahsuKeyset> keysets,
    int length,
  ) {
    List<WalletCashuProof> result = [];

    void backtrack(int start, List<WalletCashuProof> current, int currentSum) {
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
