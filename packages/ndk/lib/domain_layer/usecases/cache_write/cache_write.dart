import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../shared/isolates/isolate_manager_io.dart';
import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';

/// class to handle writes to cache/db with business logic
class CacheWrite {
  final CacheManager cacheManager;
  final Duration writeBufferDuration;

  CacheWrite(
    this.cacheManager, {
    this.writeBufferDuration = const Duration(seconds: 5),
  });

  /// saves network responses in db and then write to response stream if not already in db (useful to avoid duplicates)
  void saveNetworkResponse({
    required bool writeToCache,
    required Stream<Nip01Event> inputStream,
  }) {
    inputStream
        .doOnData((event) {
          Logger.log.t(() => "⛁ got event from network $event ");
        })
        .bufferTime(writeBufferDuration)
        .where((events) => writeToCache && events.isNotEmpty)
        .listen(
          (events) {
            Logger.log.t(() =>
                "CacheWrite - 💾 Saving batch of ${events.length} events");
            cacheManager.saveEvents(events);
          },
          onDone: () {
            Logger.log.t(() => "CacheWrite - ✓ Stream completed");
          },
          onError: (error) {
            Logger.log.e(() => "CacheWrite - ⛔ $error ");
          },
        );
  }
}
