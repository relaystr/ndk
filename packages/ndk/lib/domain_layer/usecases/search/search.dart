import '../../entities/filter.dart';
import '../../entities/metadata.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';
import '../requests/requests.dart';

class Search {
  final CacheManager _cacheManager;
  final Requests _requests;

  Search({
    required CacheManager cacheManager,
    required Requests requests,
  })  : _cacheManager = cacheManager,
        _requests = requests;

  /// Search for metadata \
  /// [query] can be pubkey, name, nip05
  Future<List<Metadata>> metadataSearch(String query, {int limit = 10}) async {
    final result = await _cacheManager.searchMetadatas(query, limit);
    return result.toList();
  }

  /// Search for events \
  /// [ids] list of event ids \
  /// [authors] list of authors \
  /// [kinds] list of kinds \
  /// [tags] map of tags \
  /// [since] timestamp since \
  /// [until] timestamp until \
  /// [search] search string \
  /// [limit] limit of results \
  /// [cacheOnly] if true only cache is used (a lot faster but no network fetch)
  Future<Iterable<Nip01Event>> searchEvents({
    final List<String>? ids,
    final List<String>? authors,
    final List<int>? kinds,
    final Map<String, List<String>>? tags,
    final int? since,
    final int? until,
    final String? search,
    final int limit = 100,

    /// cache only is much faster but does not fetch from the network
    final bool cacheOnly = false,
  }) async {
    final localEvents = _cacheManager.searchEvents(
      ids: ids,
      authors: authors,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
      limit: limit,
    );

    if (cacheOnly) {
      return localEvents;
    }

    final networkEvents = _requests.query(
      filters: [
        Filter(
          authors: authors,
          kinds: kinds,
          tags: tags,
          since: since,
          until: until,
          search: search,
          limit: limit,
        ),
      ],
    );

    final events = await Future.wait([localEvents, networkEvents.future]);

    final combined = events.expand((element) => element);

    final withoutDuplicates = combined.toSet().toList();
    return withoutDuplicates;
  }
}
