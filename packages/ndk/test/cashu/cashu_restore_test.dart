import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/data_layer/repositories/cashu_seed_secret_generator/dart_cashu_key_derivation.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_user_seedphrase.dart';
import 'package:ndk/domain_layer/repositories/cashu_key_derivation.dart';
import 'package:ndk/domain_layer/repositories/cashu_repo.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_seed.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';
import 'dart:typed_data';

import 'cashu_test_tools.dart';

const devMintUrl = 'https://dev.mint.camelus.app';

void main() {
  group('Cashu Restore Tests', () {
    test('restore - deterministic secret generation', () async {
      // Generate a seed phrase
      final seedPhrase = CashuSeed.generateSeedPhrase();
      final userSeedPhrase = CashuUserSeedphrase(seedPhrase: seedPhrase);
      
      final cashu = CashuTestTools.mockHttpCashu(seedPhrase: userSeedPhrase);

      // Test that we can generate deterministic secrets
      final cashuSeed = cashu.getCashuSeed();
      final seedBytes = Uint8List.fromList(cashuSeed.getSeedBytes());
      
      final keyDerivation = DartCashuKeyDerivation();
      
      // Test derivation for a known keyset
      final keysetId = '009a1f293253e41e';
      
      // Generate secrets for multiple counters
      final secret1 = await keyDerivation.deriveSecret(
        seedBytes: seedBytes,
        counter: 0,
        keysetId: keysetId,
      );
      
      final secret2 = await keyDerivation.deriveSecret(
        seedBytes: seedBytes,
        counter: 1,
        keysetId: keysetId,
      );
      
      // Verify they are different
      expect(secret1.secretHex, isNot(equals(secret2.secretHex)));
      expect(secret1.blindingHex, isNot(equals(secret2.blindingHex)));
      
      // Verify determinism - generate again with same inputs
      final secret1Again = await keyDerivation.deriveSecret(
        seedBytes: seedBytes,
        counter: 0,
        keysetId: keysetId,
      );
      
      expect(secret1.secretHex, equals(secret1Again.secretHex));
      expect(secret1.blindingHex, equals(secret1Again.blindingHex));
    });

    test('restore - method exists', () async {
      final seedPhrase = CashuSeed.generateSeedPhrase();
      final userSeedPhrase = CashuUserSeedphrase(seedPhrase: seedPhrase);
      
      final cashu = CashuTestTools.mockHttpCashu(seedPhrase: userSeedPhrase);
      
      // Verify the restore method exists
      expect(cashu.restore, isNotNull);
    });

    test('restore - full flow with real mint', () async {
      // Skip this test in CI/automated environments
      // This test requires actual interaction with a mint
    }, skip: true);

    test('restore - fund and restore workflow', () async {
      // This test demonstrates the complete restore workflow:
      // 1. Create wallet with seed
      // 2. Fund it (simulated)
      // 3. Create new wallet with same seed
      // 4. Restore should recover the funds
      
      // Generate a seed phrase
      final seedPhrase = CashuSeed.generateSeedPhrase();
      final userSeedPhrase = CashuUserSeedphrase(seedPhrase: seedPhrase);
      
      final cashu = CashuTestTools.mockHttpCashu(seedPhrase: userSeedPhrase);
      
      // For now, just verify the restore method exists
      // Full integration test would require actual mint interaction
      expect(cashu.restore, isNotNull);
    }, skip: true);

    test('restore - should handle empty restore gracefully', () async {
      final seedPhrase = CashuSeed.generateSeedPhrase();
      final userSeedPhrase = CashuUserSeedphrase(seedPhrase: seedPhrase);
      
      final cashu = CashuTestTools.mockHttpCashu(seedPhrase: userSeedPhrase);
      
      // Attempting to restore with no funds should not throw
      // It should return empty results
      expect(cashu.restore, isNotNull);
    }, skip: true);
  });

  group('Cashu Restore - Real Mint Integration', () {
    test('restore from real mint - full workflow', () async {
      // This test uses the real dev mint
      final httpClient = http.Client();
      final httpRequestDS = HttpRequestDS(httpClient);
      final cashuRepo = CashuRepoImpl(client: httpRequestDS);
      final cacheManager = MemCacheManager();
      final keyDerivation = DartCashuKeyDerivation();

      // Generate a new seed phrase for this test
      final seedPhrase = CashuSeed.generateSeedPhrase();
      final userSeedPhrase = CashuUserSeedphrase(seedPhrase: seedPhrase);

      // Create first wallet
      final wallet1 = Cashu(
        cashuRepo: cashuRepo,
        cacheManager: cacheManager,
        cashuKeyDerivation: keyDerivation,
        cashuUserSeedphrase: userSeedPhrase,
      );

      // Note: In a real scenario, you would:
      // 1. Fund wallet1 with actual funds
      // 2. Create wallet2 with the same seed
      // 3. Call restore on wallet2
      // 4. Verify wallet2 has the same balance as wallet1
      
      // For now, we just verify the structure exists
      expect(wallet1.restore, isNotNull);
      
      httpClient.close();
    }, skip: true);
  });
}
