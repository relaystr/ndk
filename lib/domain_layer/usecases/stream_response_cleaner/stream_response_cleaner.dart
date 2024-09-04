import 'dart:async';
import 'dart:developer';

import '../../entities/nip_01_event.dart';

/// given a stream  with Nip01 events it tracks the id and adds the one to the provided stream controller
/// tracking of the happens in the tracking list
class StreamResponseCleaner {
  void call({
    required Set<String> trackingSet,
    required Stream<Nip01Event> inputStream,
    required StreamController<Nip01Event> outController,
  }) {
    inputStream.listen((event) {
      // check if event id is in the set
      if (trackingSet.contains(event.pubKey)) {
        return;
      }

      trackingSet.add(event.pubKey);
      outController.add(event);
    });
  }
}