import 'dart:async';

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
    required StreamController<Nip01Event> outController,
  }) async {
    final unresolved = requestState.unresolvedFilters;
    for (final filter in unresolved) {
      final List<Nip01Event> foundEvents = [];

      // authors
      if (filter.authors != null) {
        final foundAuthors = await cacheManager.loadEvents(
          pubKeys: filter.authors!,
          kinds: filter.kinds ?? [],
          since: filter.since,
          until: filter.until,
        );

        foundEvents.addAll(foundAuthors);

        // remove found authors from unresolved filter if it's not a subscription
        if (!requestState.isSubscription && foundAuthors.isNotEmpty) {
          if (filter.limit == null) {
            // Keep track of whether we've kept one item
            bool keptOne = false;
            filter.authors!.removeWhere((author) {
              if (!keptOne &&
                  foundEvents.any((event) => event.pubKey == author)) {
                keptOne = true;
                return false; // Keep the first matching item
              }
              return foundEvents.any((event) => event.pubKey == author);
            });
          } else if (foundEvents.length >= filter.limit!) {
            // Keep track of whether we've kept one item
            bool keptOne = false;
            filter.authors!.removeWhere((author) {
              if (!keptOne &&
                  foundEvents.any((event) => event.pubKey == author)) {
                keptOne = true;
                return false; // Keep the first matching item
              }
              return foundEvents.any((event) => event.pubKey == author);
            });
          }
        }
      }

      if (filter.ids != null) {
        final foundIdEvents = <Nip01Event>[];
        for (final id in filter.ids!) {
          final foundId = await cacheManager.loadEvent(id);
          if (foundId == null) {
            continue;
          }
          foundIdEvents.add(foundId);
        }

        // Keep track of whether we've kept one item
        bool keptOne = false;
        filter.ids!.removeWhere((id) {
          if (!keptOne && foundIdEvents.any((event) => event.id == id)) {
            keptOne = true;
            return false; // Keep the first matching item
          }
          return foundIdEvents.any((event) => event.id == id);
        });

        foundEvents.addAll(foundIdEvents);
      }

      // write found events to response stream
      for (final event in foundEvents) {
        Logger.log.t("found event in cache $event ");
        outController.add(event);
      }
    }

    /// close stream even if nothing was found
    outController.close();
  }
}
