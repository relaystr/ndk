import 'dart:typed_data';

import '../../../shared/logger/logger.dart';
import '../../entities/cashu/cashu_blinded_message.dart';
import '../../entities/cashu/cashu_blinded_signature.dart';
import '../../entities/cashu/cashu_keyset.dart';
import '../../entities/cashu/cashu_proof.dart';
import '../../repositories/cashu_key_derivation.dart';
import '../../repositories/cashu_repo.dart';
import 'cashu_bdhke.dart';
import 'cashu_cache_decorator.dart';
import 'cashu_seed.dart';
import 'cashu_tools.dart';

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

/// Overall result of a restore operation
class CashuRestoreResult {
  final List<CashuRestoreKeysetResult> keysetResults;
  final int totalProofsRestored;

  CashuRestoreResult({
    required this.keysetResults,
    required this.totalProofsRestored,
  });
}

/// Implements NUT-09 (Restore) and uses NUT-13 (Deterministic Secrets)
/// to restore proofs from a seed phrase.
class CashuRestore {
  final CashuRepo cashuRepo;
  final CashuKeyDerivation cashuKeyDerivation;
  final CashuCacheDecorator cacheManager;
  final CashuSeed cashuSeed;

  CashuRestore({
    required this.cashuRepo,
    required this.cashuKeyDerivation,
    required this.cacheManager,
    required this.cashuSeed,
  });

  /// Restores proofs for a single keyset from a mint.
  ///
  /// This implements NUT-09 restore protocol:
  /// 1. Generates deterministic blinded messages using NUT-13
  /// 2. Calls the mint's restore endpoint with these messages
  /// 3. Receives back blind signatures for proofs that exist
  /// 4. Unblinds the signatures to get the actual proofs
  ///
  /// [mintUrl] - The URL of the mint to restore from
  /// [keyset] - The keyset to restore proofs for
  /// [startCounter] - The counter to start scanning from (default: 0)
  /// [batchSize] - How many secrets to check in each batch (default: 100)
  /// [gapLimit] - How many consecutive empty batches before stopping (default: 2)
  Future<CashuRestoreKeysetResult> restoreKeyset({
    required String mintUrl,
    required CahsuKeyset keyset,
    int startCounter = 0,
    int batchSize = 100,
    int gapLimit = 2,
  }) async {
    final String keysetId = keyset.id;
    final seedBytes = Uint8List.fromList(cashuSeed.getSeedBytes());

    List<CashuProof> allRestoredProofs = [];
    int currentCounter = startCounter;
    int consecutiveEmptyBatches = 0;
    int lastUsedCounter = startCounter - 1;

    Logger.log
        .i('Starting restore for keyset $keysetId from counter $startCounter');

    while (consecutiveEmptyBatches < gapLimit) {
      // Generate blinded messages for this batch
      final List<CashuBlindedMessageItem> blindedMessageItems = [];

      for (int i = 0; i < batchSize; i++) {
        final counter = currentCounter + i;

        try {
          // Derive secret and blinding factor using NUT-13
          final derivedSecret = await cashuKeyDerivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );

          final secret = derivedSecret.secretHex;
          final r = BigInt.parse(derivedSecret.blindingHex, radix: 16);

          // Create blinded message
          // ignore: non_constant_identifier_names, constant_identifier_names
          final (B_, rActual) = CashuBdhke.blindMessage(secret, r: r);

          if (B_.isEmpty) {
            Logger.log.w('Empty blinded message for counter $counter');
            continue;
          }

          // We don't know the amount for restore, so we use 0 as placeholder
          // The mint will return the actual amount in the signature
          final blindedMessage = CashuBlindedMessage(
            id: keysetId,
            amount: 0, // Amount is unknown during restore
            blindedMessage: B_,
          );

          blindedMessageItems.add(CashuBlindedMessageItem(
            blindedMessage: blindedMessage,
            secret: secret,
            r: rActual,
            amount: 0,
          ));
        } catch (e) {
          Logger.log
              .w('Error creating blinded message for counter $counter: $e');
        }
      }

      if (blindedMessageItems.isEmpty) {
        Logger.log.w(
            'No valid blinded messages created for batch starting at $currentCounter');
        consecutiveEmptyBatches++;
        currentCounter += batchSize;
        continue;
      }

      // Call restore endpoint
      try {
        final blindedMessages =
            blindedMessageItems.map((item) => item.blindedMessage).toList();

        final signatures = await cashuRepo.restore(
          mintUrl: mintUrl,
          outputs: blindedMessages,
        );

        if (signatures.isEmpty) {
          // No signatures returned for this batch
          Logger.log.d(
              'No signatures returned for batch starting at $currentCounter');
          consecutiveEmptyBatches++;
        } else {
          // Found some proofs! Reset empty batch counter
          consecutiveEmptyBatches = 0;

          Logger.log.i(
              'Found ${signatures.length} signatures in batch starting at $currentCounter');

          // Unblind the signatures to get proofs
          final proofs = _unblindRestoreSignatures(
            signatures: signatures,
            blindedMessageItems: blindedMessageItems,
            keyset: keyset,
          );

          allRestoredProofs.addAll(proofs);

          // Update last used counter
          lastUsedCounter = currentCounter + batchSize - 1;
        }
      } catch (e) {
        Logger.log.e(
            'Error calling restore endpoint for batch starting at $currentCounter: $e');
        // On error, we consider this batch as empty and continue
        consecutiveEmptyBatches++;
      }

      currentCounter += batchSize;
    }

    Logger.log.i('Restore completed for keyset $keysetId. '
        'Found ${allRestoredProofs.length} proofs. '
        'Last used counter: $lastUsedCounter');

    return CashuRestoreKeysetResult(
      keysetId: keysetId,
      restoredProofs: allRestoredProofs,
      lastUsedCounter: lastUsedCounter,
    );
  }

  /// Unblinds restore signatures to create proofs
  List<CashuProof> _unblindRestoreSignatures({
    required List<CashuBlindedSignature> signatures,
    required List<CashuBlindedMessageItem> blindedMessageItems,
    required CahsuKeyset keyset,
  }) {
    final List<CashuProof> proofs = [];

    // Create a map of blinded message hex to its item for quick lookup
    final Map<String, CashuBlindedMessageItem> messageMap = {};
    for (final item in blindedMessageItems) {
      messageMap[item.blindedMessage.blindedMessage] = item;
    }

    // Create a map of amount to public key
    final Map<int, String> keysByAmount = {};
    for (final keyPair in keyset.mintKeyPairs) {
      keysByAmount[keyPair.amount] = keyPair.pubkey;
    }

    for (final signature in signatures) {
      // Find the corresponding blinded message by ID
      final matchingItem = messageMap.values.firstWhere(
        (item) => item.blindedMessage.id == signature.id,
        orElse: () =>
            throw Exception('No matching blinded message for signature'),
      );

      final mintPubKey = keysByAmount[signature.amount];
      if (mintPubKey == null) {
        Logger.log.w('No mint public key for amount ${signature.amount}');
        continue;
      }

      try {
        // Unblind the signature
        final unblindedSig = CashuBdhke.unblindingSignature(
          cHex: signature.blindedSignature,
          kHex: mintPubKey,
          r: matchingItem.r,
        );

        if (unblindedSig == null) {
          Logger.log
              .w('Failed to unblind signature for amount ${signature.amount}');
          continue;
        }

        // Create the proof
        final proof = CashuProof(
          keysetId: signature.id,
          amount: signature.amount,
          secret: matchingItem.secret,
          unblindedSig: CashuTools.ecPointToHex(unblindedSig),
        );

        proofs.add(proof);
      } catch (e) {
        Logger.log.e('Error unblinding signature: $e');
      }
    }

    return proofs;
  }

  /// Restores proofs for all keysets from a mint.
  ///
  /// This is the main restore method that should be called by wallets.
  /// It will restore proofs for all active keysets in the mint.
  ///
  /// [mintUrl] - The URL of the mint to restore from
  /// [keysets] - The list of keysets to restore proofs for
  /// [startCounter] - The counter to start scanning from (default: 0)
  /// [batchSize] - How many secrets to check in each batch (default: 100)
  /// [gapLimit] - How many consecutive empty batches before stopping (default: 2)
  Future<CashuRestoreResult> restoreAllKeysets({
    required String mintUrl,
    required List<CahsuKeyset> keysets,
    int startCounter = 0,
    int batchSize = 100,
    int gapLimit = 2,
  }) async {
    final List<CashuRestoreKeysetResult> keysetResults = [];
    int totalProofs = 0;

    for (final keyset in keysets) {
      try {
        final result = await restoreKeyset(
          mintUrl: mintUrl,
          keyset: keyset,
          startCounter: startCounter,
          batchSize: batchSize,
          gapLimit: gapLimit,
        );

        keysetResults.add(result);
        totalProofs += result.restoredProofs.length;

        // Update the derivation counter in cache
        if (result.lastUsedCounter >= startCounter) {
          await cacheManager.setDerivationCounter(
            keysetId: keyset.id,
            mintUrl: mintUrl,
            counter: result.lastUsedCounter + 1,
          );
        }
      } catch (e) {
        Logger.log.e('Error restoring keyset ${keyset.id}: $e');
      }
    }

    return CashuRestoreResult(
      keysetResults: keysetResults,
      totalProofsRestored: totalProofs,
    );
  }
}
