part of 'cache_manager_test_suite.dart';

void _runNip05Tests(CacheManager Function() getCacheManager) {
  test('saveNip05 and loadNip05', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: 'nip05_pubkey_1',
      nip05: 'test@example.com',
      valid: true,
      networkFetchTime: 1234567890,
      relays: ['wss://relay1.com', 'wss://relay2.com'],
    );

    await cacheManager.saveNip05(nip05);
    final loaded = await cacheManager.loadNip05(pubKey: 'nip05_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(nip05.pubKey));
    expect(loaded.nip05, equals(nip05.nip05));
    expect(loaded.valid, equals(nip05.valid));
    expect(loaded.networkFetchTime, equals(nip05.networkFetchTime));
    expect(loaded.relays, equals(nip05.relays));
  });

  test('loadNip05 by identifier', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: 'nip05_id_pubkey',
      nip05: 'testuser@example.com',
      valid: true,
      networkFetchTime: 1234567890,
      relays: ['wss://relay1.com'],
    );

    await cacheManager.saveNip05(nip05);
    final loaded =
        await cacheManager.loadNip05(identifier: 'testuser@example.com');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(nip05.pubKey));
    expect(loaded.nip05, equals(nip05.nip05));
    expect(loaded.valid, equals(nip05.valid));
  });

  test('saveNip05s batch operation', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(pubKey: 'nip05_batch_1', nip05: 'user1@example.com', valid: true),
      Nip05(pubKey: 'nip05_batch_2', nip05: 'user2@example.com', valid: false),
    ];

    await cacheManager.saveNip05s(nip05s);

    for (final nip05 in nip05s) {
      final loaded = await cacheManager.loadNip05(pubKey: nip05.pubKey);
      expect(loaded, isNotNull);
      expect(loaded!.nip05, equals(nip05.nip05));
      expect(loaded.valid, equals(nip05.valid));
    }
  });

  test('loadNip05s batch operation', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(pubKey: 'nip05_load_1', nip05: 'user1@example.com', valid: true),
      Nip05(pubKey: 'nip05_load_2', nip05: 'user2@example.com', valid: false),
    ];

    await cacheManager.saveNip05s(nip05s);
    final loaded = await cacheManager.loadNip05s([
      'nip05_load_1',
      'nip05_load_2',
      'nonexistent',
    ]);

    expect(loaded.length, equals(3));
    expect(loaded[0]?.nip05, equals('user1@example.com'));
    expect(loaded[1]?.nip05, equals('user2@example.com'));
    expect(loaded[2], isNull);
  });

  test('removeNip05', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: 'nip05_remove',
      nip05: 'test@example.com',
      valid: true,
    );

    await cacheManager.saveNip05(nip05);
    expect(await cacheManager.loadNip05(pubKey: 'nip05_remove'), isNotNull);

    await cacheManager.removeNip05('nip05_remove');
    expect(await cacheManager.loadNip05(pubKey: 'nip05_remove'), isNull);
  });

  test('removeAllNip05s', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(pubKey: 'nip05_clear_1', nip05: 'u1@ex.com', valid: true),
      Nip05(pubKey: 'nip05_clear_2', nip05: 'u2@ex.com', valid: false),
    ];

    await cacheManager.saveNip05s(nip05s);
    await cacheManager.removeAllNip05s();

    for (final nip05 in nip05s) {
      expect(await cacheManager.loadNip05(pubKey: nip05.pubKey), isNull);
    }
  });
}
