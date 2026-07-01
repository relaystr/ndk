part of 'cache_manager_test_suite.dart';

void _runClearAllTests(CacheManager Function() getCacheManager) {
  test('clearAll removes all cached data', () async {
    final cacheManager = getCacheManager();

    final event = Nip01Event(
      pubKey: 'clearall_event_pubkey',
      kind: 1,
      tags: [],
      content: 'Test event',
      createdAt: 1234567890,
    );
    await cacheManager.saveEvent(event);

    final metadata = Metadata(pubKey: 'clearall_metadata_pubkey', name: 'Test');
    await cacheManager.saveMetadata(metadata);

    final contactList = ContactList(
      pubKey: 'clearall_contact_pubkey',
      contacts: ['contact1'],
    );
    await cacheManager.saveContactList(contactList);

    final nip05 = Nip05(
      pubKey: 'clearall_nip05_pubkey',
      nip05: 'test@example.com',
      valid: true,
    );
    await cacheManager.saveNip05(nip05);

    final userRelayList = UserRelayList(
      pubKey: 'clearall_relay_pubkey',
      createdAt: 1234567890,
      refreshedTimestamp: 1234567890,
      relays: {'wss://relay.com': ReadWriteMarker.readWrite},
    );
    await cacheManager.saveUserRelayList(userRelayList);

    final relaySet = RelaySet(
      name: 'clearall_set',
      pubKey: 'clearall_relayset_pubkey',
      relayMinCountPerPubkey: 1,
      direction: RelayDirection.inbox,
      relaysMap: {},
      notCoveredPubkeys: [],
    );
    await cacheManager.saveRelaySet(relaySet);

    final keyset = CahsuKeyset(
      id: 'clearall_keyset',
      mintUrl: 'https://clearall.mint.com',
      unit: 'sat',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
    );
    await cacheManager.saveKeyset(keyset);

    final proof = CashuProof(
      keysetId: 'clearall_keyset',
      amount: 100,
      secret: 'clearall_secret',
      unblindedSig: 'clearall_sig',
      state: CashuProofState.unspend,
    );
    await cacheManager
        .saveProofs(proofs: [proof], mintUrl: 'https://clearall.mint.com');

    expect(await cacheManager.loadEvent(event.id), isNotNull);
    expect(
        await cacheManager.loadMetadata('clearall_metadata_pubkey'), isNotNull);
    expect(await cacheManager.loadContactList('clearall_contact_pubkey'),
        isNotNull);
    expect(await cacheManager.loadNip05(pubKey: 'clearall_nip05_pubkey'),
        isNotNull);
    expect(await cacheManager.loadUserRelayList('clearall_relay_pubkey'),
        isNotNull);
    expect(
        await cacheManager.loadRelaySet(
            'clearall_set', 'clearall_relayset_pubkey'),
        isNotNull);
    expect(
        (await cacheManager.getKeysets(mintUrl: 'https://clearall.mint.com'))
            .length,
        equals(1));
    expect(
        (await cacheManager.getProofs(mintUrl: 'https://clearall.mint.com'))
            .length,
        equals(1));

    await cacheManager.clearAll();

    expect(await cacheManager.loadEvent(event.id), isNull);
    expect(await cacheManager.loadMetadata('clearall_metadata_pubkey'), isNull);
    expect(
        await cacheManager.loadContactList('clearall_contact_pubkey'), isNull);
    expect(
        await cacheManager.loadNip05(pubKey: 'clearall_nip05_pubkey'), isNull);
    expect(
        await cacheManager.loadUserRelayList('clearall_relay_pubkey'), isNull);
    expect(
        await cacheManager.loadRelaySet(
            'clearall_set', 'clearall_relayset_pubkey'),
        isNull);
    expect(
        (await cacheManager.getKeysets(mintUrl: 'https://clearall.mint.com'))
            .length,
        equals(0));
    expect(
        (await cacheManager.getProofs(mintUrl: 'https://clearall.mint.com'))
            .length,
        equals(0));
  });
}
