import 'dart:typed_data';

import 'package:ndk/domain_layer/usecases/cashu/cashu_keypair.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_seed.dart';

import '../../../domain_layer/repositories/cashu_key_derivation.dart';

class FakeCashuSeedGenerator implements CashuKeyDerivation {
  @override
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required Uint8List seedBytes,
    required int counter,
    required String keysetId,
  }) {
    // Generate fake secret and blinding values based on the counter
    final fakeSecretHex =
        'deadbeef${counter.toRadixString(16).padLeft(24, '0')}';
    final fakeBlindingHex =
        'cafebabe${counter.toRadixString(16).padLeft(24, '0')}';

    return Future.value(
      CashuSeedDeriveSecretResult(
        secretHex: fakeSecretHex,
        blindingHex: fakeBlindingHex,
      ),
    );
  }

  @override
  Future<CashuKeypair> deriveQuoteKey({
    required Uint8List seedBytes,
    required String mintUrl,
    required int counter,
  }) async {
    return CashuKeypair(
      privateKey: 'deadbeef${counter.toRadixString(16).padLeft(56, '0')}',
      publicKey: 'fake${counter.toRadixString(16).padLeft(8, '0')}',
    );
  }
}
