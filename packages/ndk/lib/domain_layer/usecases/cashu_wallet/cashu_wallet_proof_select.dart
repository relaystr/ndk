import '../../entities/cashu/wallet_cashu_keyset.dart';
import '../../entities/cashu/wallet_cashu_blinded_message.dart';
import '../../entities/cashu/wallet_cashu_proof.dart';
import '../../repositories/cashu_repo.dart';
import 'cashu_bdhke.dart';

class ProofSelectionResult {
  final List<WalletCashuProof> selectedProofs;
  final int totalSelected;

  /// amount that needs to be split
  final int splitAmount;
  final bool needsSplit;

  ProofSelectionResult({
    required this.selectedProofs,
    required this.totalSelected,
    required this.splitAmount,
    required this.needsSplit,
  });
}

class SplitResult {
  /// proofs that sum to exact target
  final List<WalletCashuProof> exactProofs;

  /// change proofs to keep
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

  /// swaps proofs in target amount and change
  Future<SplitResult> performSplit({
    required String mint,
    required List<WalletCashuProof> proofsToSplit,
    required int targetAmount,
    required int changeAmount,
    required WalletCahsuKeyset keyset,
  }) async {
    final outputs = [
      // amount we want to spend
      targetAmount,

      // change to keep
      changeAmount,
    ];

    final blindedMessagesOutputs = CashuBdhke.createBlindedMsgForAmounts(
      keysetId: keyset.id,
      amounts: outputs,
    );

    final blindedSignatures = await _cashuRepo.swap(
      mintURL: mint,
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

    // unblind
    final myUnblindedTokens = CashuBdhke.unblindSignatures(
      mintSignatures: blindedSignatures,
      blindedMessages: blindedMessagesOutputs,
      mintPublicKeys: keyset,
    );

    return SplitResult(
      /// first proof is exact amount
      exactProofs: myUnblindedTokens.take(1).toList(),

      /// change
      changeProofs: myUnblindedTokens.skip(1).toList(),
    );
  }

  /// Selects proofs for spending target amount. \
  /// returns selected proofs, total amount selected, \
  /// and whether a split is needed.
  static ProofSelectionResult selectProofsForSpending(
      List<WalletCashuProof> proofs, int targetAmount) {
    /// sort proofs by amount descending for greedy selection
    final sortedProofs = List<WalletCashuProof>.from(proofs)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    /// first try to find exact match
    final exactMatch = _findExactMatch(sortedProofs, targetAmount);
    if (exactMatch.isNotEmpty) {
      return ProofSelectionResult(
        selectedProofs: exactMatch,
        totalSelected: targetAmount,
        splitAmount: 0,
        needsSplit: false,
      );
    }

    /// find minimum overpayment scenario
    final selected = <WalletCashuProof>[];
    int totalAmount = 0;

    for (final proof in sortedProofs) {
      selected.add(proof);
      totalAmount += proof.amount;

      if (totalAmount >= targetAmount) {
        break;
      }
    }

    if (totalAmount < targetAmount) {
      throw Exception(
          'Insufficient funds: need $targetAmount, have $totalAmount');
    }

    final splitAmount = totalAmount - targetAmount;

    return ProofSelectionResult(
      selectedProofs: selected,
      totalSelected: totalAmount,
      splitAmount: splitAmount,
      needsSplit: splitAmount > 0,
    );
  }

  static List<WalletCashuProof> _findExactMatch(
      List<WalletCashuProof> proofs, int targetAmount) {
    /// check single proof exact match
    for (final proof in proofs) {
      if (proof.amount == targetAmount) {
        return [proof];
      }
    }

    /// check combinations (subset sum) - limited depth for performance
    return _findExactCombination(proofs, targetAmount, maxProofs: 5);
  }

  static List<WalletCashuProof> _findExactCombination(
    List<WalletCashuProof> proofs,
    int target, {
    int maxProofs = 5,
  }) {
    /// Skip for large sets
    if (proofs.length > 20) return [];

    for (int len = 2; len <= maxProofs && len <= proofs.length; len++) {
      final combination = _findCombinationOfLength(proofs, target, len);
      if (combination.isNotEmpty) return combination;
    }

    return [];
  }

  static List<WalletCashuProof> _findCombinationOfLength(
      List<WalletCashuProof> proofs, int target, int length) {
    List<WalletCashuProof> result = [];

    void backtrack(int start, List<WalletCashuProof> current, int currentSum) {
      if (current.length == length) {
        if (currentSum == target) {
          result = List.from(current);
        }
        return;
      }

      for (int i = start; i < proofs.length; i++) {
        if (currentSum + proofs[i].amount <= target) {
          current.add(proofs[i]);
          backtrack(i + 1, current, currentSum + proofs[i].amount);
          current.removeLast();

          /// found match
          if (result.isNotEmpty) return;
        }
      }
    }

    backtrack(0, [], 0);
    return result;
  }
}
