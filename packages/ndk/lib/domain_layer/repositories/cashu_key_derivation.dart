import 'dart:typed_data';

import '../usecases/cashu/cashu_keypair.dart';
import '../usecases/cashu/cashu_seed.dart';

/// Reserved derivation counter slot for NUT-20 mint quote lock keys.
///
/// Stored alongside the per-keyset derivation counters. Cannot collide with a
/// real keyset id since keyset ids are always hex.
const String kQuoteKeyDerivationCounterSlot = 'quote-key';

abstract class CashuKeyDerivation {
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required Uint8List seedBytes,
    required int counter,
    required String keysetId,
  });

  /// Deterministically derives the NUT-20 mint quote lock key from the seed.
  ///
  /// The key is bound to [mintUrl] (not a keyset id, because no keyset is
  /// chosen yet when a quote is created) and to [counter], so any wallet that
  /// owns the seed can re-derive the private key for a quote it created. The
  /// public key is sent to the mint as the quote `pubkey` lock when the quote
  /// is created.
  Future<CashuKeypair> deriveQuoteKey({
    required Uint8List seedBytes,
    required String mintUrl,
    required int counter,
  });
}
