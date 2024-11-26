import 'dart:async';

import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';

/// class to handle writes to cache/db with business logic
class CacheWrite {
  final CacheManager cacheManager;

  CacheWrite(this.cacheManager);

  /// saves network responses in db and then write to response stream if not already in db (useful to avoid duplicates)
  void saveNetworkResponse({
    required bool writeToCache,
    required Stream<Nip01Event> inputStream,
  }) {
    inputStream.listen((event) async {
      Logger.log.t("⛁ got event from network $event ");

      if (writeToCache) {
        await cacheManager.saveEvent(event);
      }
    }, onDone: () {
      //? cannot be implemented as stack insert when the stream closes, because it would screw up subscriptions.
    }, onError: (error) {
      Logger.log.e("⛔ $error ");
    });
  }
}
