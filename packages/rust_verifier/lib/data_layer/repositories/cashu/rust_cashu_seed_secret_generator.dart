import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:ndk/domain_layer/repositories/cashu_key_derivation.dart';

import 'package:ndk/domain_layer/usecases/cashu/cashu_seed.dart';
import 'package:ndk_rust_verifier/rust_bridge/api/cashu_seed.dart';
import '../rust_lib_initializer.dart';

class RustCashuKeyDerivation implements CashuKeyDerivation {
  final RustLibInitializer _initializer = RustLibInitializer();

  /// Creates a new instance of [RustCashuKeyDerivation]
  RustCashuKeyDerivation();

  @override
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required Mnemonic mnemonic,
    required int counter,
    required String keysetId,
  }) async {
    await _initializer.ensureInitialized();

    final result = await deriveSecretRust(
      seedPhrase: mnemonic.sentence,
      passphrase: mnemonic.passphrase,
      counter: counter,
      keysetId: keysetId,
    );

    return CashuSeedDeriveSecretResult(
      secretHex: result.secretHex,
      blindingHex: result.blindingHex,
    );
  }
}
