part of 'cache_manager_test_suite.dart';

void _runRelaySetTests(CacheManager Function() getCacheManager) {
  test('saveRelaySet and loadRelaySet', () async {
    final cacheManager = getCacheManager();
    final relaySet = RelaySet(
      name: 'test_set',
      pubKey: 'relay_set_pubkey_1',
      relayMinCountPerPubkey: 2,
      direction: RelayDirection.outbox,
      relaysMap: {
        'wss://relay1.com': [
          PubkeyMapping(pubKey: 'user1', rwMarker: ReadWriteMarker.readWrite),
          PubkeyMapping(pubKey: 'user2', rwMarker: ReadWriteMarker.readOnly),
        ],
        'wss://relay2.com': [
          PubkeyMapping(pubKey: 'user3', rwMarker: ReadWriteMarker.writeOnly),
        ],
      },
      notCoveredPubkeys: [],
      fallbackToBootstrapRelays: true,
    );

    await cacheManager.saveRelaySet(relaySet);
    final loaded =
        await cacheManager.loadRelaySet('test_set', 'relay_set_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.name, equals(relaySet.name));
    expect(loaded.pubKey, equals(relaySet.pubKey));
    expect(loaded.relayMinCountPerPubkey, equals(2));
    expect(loaded.direction, equals(RelayDirection.outbox));
    expect(loaded.relaysMap.length, equals(2));
    expect(loaded.relaysMap['wss://relay1.com']?.length, equals(2));
  });

  test('removeRelaySet', () async {
    final cacheManager = getCacheManager();
    final relaySet = RelaySet(
      name: 'set_to_remove',
      pubKey: 'relay_set_remove',
      relayMinCountPerPubkey: 1,
      direction: RelayDirection.inbox,
      relaysMap: {},
      notCoveredPubkeys: [],
    );

    await cacheManager.saveRelaySet(relaySet);
    expect(
      await cacheManager.loadRelaySet('set_to_remove', 'relay_set_remove'),
      isNotNull,
    );

    await cacheManager.removeRelaySet('set_to_remove', 'relay_set_remove');
    expect(
      await cacheManager.loadRelaySet('set_to_remove', 'relay_set_remove'),
      isNull,
    );
  });

  test('removeAllRelaySets', () async {
    final cacheManager = getCacheManager();
    final relaySets = [
      RelaySet(
        name: 'set_clear_1',
        pubKey: 'relay_set_clear_1',
        relayMinCountPerPubkey: 1,
        direction: RelayDirection.inbox,
        relaysMap: {},
        notCoveredPubkeys: [],
      ),
      RelaySet(
        name: 'set_clear_2',
        pubKey: 'relay_set_clear_2',
        relayMinCountPerPubkey: 1,
        direction: RelayDirection.outbox,
        relaysMap: {},
        notCoveredPubkeys: [],
      ),
    ];

    for (final relaySet in relaySets) {
      await cacheManager.saveRelaySet(relaySet);
    }
    await cacheManager.removeAllRelaySets();

    for (final relaySet in relaySets) {
      expect(
        await cacheManager.loadRelaySet(relaySet.name, relaySet.pubKey),
        isNull,
      );
    }
  });
}
