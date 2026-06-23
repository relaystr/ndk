import 'package:ndk/data_layer/repositories/wallets/mem_wallets_repo.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_keyset.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_cache_decorator.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

CashuStateExportImport _export(
    CacheManager cache, MemWalletsRepo wallets, CashuSeed seed) {
  return CashuStateExportImport(
    cacheManagerCashu: CashuCacheDecorator(cacheManager: cache),
    walletsRepo: wallets,
    cashuSeed: seed,
  );
}

CahsuKeyset _keyset(String mintUrl) => CahsuKeyset(
      id: 'keyset1',
      mintUrl: mintUrl,
      unit: 'sat',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {CahsuMintKeyPair(amount: 1, pubkey: 'abc')},
    );

void main() {
  const mintUrl = 'https://mint.test';

  test('export then import round-trips proofs, keysets and counters', () async {
    final srcCache = MemCacheManager();
    final srcWallets = MemWalletsRepo();
    final seed = CashuSeed();
    await seed.setSeedPhrase(seedPhrase: CashuSeed.generateSeedPhrase());

    await srcCache.saveKeyset(_keyset(mintUrl));
    await srcCache.saveProofs(
      proofs: [
        CashuProof(
          keysetId: 'keyset1',
          amount: 8,
          secret: 'secret-a',
          unblindedSig: 'sig-a',
        ),
        CashuProof(
          keysetId: 'keyset1',
          amount: 2,
          secret: 'secret-b',
          unblindedSig: 'sig-b',
        ),
      ],
      mintUrl: mintUrl,
    );
    await srcCache.setCashuSecretCounter(
      mintUrl: mintUrl,
      keysetId: 'keyset1',
      counter: 42,
    );

    final exported = await _export(srcCache, srcWallets, seed)
        .exportToMap(includeSeedPhrase: true);

    expect(exported['type'], equals(CashuStateExportImport.exportType));
    expect(exported['seedPhrase'], equals(seed.getSeedPhrase().sentence));
    expect((exported['proofs'] as List).length, equals(2));
    expect((exported['counters'] as List).single['counter'], equals(42));

    // restore into a fresh, empty device
    final dstCache = MemCacheManager();
    final dstWallets = MemWalletsRepo();
    final dstSeed = CashuSeed();

    final result =
        await _export(dstCache, dstWallets, dstSeed).importFromMap(exported);

    expect(result.restoredProofs, equals(2));
    expect(result.restoredKeysets, equals(1));
    expect(result.seedPhrase, equals(seed.getSeedPhrase().sentence));
    // seed was loaded into the destination seed instance
    expect(dstSeed.getSeedPhrase().sentence,
        equals(seed.getSeedPhrase().sentence));

    final restoredProofs = await dstCache.getProofs(mintUrl: mintUrl);
    expect(restoredProofs.length, equals(2));

    final restoredCounter = await dstCache.getCashuSecretCounter(
      mintUrl: mintUrl,
      keysetId: 'keyset1',
    );
    expect(restoredCounter, equals(42));

    final restoredKeysets = await dstCache.getKeysets(mintUrl: mintUrl);
    expect(restoredKeysets.single.id, equals('keyset1'));
  });

  test('json string round-trips', () async {
    final cache = MemCacheManager();
    final wallets = MemWalletsRepo();
    final seed = CashuSeed();
    await seed.setSeedPhrase(seedPhrase: CashuSeed.generateSeedPhrase());

    await cache.saveKeyset(_keyset(mintUrl));
    await cache.saveProofs(
      proofs: [
        CashuProof(
          keysetId: 'keyset1',
          amount: 1,
          secret: 'secret-c',
          unblindedSig: 'sig-c',
        ),
        CashuProof(
          keysetId: 'keyset1',
          amount: 2,
          secret: 'secret-c-2',
          unblindedSig: 'sig-c-2',
        ),
      ],
      mintUrl: mintUrl,
    );

    final jsonString = await _export(cache, wallets, seed).exportToJsonString();

    final dstCache = MemCacheManager();
    final result = await _export(dstCache, MemWalletsRepo(), CashuSeed())
        .importFromJsonString(jsonString);

    expect(result.restoredProofs, equals(2));
    expect((await dstCache.getProofs(mintUrl: mintUrl)).length, equals(2));
    expect((await dstCache.getKeysets(mintUrl: mintUrl)).first.id,
        equals('keyset1'));

    // check that the secret amount and unblinded sig round-tripped correctly (they are the most sensitive fields to get wrong in the serialization)
    final restoredProof = (await dstCache.getProofs(mintUrl: mintUrl)).first;
    expect(restoredProof.secret, equals('secret-c'));
    expect(restoredProof.unblindedSig, equals('sig-c'));
  });

  test('seed phrase is excluded by default', () async {
    final cache = MemCacheManager();
    final seed = CashuSeed();
    await seed.setSeedPhrase(seedPhrase: CashuSeed.generateSeedPhrase());

    final exported = await _export(cache, MemWalletsRepo(), seed).exportToMap();

    expect(exported.containsKey('seedPhrase'), isFalse);
  });

  test('rejects non-backup json', () async {
    final backup = _export(MemCacheManager(), MemWalletsRepo(), CashuSeed());
    expect(
      () => backup.importFromMap({'type': 'something-else', 'version': 1}),
      throwsArgumentError,
    );
  });
}
