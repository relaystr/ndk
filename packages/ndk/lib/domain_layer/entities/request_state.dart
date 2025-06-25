import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../config/rx_defaults.dart';
import 'filter.dart';
import 'ndk_request.dart';
import 'nip_01_event.dart';

/// Single relay request state
class RelayRequestState {
  String url;
  bool receivedEOSE = false;
  List<Filter> filters;

  /// default const
  RelayRequestState(this.url, this.filters);
}

/// State per request for multiple relays
class RequestState {
  ReplaySubject<Nip01Event> controller = ReplaySubject<Nip01Event>(
    maxSize: RX_REPLAYSUBJECT_MAX_EVENTS,
  );

  /// [networkController] used by engines to write their response
  StreamController<Nip01Event> networkController =
      StreamController<Nip01Event>();

  /// [cacheController] is the controller cacheRead writes to
  StreamController<Nip01Event> cacheController = StreamController<Nip01Event>();

  /// ids that got already returned by this request
  Set<String> returnedIds = {};

  Timer? _timeout;

  Stream<Nip01Event> get stream => controller.stream;

  /// request id
  String get id => request.id;

  /// is this a subscription?
  bool get isSubscription => !request.closeOnEOSE;

  ///! our requests tracking obj
  // key is relay url, value is RelayRequestState
  Map<String, RelayRequestState> requests = {};

  /// the original request
  NdkRequest request;

  /// this is the working filter obj, gets initialized with user provided filters.
  /// Then on each step (cache, network) resolved filters get removed/updated
  final List<Filter> unresolvedFilters;

  /// timeout duration, closes all streams
  Duration? timeoutDuration;

  /// called when timeout is triggered
  Function(RequestState)? onTimeout;

  late StreamSubscription<Nip01Event> _streamSubscription;

  /// Creates a new [RequestState] instance
  RequestState(this.request) : unresolvedFilters = request.filters {
    // if we have a timeout set, we start it
    if (request.timeoutDuration != null) {
      timeoutDuration = request.timeoutDuration;
      _timeout = Timer(timeoutDuration!, () {
        onTimeout?.call(this);
        // call close on all controllers
        close();
      });
    }
    _streamSubscription = controller.listen((e) {}, onDone: () {
      if (_timeout != null) {
        _timeout!.cancel();
      }
      _streamSubscription.cancel();
    });
  }

  /// checks if all requests received EOSE
  bool get didAllRequestsReceivedEOSE =>
      !requests.values.any((element) => !element.receivedEOSE);

  /// Adds single relay request to the state
  void addRequest(String url, List<Filter> filters) {
    if (!requests.containsKey(url)) {
      requests[url] = RelayRequestState(url, filters);
    }
  }

  /// closes all streams
  Future<void> close() async {
    if (_timeout != null) {
      _timeout!.cancel();
    }
    await networkController.close();
    await cacheController.close();
    await controller.close();
  }
}
