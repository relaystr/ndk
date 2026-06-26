import 'dart:async';

import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';

/// Writes network-delivered events into the cache.
///
/// Network responses enter the same generic event store used by event reads,
/// replaceable convergence, deletion suppression, and convenience projections.
class CacheWrite {
  final CacheManager cacheManager;

  CacheWrite(this.cacheManager);

  /// Persists network responses when [writeToCache] is enabled.
  void saveNetworkResponse({
    required bool writeToCache,
    required Stream<Nip01Event> inputStream,
  }) {
    inputStream.listen((event) async {
      Logger.log.t(() => "⛁ got event from network $event ");

      if (writeToCache) {
        await cacheManager.saveEvent(event);
      }
    }, onDone: () {
      //? cannot be implemented as stack insert when the stream closes, because it would screw up subscriptions.
    }, onError: (error) {
      Logger.log.e(() => "⛔ $error ");
    });
  }
}
