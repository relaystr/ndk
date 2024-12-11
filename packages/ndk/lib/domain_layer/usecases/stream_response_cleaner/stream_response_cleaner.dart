import 'dart:async';
import '../../../shared/logger/logger.dart';
import '../../entities/event_filter.dart';
import '../../entities/nip_01_event.dart';

/// given a stream  with Nip01 events it tracks the id and adds the one to the provided stream controller \
/// tracking of the happens in the tracking list
class StreamResponseCleaner {
  final Set<String> _trackingSet;
  final List<Stream<Nip01Event>> _inputStreams;
  final StreamController<Nip01Event> _outController;
  List<EventFilter> _eventOutFilters;

  int get _numStreams => _inputStreams.length;

  int _closedStreams = 0;

  /// -  [trackingSet] a set of ids that are already returned \
  /// - [inputStreams] a list of streams that are be listened to \
  /// - [outController] the controller that is used to add the events to \

  StreamResponseCleaner({
    required Set<String> trackingSet,
    required List<Stream<Nip01Event>> inputStreams,
    required StreamController<Nip01Event> outController,
    required List<EventFilter> eventOutFilters,
  })  : _trackingSet = trackingSet,
        _outController = outController,
        _inputStreams = inputStreams,
        _eventOutFilters = eventOutFilters {}

  void call() {
    for (final stream in _inputStreams) {
      _addStreamListener(stream);
    }
  }

  _addStreamListener(Stream<Nip01Event> stream) {
    stream.listen((event) {
      // check if event id is in the set
      if (_trackingSet.contains(event.id)) {
        return;
      }

      if (_outController.isClosed) {
        return;
      }

      _trackingSet.add(event.id);

      // check against filters
      for (final filter in _eventOutFilters) {
        if (!filter.filter(event)) {
          return;
        }
      }
      _outController.add(event);
      Logger.log.t("added event ${event.content}");
    }, onDone: () async {
      _canClose();
    }, onError: (error) {
      Logger.log.e("⛔ $error ");
    });
  }

  /// used to wait on all streams
  Future<void> _canClose() async {
    _closedStreams++;
    if (_closedStreams >= _numStreams) {
      await _outController.close();
    }
  }
}
