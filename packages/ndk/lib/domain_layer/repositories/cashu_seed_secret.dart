import '../usecases/cashu/cashu_seed.dart';

abstract class CashuSeedSecretGenerator {
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required String seedPhrase,
    required String passphrase,
    required int counter,
    required String keysetId,
  });
}
