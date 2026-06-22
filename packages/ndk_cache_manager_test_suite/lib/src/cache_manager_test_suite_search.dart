part of 'cache_manager_test_suite.dart';

void _runSearchTests(CacheManager Function() getCacheManager) {
  test('searchMetadatas by name', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllMetadatas();

    final metadatas = [
      Metadata(
          pubKey: 'search_meta_1', name: 'Alice Smith', displayName: 'Alice'),
      Metadata(
          pubKey: 'search_meta_2', name: 'Bob Jones', displayName: 'Bobby'),
      Metadata(
          pubKey: 'search_meta_3',
          name: 'Alice Wonder',
          nip05: 'alice@example.com'),
    ];

    await cacheManager.saveMetadatas(metadatas);

    final aliceResults = await cacheManager.searchMetadatas('Alice', 10);
    expect(aliceResults.length, greaterThanOrEqualTo(2));
    expect(
        aliceResults.every((m) =>
            m.name?.toLowerCase().contains('alice') == true ||
            m.displayName?.toLowerCase().contains('alice') == true ||
            m.nip05?.toLowerCase().contains('alice') == true),
        isTrue);
  });

  test('searchMetadatas with limit', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllMetadatas();

    final metadatas = List.generate(
      5,
      (i) => Metadata(pubKey: 'search_limit_$i', name: 'User $i'),
    );

    await cacheManager.saveMetadatas(metadatas);

    final results = await cacheManager.searchMetadatas('User', 2);
    expect(results.length, lessThanOrEqualTo(2));
  });
}
