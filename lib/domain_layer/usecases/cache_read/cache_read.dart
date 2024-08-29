import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/request_state.dart';
import '../../repositories/cache_manager.dart';

class CacheRead {
  final CacheManager cacheManager;

  CacheRead(this.cacheManager);

  /// find matching events in cache return them and remove/update unresolved filters
  Future<void> resolveUnresolvedFilters({
    required RequestState requestState,
  }) async {
    final unresolved = requestState.unresolvedFilters;
    for (final filter in unresolved) {
      final List<Nip01Event> foundEvents = [];

      // authors
      if (filter.authors != null) {
        final foundAuthors = cacheManager.loadEvents(
          pubKeys: filter.authors!,
          kinds: filter.kinds ?? [],
        );
        foundEvents.addAll(foundAuthors);

        // remove found authors from unresolved filter if it's not a subscription
        if (!requestState.isSubscription) {
          filter.authors!.removeWhere(
            (author) => foundEvents.any((event) => event.pubKey == author),
          );
        }
      }

      // write found events to response stream
      for (final event in foundEvents) {
        Logger.log.d("☑ found event in cache $event ");
        requestState.controller.add(event);
      }
    }
  }
}
