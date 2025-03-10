import '../../entities/filter.dart';
import '../../entities/metadata.dart';
import '../../entities/nip_01_event.dart';
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

  Future<Iterable<Nip01Event>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 100,
  }) async {
    return await _cacheManager.searchEvents(
      ids: ids,
      authors: authors,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
      limit: limit,
    );
  }
}
