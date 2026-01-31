import 'dart:typed_data';

import 'package:ndk/domain_layer/usecases/cashu/cashu_seed.dart';

import '../../../domain_layer/repositories/cashu_seed_secret.dart';

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

    return Future.value(CashuSeedDeriveSecretResult(
      secretHex: fakeSecretHex,
      blindingHex: fakeBlindingHex,
    ));
  }
}
