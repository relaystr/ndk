import '../../entities/cashu/wallet_cahsu_keyset.dart';
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
  /// Returns a list of [WalletCahsuKeyset]. \
  /// [mintURL] The URL of the mint to fetch keysets from. \
  /// [validityDurationSeconds] The duration in seconds for which the cache is valid.
  Future<List<WalletCahsuKeyset>> getKeysetsFromMint(
    String mintURL, {
    int validityDurationSeconds = 24 * 60 * 60, // 24 hours
  }) async {
    final cachedKeysets = await getKeysetFromCache(mintURL);

    if (cachedKeysets != null && cachedKeysets.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final isCacheStale = cachedKeysets.any((keyset) =>
          keyset.fetchedAt == null ||
          (now - keyset.fetchedAt!) >= validityDurationSeconds);

      if (!isCacheStale) {
        return cachedKeysets;
      }
    }

    return getKeysetMintFromNetwork(mintURL: mintURL);
  }

  Future<List<WalletCahsuKeyset>> getKeysetMintFromNetwork({
    required String mintURL,
  }) async {
    final List<WalletCahsuKeyset> mintKeys = [];
    final keySets = await _cashuRepo.getKeysets(
      mintURL: mintURL,
    );

    for (final keySet in keySets) {
      final keys = await _cashuRepo.getKeys(
        mintURL: mintURL,
        keysetId: keySet.id,
      );

      mintKeys.add(
        WalletCahsuKeyset.fromResponses(
          keysetResponse: keySet,
          keysResponse: keys.first,
        ),
      );
    }
    return mintKeys;
  }

  Future<void> saveKeyset(WalletCahsuKeyset keyset) async {
    await _cacheManager.saveKeyset(keyset);
  }

  Future<List<WalletCahsuKeyset>?> getKeysetFromCache(String mintURL) async {
    try {
      return await _cacheManager.getKeysets(mintURL: mintURL);
    } catch (e) {
      return null;
    }
  }
}
