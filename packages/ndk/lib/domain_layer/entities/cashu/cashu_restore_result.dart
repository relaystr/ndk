import 'cashu_proof.dart';

class CashuRestoreResult {
  final List<CashuRestoreKeysetResult> keysetResults;
  final int totalProofsRestored;

  CashuRestoreResult({
    required this.keysetResults,
    required this.totalProofsRestored,
  });
}

/// Result of a restore operation for a single keyset
class CashuRestoreKeysetResult {
  final String keysetId;
  final List<CashuProof> restoredProofs;
  final int lastUsedCounter;

  CashuRestoreKeysetResult({
    required this.keysetId,
    required this.restoredProofs,
    required this.lastUsedCounter,
  });
}
