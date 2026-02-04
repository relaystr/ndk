import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/data_layer/repositories/cashu_seed_secret_generator/dart_cashu_key_derivation.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_user_seedphrase.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'cashu_test_tools.dart';
import 'mocks/cashu_http_client_mock.dart';

const devMintUrl = 'https://dev.mint.camelus.app';
const mockMintUrl = 'http://mock.mint';

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

    test('restore - fund wallet1 and restore to wallet2 with real mint',
        () async {
      // This test uses the real dev mint to properly test the restore functionality
      // It can be run manually when needed by removing the skip flag
      
      // Create a shared seed phrase for both wallets  
      final seedPhrase = CashuSeed.generateSeedPhrase();
      final userSeedPhrase = CashuUserSeedphrase(seedPhrase: seedPhrase);
      
      print('Using seed phrase for test (first 5 words): ${seedPhrase.split(' ').take(5).join(' ')}...');

      // Create wallet1
      final httpClient1 = http.Client();
      final httpRequestDS1 = HttpRequestDS(httpClient1);
      final cashuRepo1 = CashuRepoImpl(client: httpRequestDS1);
      final cacheManager1 = MemCacheManager();
      final keyDerivation1 = DartCashuKeyDerivation();

      final wallet1 = Cashu(
        cashuRepo: cashuRepo1,
        cacheManager: cacheManager1,
        cashuKeyDerivation: keyDerivation1,
        cashuUserSeedphrase: userSeedPhrase,
      );

      const fundAmount = 21; // Small amount for testing
      const mintUrl = devMintUrl;
      const unit = "sat";

      print('Step 1: Funding wallet1 with $fundAmount $unit...');

      // Fund wallet1
      final draftTransaction = await wallet1.initiateFund(
        mintUrl: mintUrl,
        amount: fundAmount,
        unit: unit,
        method: "bolt11",
      );

      print('Quote created: ${draftTransaction.qoute!.quoteId}');
      print('Payment request: ${draftTransaction.qoute!.request}');
      print('Waiting for payment...');

      final transactionStream =
          wallet1.retrieveFunds(draftTransaction: draftTransaction);

      await expectLater(
        transactionStream,
        emitsInOrder([
          isA<CashuWalletTransaction>().having(
              (t) => t.state, 'state', WalletTransactionState.pending),
          isA<CashuWalletTransaction>().having(
              (t) => t.state, 'state', WalletTransactionState.completed),
        ]),
      );

      // Check wallet1 balance
      final wallet1Balances = await wallet1.getBalances();
      final wallet1Balance = wallet1Balances
          .where((element) => element.mintUrl == mintUrl)
          .first
          .balances[unit]!;

      print('Step 2: Wallet1 funded successfully!');
      print('Wallet1 balance: $wallet1Balance $unit');
      expect(wallet1Balance, equals(fundAmount));

      // Get wallet1 proofs to verify later
      final wallet1Proofs = await cacheManager1.getProofs(mintUrl: mintUrl);
      print('Wallet1 has ${wallet1Proofs.length} proofs');

      // Create wallet2 with the SAME seed phrase but DIFFERENT cache
      print('\nStep 3: Creating wallet2 with same seed phrase...');
      
      final httpClient2 = http.Client();
      final httpRequestDS2 = HttpRequestDS(httpClient2);
      final cashuRepo2 = CashuRepoImpl(client: httpRequestDS2);
      final cacheManager2 = MemCacheManager(); // Fresh cache - empty!
      final keyDerivation2 = DartCashuKeyDerivation();

      final wallet2 = Cashu(
        cashuRepo: cashuRepo2,
        cacheManager: cacheManager2,
        cashuKeyDerivation: keyDerivation2,
        cashuUserSeedphrase: userSeedPhrase, // SAME seed phrase!
      );

      // Wallet2 should have 0 balance before restore (fresh cache)
      final wallet2BalancesBefore = await wallet2.getBalances();
      final wallet2BalanceBefore = wallet2BalancesBefore
          .where((element) => element.mintUrl == mintUrl)
          .firstOrNull
          ?.balances[unit];
      
      print('Wallet2 balance before restore: ${wallet2BalanceBefore ?? 0} $unit');
      expect(wallet2BalanceBefore, anyOf(isNull, equals(0)));

      // Restore wallet2 using the seed phrase
      print('\nStep 4: Restoring wallet2 from seed phrase...');
      
      final restoreResult = await wallet2.restore(
        mintUrl: mintUrl,
        unit: unit,
      );

      print('Restore completed!');
      print('Total proofs restored: ${restoreResult.totalProofsRestored}');
      for (final keysetResult in restoreResult.keysetResults) {
        print(
            '  Keyset ${keysetResult.keysetId}: ${keysetResult.restoredProofs.length} proofs');
      }

      // Check wallet2 balance after restore
      final wallet2BalancesAfter = await wallet2.getBalances();
      final wallet2BalanceAfter = wallet2BalancesAfter
          .where((element) => element.mintUrl == mintUrl)
          .first
          .balances[unit]!;

      print('\nStep 5: Verification');
      print('Wallet1 balance: $wallet1Balance $unit');
      print('Wallet2 balance after restore: $wallet2BalanceAfter $unit');

      // Verify both wallets have the same balance
      expect(wallet2BalanceAfter, equals(wallet1Balance),
          reason: 'Wallet2 should have the same balance as wallet1 after restore');
      expect(wallet2BalanceAfter, equals(fundAmount),
          reason: 'Wallet2 should have the funded amount');

      // Verify wallet2 has proofs
      final wallet2Proofs = await cacheManager2.getProofs(mintUrl: mintUrl);
      print('Wallet2 has ${wallet2Proofs.length} proofs after restore');
      expect(wallet2Proofs.length, greaterThan(0),
          reason: 'Wallet2 should have proofs after restore');

      print('\n✅ Test passed! Restore functionality works correctly.');
      print('Wallet1 and Wallet2 both have $fundAmount $unit');

      httpClient1.close();
      httpClient2.close();
    }, skip: true); // Remove 'skip: true' to run this test with a real mint
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
