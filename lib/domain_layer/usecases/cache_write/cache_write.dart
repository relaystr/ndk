import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';

/// class to handle writes to cache/db with business logic
class CacheWrite {
  final CacheManager cacheManager;

  CacheWrite(this.cacheManager);

  /// saves network responses in db and then write to response stream if not already in db (useful to avoid duplicates)
  /// [networkController] input controller,
  /// [responseController] output controller, where the result is written to
  saveNetworkResponse({
    required bool writeToCache,
    required StreamController<Nip01Event> networkController,
    required StreamController<Nip01Event> responseController,
  }) {
    networkController.stream.listen((event) {
      final foundElement = cacheManager.loadEvent(event.id);
      if (foundElement != null) {
        // already in db
        // todo: allow cache manager structure to save metadata about event, relay rcv from
        return;
      }
      Logger.log.d("⛁ got event from network $event ");

      if (writeToCache) {
        //todo: currently working on
        //cacheManager.saveEvent(event);
      }

      responseController.add(event);
    }, onDone: () {
      responseController.close();
    }, onError: (error) {
      Logger.log.e("⛔ $error ");
    });
  }
}
