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
    final unresolved = requestState.unresolvedFilters.toSet();
    for (final filter in unresolved) {
      final List<Nip01Event> foundEvents = [];

      // authors
      if (filter.authors != null) {
        final cached = await cacheManager.loadEvents(
          pubKeys: filter.authors!,
          kinds: filter.kinds ?? [],
          since: filter.since,
          until: filter.until,
        );

        foundEvents.addAll(cached);
        // TODO Move this to a Github issue
        // WE CANNOT DO THIS, BECAUSE 1) kinds.length > 1,  2) only replaceable events have 1 event per pubKey+kind, normal events can have many per pubKey+kind
        // if kind.length == 1 and kind IS replaceable AND there is not limit/until/since AND it is NOT a subscription, then we can do some shit
        //
        //   // remove found authors from unresolved filter if it's not a subscription
        //   if (!requestState.isSubscription && cached.isNotEmpty) {
        //     if (filter.limit == null) {
        //       // Keep track of whether we've kept one item
        //       bool keptOne = false;
        //       filter.authors!.removeWhere((author) {
        //         if (!keptOne &&
        //             foundEvents.any((event) => event.pubKey == author)) {
        //           keptOne = true;
        //           return false; // Keep the first matching item
        //         }
        //         return foundEvents.any((event) => event.pubKey == author);
        //       });
        //     } else if (foundEvents.length >= filter.limit!) {
        //       // Keep track of whether we've kept one item
        //       bool keptOne = false;
        //       filter.authors!.removeWhere((author) {
        //         if (!keptOne &&
        //             foundEvents.any((event) => event.pubKey == author)) {
        //           keptOne = true;
        //           return false; // Keep the first matching item
        //         }
        //         return foundEvents.any((event) => event.pubKey == author);
        //       });
        //     }
        //   }
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

        filter.ids!.removeWhere((id) {
          return foundIdEvents.any((event) => event.id == id);
        });

        foundEvents.addAll(foundIdEvents);
        if (filter.ids!.isEmpty) {
          // if we have not more ids in filter, remove the filter entirely,
          // otherwise it will send too broad filter to relay
          requestState.unresolvedFilters.remove(filter);
        }
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
