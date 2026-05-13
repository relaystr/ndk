part of 'cache_manager_test_suite.dart';

// ============================================================================
// Cashu Tests
// ============================================================================

void _runCashuTests(CacheManager Function() getCacheManager) {
  test('saveKeyset and getKeysets', () async {
    final cacheManager = getCacheManager();
    final keyset = CahsuKeyset(
      id: 'test_keyset_id',
      mintUrl: 'https://test.mint.com',
      unit: 'sat',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
    );

    await cacheManager.saveKeyset(keyset);
    final loadedKeysets =
        await cacheManager.getKeysets(mintUrl: 'https://test.mint.com');

    expect(loadedKeysets.length, equals(1));
    expect(loadedKeysets[0].id, equals(keyset.id));
    expect(loadedKeysets[0].mintUrl, equals(keyset.mintUrl));
  });

  test('getKeysets without filter', () async {
    final cacheManager = getCacheManager();
    final keyset1 = CahsuKeyset(
      id: 'keyset1',
      mintUrl: 'https://mint1.com',
      unit: 'sat',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
    );
    final keyset2 = CahsuKeyset(
      id: 'keyset2',
      mintUrl: 'https://mint2.com',
      unit: 'sat',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
    );

    await cacheManager.saveKeyset(keyset1);
    await cacheManager.saveKeyset(keyset2);

    final allKeysets = await cacheManager.getKeysets();
    expect(allKeysets.length, greaterThanOrEqualTo(2));
  });

  test('saveProofs and getProofs', () async {
    final cacheManager = getCacheManager();
    final proof = CashuProof(
      keysetId: 'test_keyset',
      amount: 10,
      secret: 'test_secret',
      unblindedSig: 'test_sig',
      state: CashuProofState.unspend,
    );

    final cashuKeyset = CahsuKeyset(
      id: 'test_keyset',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
      mintUrl: 'https://test.mint.com',
      unit: 'sat',
    );
    await cacheManager.saveKeyset(cashuKeyset);

    await cacheManager
        .saveProofs(proofs: [proof], mintUrl: 'https://test.mint.com');
    final loadedProofs = await cacheManager.getProofs(
      mintUrl: 'https://test.mint.com',
      state: CashuProofState.unspend,
    );

    expect(loadedProofs.length, equals(1));
    expect(loadedProofs[0].keysetId, equals(proof.keysetId));
    expect(loadedProofs[0].amount, equals(proof.amount));
  });

  test('getProofs with state filter', () async {
    final cacheManager = getCacheManager();
    final proof1 = CashuProof(
      keysetId: 'keyset1',
      amount: 5,
      secret: 'secret1',
      unblindedSig: 'sig1',
      state: CashuProofState.unspend,
    );
    final proof2 = CashuProof(
      keysetId: 'keyset1',
      amount: 10,
      secret: 'secret2',
      unblindedSig: 'sig2',
      state: CashuProofState.spend,
    );

    final cashuKeyset = CahsuKeyset(
      id: 'keyset1',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
      mintUrl: 'https://mint.com',
      unit: 'sat',
    );
    await cacheManager.saveKeyset(cashuKeyset);

    await cacheManager
        .saveProofs(proofs: [proof1, proof2], mintUrl: 'https://mint.com');

    final unspendProofs = await cacheManager.getProofs(
      mintUrl: 'https://mint.com',
      state: CashuProofState.unspend,
    );
    expect(unspendProofs.length, equals(1));
    expect(unspendProofs[0].state, equals(CashuProofState.unspend));

    final spendProofs = await cacheManager.getProofs(
      mintUrl: 'https://mint.com',
      state: CashuProofState.spend,
    );
    expect(spendProofs.length, equals(1));
    expect(spendProofs[0].state, equals(CashuProofState.spend));
  });

  test('saveMintInfo and getMintInfos', () async {
    final cacheManager = getCacheManager();
    final mintInfo = CashuMintInfo(
      urls: ['https://mint.info.com'],
      name: 'Test Mint',
      description: 'A test mint',
      version: '1.0',
      nuts: {},
    );

    await cacheManager.saveMintInfo(mintInfo: mintInfo);
    final loadedInfos =
        await cacheManager.getMintInfos(mintUrls: ['https://mint.info.com']);
    expect(loadedInfos!.length, equals(1));
    expect(loadedInfos[0].urls, equals(mintInfo.urls));
    expect(loadedInfos[0].name, equals(mintInfo.name));
  });

  test('getCashuSecretCounter and setCashuSecretCounter', () async {
    final cacheManager = getCacheManager();
    const keysetId = 'counter_keyset';
    const initialCounter = 5;

    await cacheManager.setCashuSecretCounter(
        mintUrl: 'https://counter.mint.com',
        keysetId: keysetId,
        counter: initialCounter);
    final loadedCounter = await cacheManager.getCashuSecretCounter(
        mintUrl: "https://counter.mint.com", keysetId: keysetId);
    expect(loadedCounter, equals(initialCounter));

    const newCounter = 10;
    await cacheManager.setCashuSecretCounter(
        mintUrl: 'https://counter.mint.com',
        keysetId: keysetId,
        counter: newCounter);
    final updatedCounter = await cacheManager.getCashuSecretCounter(
        mintUrl: "https://counter.mint.com", keysetId: keysetId);
    expect(updatedCounter, equals(newCounter));
  });

  test('proof upsert behavior', () async {
    final cacheManager = getCacheManager();
    final proof = CashuProof(
      keysetId: 'upsert_keyset',
      amount: 15,
      secret: 'upsert_secret',
      unblindedSig: 'upsert_sig',
      state: CashuProofState.unspend,
    );

    final cashuKeyset = CahsuKeyset(
      id: 'upsert_keyset',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
      mintUrl: 'https://upsert.mint.com',
      unit: 'sat',
    );
    await cacheManager.saveKeyset(cashuKeyset);

    await cacheManager
        .saveProofs(proofs: [proof], mintUrl: 'https://upsert.mint.com');

    // Update the state
    proof.state = CashuProofState.pending;
    await cacheManager
        .saveProofs(proofs: [proof], mintUrl: 'https://upsert.mint.com');

    final loadedProofsUnspend = await cacheManager.getProofs(
        mintUrl: 'https://upsert.mint.com', state: CashuProofState.unspend);
    expect(loadedProofsUnspend.length, equals(0));

    final loadedProofsPending = await cacheManager.getProofs(
        mintUrl: 'https://upsert.mint.com', state: CashuProofState.pending);
    expect(loadedProofsPending.length, equals(1));
    expect(loadedProofsPending[0].state, equals(CashuProofState.pending));
  });

  test('removeMintInfo deletes mint info', () async {
    final cacheManager = getCacheManager();
    final mintInfo = CashuMintInfo(
      urls: ['https://delete.mint.com'],
      name: 'Delete Test Mint',
      description: 'A mint to be deleted',
      version: '1.0',
      nuts: {},
    );

    // Save the mint info
    await cacheManager.saveMintInfo(mintInfo: mintInfo);

    // Verify it was saved
    final savedInfos = await cacheManager.getMintInfos(
      mintUrls: ['https://delete.mint.com'],
    );
    expect(savedInfos!.length, equals(1));
    expect(savedInfos[0].name, equals('Delete Test Mint'));

    // Delete the mint info
    await cacheManager.removeMintInfo(mintUrl: 'https://delete.mint.com');

    // Verify it was deleted
    final deletedInfos = await cacheManager.getMintInfos(
      mintUrls: ['https://delete.mint.com'],
    );
    expect(deletedInfos, anyOf(isNull, isEmpty));
  });
}
