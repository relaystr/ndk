import '../../usecases/cashu/cashu_keypair.dart';
import '../wallet/wallet_transaction.dart';

/// High-level stage of a [Cashu.recoverAndCompleteQuote] run, used by UIs to
/// render live progress.
enum CashuQuoteRecoveryStage {
  /// Fetching the quote from the mint to learn the locked public key.
  fetchingQuote,

  /// Scanning the seed-derived quote-key counters for the locked key.
  recoveringLockKey,

  /// Completing the mint (waits for payment and mints the proofs).
  completingMint,
}

/// Live progress report emitted by [Cashu.recoverAndCompleteQuote].
class CashuQuoteRecoveryProgress {
  final CashuQuoteRecoveryStage stage;

  /// The seed-derived derivation counter of the recovered lock key, once known.
  final int? derivationCounter;

  /// The recovered lock keypair, once known.
  final CashuKeypair? quoteKey;

  /// Latest state of the funding transaction while the mint is completed;
  /// null before the completion step.
  final CashuWalletTransaction? transaction;

  const CashuQuoteRecoveryProgress({
    required this.stage,
    this.derivationCounter,
    this.quoteKey,
    this.transaction,
  });

  bool get transactionCompleted =>
      transaction?.state == WalletTransactionState.completed;

  bool get transactionFailed =>
      transaction?.state == WalletTransactionState.failed;
}
