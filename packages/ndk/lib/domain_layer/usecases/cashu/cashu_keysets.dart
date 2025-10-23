import '../../entities/cashu/cashu_keyset.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/cashu_repo.dart';

class CashuKeysets {
  final CashuRepo _cashuRepo;
  final CacheManager _cacheManager;

  CashuKeysets({
    required CashuRepo cashuRepo,
    required CacheManager cacheManager,
  })  : _cashuRepo = cashuRepo,
        _cacheManager = cacheManager;

  /// Fetches keysets from the cache or network. \
  /// If the cache is stale or empty, it fetches from the network. \
  /// Returns a list of [CahsuKeyset]. \
  /// [mintUrl] The URL of the mint to fetch keysets from. \
  /// [validityDurationSeconds] The duration in seconds for which the cache is valid.
  Future<List<CahsuKeyset>> getKeysetsFromMint(
    String mintUrl, {
    int validityDurationSeconds = 24 * 60 * 60, // 24 hours
  }) async {
    final cachedKeysets = await getKeysetFromCache(mintUrl);

    if (cachedKeysets != null && cachedKeysets.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final isCacheStale = cachedKeysets.any((keyset) =>
          keyset.fetchedAt == null ||
          (now - keyset.fetchedAt!) >= validityDurationSeconds);

      if (!isCacheStale) {
        return cachedKeysets;
      }
    }

    final networkKeyset = await getKeysetMintFromNetwork(mintUrl: mintUrl);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final keyset in networkKeyset) {
      keyset.fetchedAt = now;
      await saveKeyset(keyset);
    }
    return networkKeyset;
  }

  Future<List<CahsuKeyset>> getKeysetMintFromNetwork({
    required String mintUrl,
  }) async {
    final List<CahsuKeyset> mintKeys = [];
    final keySets = await _cashuRepo.getKeysets(
      mintUrl: mintUrl,
    );

    for (final keySet in keySets) {
      final keys = await _cashuRepo.getKeys(
        mintUrl: mintUrl,
        keysetId: keySet.id,
      );

      mintKeys.add(
        CahsuKeyset.fromResponses(
          keysetResponse: keySet,
          keysResponse: keys.first,
        ),
      );
    }
    return mintKeys;
  }

  Future<void> saveKeyset(CahsuKeyset keyset) async {
    await _cacheManager.saveKeyset(keyset);
  }

  Future<List<CahsuKeyset>?> getKeysetFromCache(String mintUrl) async {
    try {
      return await _cacheManager.getKeysets(mintUrl: mintUrl);
    } catch (e) {
      return null;
    }
  }
}
