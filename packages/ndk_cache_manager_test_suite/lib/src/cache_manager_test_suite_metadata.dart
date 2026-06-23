part of 'cache_manager_test_suite.dart';

void _runMetadataTests(CacheManager Function() getCacheManager) {
  test('saveMetadata and loadMetadata', () async {
    final cacheManager = getCacheManager();
    final metadata = Metadata(
      pubKey: 'metadata_pubkey_1',
      name: 'Test User',
      displayName: 'Test Display Name',
      about: 'Test about text',
      picture: 'https://example.com/pic.jpg',
      banner: 'https://example.com/banner.jpg',
      website: 'https://example.com',
      nip05: 'test@example.com',
      lud16: 'test@walletofsatoshi.com',
      lud06: 'lnurl1234',
      updatedAt: 1234567890,
    );

    await cacheManager.saveMetadata(metadata);
    final loaded = await cacheManager.loadMetadata('metadata_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(metadata.pubKey));
    expect(loaded.name, equals(metadata.name));
    expect(loaded.displayName, equals(metadata.displayName));
    expect(loaded.about, equals(metadata.about));
    expect(loaded.picture, equals(metadata.picture));
    expect(loaded.banner, equals(metadata.banner));
    expect(loaded.website, equals(metadata.website));
    expect(loaded.nip05, equals(metadata.nip05));
    expect(loaded.lud16, equals(metadata.lud16));
    expect(loaded.lud06, equals(metadata.lud06));
  });

  test('saveMetadatas batch operation', () async {
    final cacheManager = getCacheManager();
    final metadatas = [
      Metadata(pubKey: 'metadata_batch_1', name: 'User 1'),
      Metadata(pubKey: 'metadata_batch_2', name: 'User 2'),
    ];

    await cacheManager.saveMetadatas(metadatas);

    for (final metadata in metadatas) {
      final loaded = await cacheManager.loadMetadata(metadata.pubKey);
      expect(loaded, isNotNull);
      expect(loaded!.name, equals(metadata.name));
    }
  });

  test('loadMetadatas batch operation', () async {
    final cacheManager = getCacheManager();
    final metadatas = [
      Metadata(pubKey: 'metadata_load_batch_1', name: 'User 1'),
      Metadata(pubKey: 'metadata_load_batch_2', name: 'User 2'),
    ];

    await cacheManager.saveMetadatas(metadatas);
    final loaded = await cacheManager.loadMetadatas([
      'metadata_load_batch_1',
      'metadata_load_batch_2',
      'nonexistent_pubkey',
    ]);

    expect(loaded.length, equals(3));
    expect(loaded[0]?.name, equals('User 1'));
    expect(loaded[1]?.name, equals('User 2'));
    expect(loaded[2], isNull);
  });

  test('removeMetadata', () async {
    final cacheManager = getCacheManager();
    final metadata = Metadata(pubKey: 'metadata_remove', name: 'Test User');

    await cacheManager.saveMetadata(metadata);
    expect(await cacheManager.loadMetadata('metadata_remove'), isNotNull);

    await cacheManager.removeMetadata('metadata_remove');
    expect(await cacheManager.loadMetadata('metadata_remove'), isNull);
  });

  test('removeAllMetadatas', () async {
    final cacheManager = getCacheManager();
    final metadatas = [
      Metadata(pubKey: 'metadata_clear_1', name: 'User 1'),
      Metadata(pubKey: 'metadata_clear_2', name: 'User 2'),
    ];

    await cacheManager.saveMetadatas(metadatas);
    await cacheManager.removeAllMetadatas();

    for (final metadata in metadatas) {
      expect(await cacheManager.loadMetadata(metadata.pubKey), isNull);
    }
  });

  test('metadata update overwrites existing', () async {
    final cacheManager = getCacheManager();
    final metadata1 = Metadata(
      pubKey: 'metadata_update',
      name: 'Original Name',
      updatedAt: 1000,
    );

    await cacheManager.saveMetadata(metadata1);

    final metadata2 = Metadata(
      pubKey: 'metadata_update',
      name: 'Updated Name',
      updatedAt: 2000,
    );

    await cacheManager.saveMetadata(metadata2);

    final loaded = await cacheManager.loadMetadata('metadata_update');
    expect(loaded, isNotNull);
    expect(loaded!.name, equals('Updated Name'));
  });

  test('loadMetadata reads latest visible generic metadata event', () async {
    final cacheManager = getCacheManager();
    final older = Metadata(
      pubKey: 'metadata_from_event',
      name: 'Older Name',
      updatedAt: 1000,
    ).toEvent();
    final newer = Metadata(
      pubKey: 'metadata_from_event',
      name: 'Newer Name',
      updatedAt: 2000,
    ).toEvent();

    await cacheManager.saveEvents([older, newer]);

    final loaded = await cacheManager.loadMetadata('metadata_from_event');
    expect(loaded, isNotNull);
    expect(loaded!.name, equals('Newer Name'));
    expect(loaded.updatedAt, equals(2000));
  });

  test('metadata preserves tags and content', () async {
    final cacheManager = getCacheManager();
    final metadata = Metadata(
      pubKey: 'metadata_tags_rawcontent',
      name: 'Test User',
      displayName: 'Test Display',
      tags: [
        ['i', 'github:user123', 'abc123'],
        ['i', 'twitter:handle', 'xyz789'],
      ],
      content: {
        'name': 'Test User',
        'display_name': 'Test Display',
        'custom_field': 'custom_value',
        'nested': {'key': 'value'},
      },
    );

    await cacheManager.saveMetadata(metadata);
    final loaded = await cacheManager.loadMetadata('metadata_tags_rawcontent');

    expect(loaded, isNotNull);
    expect(loaded!.tags.length, equals(2));
    expect(loaded.tags[0], equals(['i', 'github:user123', 'abc123']));
    expect(loaded.tags[1], equals(['i', 'twitter:handle', 'xyz789']));
    expect(loaded.content, isNotNull);
    expect(loaded.content['custom_field'], equals('custom_value'));
    expect(loaded.content['nested'], equals({'key': 'value'}));
  });

  test('metadata with empty tags and content', () async {
    final cacheManager = getCacheManager();
    final metadata = Metadata(
      pubKey: 'metadata_empty_tags',
      name: 'Test User',
    );

    await cacheManager.saveMetadata(metadata);
    final loaded = await cacheManager.loadMetadata('metadata_empty_tags');

    expect(loaded, isNotNull);
    expect(loaded!.tags, isEmpty);
    expect(loaded.content, isNotEmpty);
    expect(loaded.content['name'], equals('Test User'));
  });
}
