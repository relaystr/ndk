import 'dart:typed_data';

import 'package:bip39_mnemonic/bip39_mnemonic.dart';

import '../usecases/cashu/cashu_seed.dart';

abstract class CashuKeyDerivation {
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required Uint8List seedBytes,
    required int counter,
    required String keysetId,
  });
}
