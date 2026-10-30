part of 'cache_manager_test_suite.dart';

void _runNip05Tests(CacheManager Function() getCacheManager) {
  test('saveNip05 and loadNip05', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: 'nip05_pubkey_1',
      identifier: 'test@example.com',
      valid: true,
      networkFetchTime: 1234567890,
      relays: ['wss://relay1.com', 'wss://relay2.com'],
    );

    await cacheManager.saveNip05(nip05);
    final loaded = await cacheManager.loadNip05('test@example.com');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(nip05.pubKey));
    expect(loaded.identifier, equals(nip05.identifier));
    expect(loaded.valid, equals(nip05.valid));
    expect(loaded.networkFetchTime, equals(nip05.networkFetchTime));
    expect(loaded.relays, equals(nip05.relays));
  });

  test('saveNip05 stores an identifier without pubkey', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: null,
      identifier: 'ghost@example.com',
      networkFetchTime: 1234567890,
    );

    await cacheManager.saveNip05(nip05);
    final loaded = await cacheManager.loadNip05('ghost@example.com');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, isNull);
    expect(loaded.valid, isFalse);
    expect(loaded.networkFetchTime, equals(1234567890));
  });

  test('saveNip05 keeps every identifier of a pubkey', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(pubKey: 'nip05_shared', identifier: 'alice@a.com', valid: true),
      Nip05(pubKey: 'nip05_shared', identifier: 'alice@b.com', valid: true),
    ];

    for (final nip05 in nip05s) {
      await cacheManager.saveNip05(nip05);
    }

    for (final nip05 in nip05s) {
      final loaded = await cacheManager.loadNip05(nip05.identifier);
      expect(loaded?.pubKey, equals('nip05_shared'));
    }
  });

  test('saveNip05 replaces the record of an identifier', () async {
    final cacheManager = getCacheManager();

    await cacheManager.saveNip05(
      Nip05(
        pubKey: 'nip05_old',
        identifier: 'replaced@example.com',
        valid: true,
        networkFetchTime: 2,
      ),
    );
    await cacheManager.saveNip05(
      Nip05(
        pubKey: null,
        identifier: 'replaced@example.com',
        networkFetchTime: 1,
      ),
    );

    final loaded = await cacheManager.loadNip05('replaced@example.com');
    expect(loaded, isNotNull);
    expect(loaded!.pubKey, isNull);
    expect(loaded.networkFetchTime, equals(1));
  });

  test('saveNip05s batch operation', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(
        pubKey: 'nip05_batch_1',
        identifier: 'user1@example.com',
        valid: true,
      ),
      Nip05(pubKey: null, identifier: 'user2@example.com'),
    ];

    await cacheManager.saveNip05s(nip05s);

    for (final nip05 in nip05s) {
      final loaded = await cacheManager.loadNip05(nip05.identifier);
      expect(loaded, isNotNull);
      expect(loaded!.pubKey, equals(nip05.pubKey));
      expect(loaded.valid, equals(nip05.valid));
    }
  });

  test('loadNip05s batch operation', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(
        pubKey: 'nip05_load_1',
        identifier: 'user1@example.com',
        valid: true,
      ),
      Nip05(pubKey: null, identifier: 'user2@example.com'),
    ];

    await cacheManager.saveNip05s(nip05s);
    final loaded = await cacheManager.loadNip05s([
      'user1@example.com',
      'user2@example.com',
      'nonexistent@example.com',
    ]);

    expect(loaded.length, equals(3));
    expect(loaded[0]?.pubKey, equals('nip05_load_1'));
    expect(loaded[1]?.identifier, equals('user2@example.com'));
    expect(loaded[1]?.pubKey, isNull);
    expect(loaded[2], isNull);
  });

  test('removeNip05', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: 'nip05_remove',
      identifier: 'remove@example.com',
      valid: true,
    );

    await cacheManager.saveNip05(nip05);
    expect(await cacheManager.loadNip05('remove@example.com'), isNotNull);

    await cacheManager.removeNip05('remove@example.com');
    expect(await cacheManager.loadNip05('remove@example.com'), isNull);
  });

  test('removeAllNip05s', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(pubKey: 'nip05_clear_1', identifier: 'u1@ex.com', valid: true),
      Nip05(pubKey: null, identifier: 'u2@ex.com'),
    ];

    await cacheManager.saveNip05s(nip05s);
    await cacheManager.removeAllNip05s();

    for (final nip05 in nip05s) {
      expect(await cacheManager.loadNip05(nip05.identifier), isNull);
    }
  });
}
