import 'dart:typed_data';

import '../usecases/cashu/cashu_seed.dart';

abstract class CashuKeyDerivation {
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required Uint8List seedBytes,
    required int counter,
    required String keysetId,
  });
}
