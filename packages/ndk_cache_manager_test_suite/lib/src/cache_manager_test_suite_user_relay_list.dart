part of 'cache_manager_test_suite.dart';

void _runUserRelayListTests(CacheManager Function() getCacheManager) {
  test('saveUserRelayList and loadUserRelayList', () async {
    final cacheManager = getCacheManager();
    final userRelayList = UserRelayList(
      pubKey: 'relay_list_pubkey_1',
      createdAt: 1234567890,
      refreshedTimestamp: 1234567895,
      relays: {
        'wss://relay1.com': ReadWriteMarker.readWrite,
        'wss://relay2.com': ReadWriteMarker.readOnly,
        'wss://relay3.com': ReadWriteMarker.writeOnly,
      },
    );

    await cacheManager.saveUserRelayList(userRelayList);
    final loaded = await cacheManager.loadUserRelayList('relay_list_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(userRelayList.pubKey));
    expect(loaded.createdAt, equals(userRelayList.createdAt));
    expect(loaded.relays.length, equals(3));
    expect(
        loaded.relays['wss://relay1.com'], equals(ReadWriteMarker.readWrite));
    expect(loaded.relays['wss://relay2.com'], equals(ReadWriteMarker.readOnly));
    expect(
        loaded.relays['wss://relay3.com'], equals(ReadWriteMarker.writeOnly));
  });

  test('saveUserRelayLists batch operation', () async {
    final cacheManager = getCacheManager();
    final userRelayLists = [
      UserRelayList(
        pubKey: 'relay_batch_1',
        createdAt: 1234567890,
        refreshedTimestamp: 1234567890,
        relays: {'wss://relay1.com': ReadWriteMarker.readWrite},
      ),
      UserRelayList(
        pubKey: 'relay_batch_2',
        createdAt: 1234567891,
        refreshedTimestamp: 1234567891,
        relays: {'wss://relay2.com': ReadWriteMarker.readOnly},
      ),
    ];

    await cacheManager.saveUserRelayLists(userRelayLists);

    for (final userRelayList in userRelayLists) {
      final loaded = await cacheManager.loadUserRelayList(userRelayList.pubKey);
      expect(loaded, isNotNull);
      expect(loaded!.relays.length, equals(1));
    }
  });

  test('removeUserRelayList', () async {
    final cacheManager = getCacheManager();
    final userRelayList = UserRelayList(
      pubKey: 'relay_remove',
      createdAt: 1234567890,
      refreshedTimestamp: 1234567890,
      relays: {'wss://relay.com': ReadWriteMarker.readWrite},
    );

    await cacheManager.saveUserRelayList(userRelayList);
    expect(await cacheManager.loadUserRelayList('relay_remove'), isNotNull);

    await cacheManager.removeUserRelayList('relay_remove');
    expect(await cacheManager.loadUserRelayList('relay_remove'), isNull);
  });

  test('removeAllUserRelayLists', () async {
    final cacheManager = getCacheManager();
    final userRelayLists = [
      UserRelayList(
        pubKey: 'relay_clear_1',
        createdAt: 1234567890,
        refreshedTimestamp: 1234567890,
        relays: {},
      ),
      UserRelayList(
        pubKey: 'relay_clear_2',
        createdAt: 1234567891,
        refreshedTimestamp: 1234567891,
        relays: {},
      ),
    ];

    await cacheManager.saveUserRelayLists(userRelayLists);
    await cacheManager.removeAllUserRelayLists();

    for (final userRelayList in userRelayLists) {
      expect(
          await cacheManager.loadUserRelayList(userRelayList.pubKey), isNull);
    }
  });

  test('kind 10002 event recomputes user relay list projection', () async {
    final cacheManager = getCacheManager();
    final event = Nip65(
      pubKey: 'relay_projection_pubkey',
      createdAt: 2000,
      relays: {
        'wss://relay1.com': ReadWriteMarker.readWrite,
        'wss://relay2.com': ReadWriteMarker.readOnly,
      },
    ).toEvent();

    await cacheManager.saveEvent(event);

    final loaded = await cacheManager.loadUserRelayList(
      'relay_projection_pubkey',
    );
    expect(loaded, isNotNull);
    expect(loaded!.createdAt, equals(2000));
    expect(
      loaded.relays['wss://relay1.com'],
      equals(ReadWriteMarker.readWrite),
    );
    expect(
      loaded.relays['wss://relay2.com'],
      equals(ReadWriteMarker.readOnly),
    );
  });

  test('kind 10002 takes precedence over kind 3 relay projection', () async {
    final cacheManager = getCacheManager();
    final kind3 = Nip01Event(
      pubKey: 'relay_precedence_pubkey',
      kind: ContactList.kKind,
      createdAt: 1000,
      tags: const [],
      content:
          '{"wss://legacy-relay.com":{"read":true,"write":true}}',
    );
    final kind10002 = Nip65(
      pubKey: 'relay_precedence_pubkey',
      createdAt: 2000,
      relays: {
        'wss://preferred-relay.com': ReadWriteMarker.writeOnly,
      },
    ).toEvent();

    await cacheManager.saveEvents([kind3, kind10002]);

    final loaded = await cacheManager.loadUserRelayList(
      'relay_precedence_pubkey',
    );
    expect(loaded, isNotNull);
    expect(
      loaded!.relays.keys,
      equals(['wss://preferred-relay.com']),
    );
    expect(
      loaded.relays['wss://preferred-relay.com'],
      equals(ReadWriteMarker.writeOnly),
    );
  });
}
