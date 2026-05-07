import 'dart:async';
import '../../../shared/logger/logger.dart';
import '../../entities/event_filter.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';

/// given a stream  with Nip01 events it tracks the id and adds the one to the provided stream controller \
/// tracking of the happens in the tracking list
class StreamResponseCleaner {
  final Map<String, Set<String>> _trackingMap; // event_id -> set of sources
  final List<Stream<Nip01Event>> _inputStreams;
  final StreamController<Nip01Event> _outController;
  final List<EventFilter> _eventOutFilters;
  final CacheManager? _cacheManager;

  int get _numStreams => _inputStreams.length;

  int _closedStreams = 0;

  /// -  [trackingSet] a set of ids that are already returned \
  /// - [inputStreams] a list of streams that are be listened to \
  /// - [outController] the controller that is used to add the events to \
  /// - [cacheManager] optional cache manager to persist event sources \

  StreamResponseCleaner({
    required Set<String> trackingSet,
    required List<Stream<Nip01Event>> inputStreams,
    required StreamController<Nip01Event> outController,
    required List<EventFilter> eventOutFilters,
    CacheManager? cacheManager,
  })  : _trackingMap = {for (final id in trackingSet) id: {}},
        _outController = outController,
        _inputStreams = inputStreams,
        _eventOutFilters = eventOutFilters,
        _cacheManager = cacheManager;

  void call() {
    for (final stream in _inputStreams) {
      _addStreamListener(stream);
    }
  }

  void _addStreamListener(Stream<Nip01Event> stream) {
    stream.listen((event) {
      if (_outController.isClosed) {
        return;
      }

      // check if event id is already seen
      final existingSources = _trackingMap[event.id];
      if (existingSources != null) {
        // Event already seen - merge sources if this event has new sources
        if (event.sources.isNotEmpty) {
          final newSources = Set<String>.from(existingSources)..addAll(event.sources);
          // Only emit if we have new sources to add
          if (newSources.length > existingSources.length) {
            _trackingMap[event.id] = newSources;
            final mergedEvent = event.copyWith(sources: newSources.toList());
            _outController.add(mergedEvent);
            // Update cache with merged sources
            _updateCacheSources(event.id, newSources);
          }
        }
        return;
      }

      // First time seeing this event
      _trackingMap[event.id] = event.sources.toSet();

      // check against filters
      for (final filter in _eventOutFilters) {
        if (!filter.filter(event)) {
          return;
        }
      }
      _outController.add(event);
      Logger.log.t(() => "added event ${event.content}");
    }, onDone: () async {
      _canClose();
    }, onError: (error) {
      Logger.log.e(() => "⛔ $error ");
    });
  }

  /// Updates the cache with merged sources for an event
  void _updateCacheSources(String eventId, Set<String> sources) {
    if (_cacheManager == null) return;
    
    // Load existing event from cache and update sources
    _cacheManager.loadEvent(eventId).then((cachedEvent) {
      if (cachedEvent != null) {
        final updatedEvent = cachedEvent.copyWith(sources: sources.toList());
        _cacheManager.saveEvent(updatedEvent);
      }
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
