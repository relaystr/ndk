import 'dart:async';
import '../../../shared/logger/logger.dart';
import '../../entities/nip_01_event.dart';

/// given a stream  with Nip01 events it tracks the id and adds the one to the provided stream controller
/// tracking of the happens in the tracking list
class StreamResponseCleaner {
  final Set<String> trackingSet;
  final List<Stream<Nip01Event>> inputStreams;
  final StreamController<Nip01Event> outController;

  int get numStreams => inputStreams.length;

  int closedStreams = 0;

  StreamResponseCleaner({
    required this.trackingSet,
    required this.inputStreams,
    required this.outController,
  });

  void call() {
    for (final stream in inputStreams) {
      addStreamListener(stream);
    }
  }

  addStreamListener(Stream<Nip01Event> stream) {
    stream.listen((event) {
      // check if event id is in the set
      if (trackingSet.contains(event.id)) {
        return;
      }

      trackingSet.add(event.id);
      outController.add(event);
      Logger.log.t("added event ${event.content}");
    }, onDone: () async {
      _canClose();
    }, onError: (error) {
      Logger.log.e("⛔ $error ");
    });
  }

  /// used to wait on all streams
  Future<void> _canClose() async {
    closedStreams++;
    if (closedStreams >= numStreams) {
      await outController.close();
    }
  }
}
