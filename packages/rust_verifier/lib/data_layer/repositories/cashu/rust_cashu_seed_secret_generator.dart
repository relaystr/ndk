import 'package:ndk/domain_layer/repositories/cashu_seed_secret.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_seed.dart';
import 'package:ndk_rust_verifier/rust_bridge/api/cashu_seed.dart';
import '../rust_lib_initializer.dart';

class RustCashuSeedSecretGenerator implements CashuSeedSecretGenerator {
  final RustLibInitializer _initializer = RustLibInitializer();

  /// Creates a new instance of [RustCashuSeedSecretGenerator]
  RustCashuSeedSecretGenerator();

  @override
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required String seedPhrase,
    required String passphrase,
    required int counter,
    required String keysetId,
  }) async {
    await _initializer.ensureInitialized();

    final result = await deriveSecretRust(
      seedPhrase: seedPhrase,
      passphrase: passphrase,
      counter: counter,
      keysetId: keysetId,
    );

    return CashuSeedDeriveSecretResult(
      secretHex: result.secretHex,
      blindingHex: result.blindingHex,
    );
  }
}
