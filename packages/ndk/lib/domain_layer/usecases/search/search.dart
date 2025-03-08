import '../../entities/filter.dart';
import '../../entities/metadata.dart';
import '../../repositories/cache_manager.dart';

class Search {
  final CacheManager _cacheManager;

  Search(CacheManager _cacheManager) : _cacheManager = _cacheManager;

  // Future<List<SearchResult>> advancedSearch(Filter query) async {
  //   return await _searchRepository.search(query);
  // }

  // Future<List<SearchResult>> search(String query) async {
  //   return await _searchRepository.search(query);
  // }

  /// Search for metadata \
  /// [query] can be pubkey, name, nip05
  Future<List<Metadata>> metadataSearch(String query, {int limit = 10}) async {
    final result = await _cacheManager.searchMetadatas(query, limit);
    return result.toList();
  }
}
