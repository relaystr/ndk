import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../config/rx_defaults.dart';
import 'filter.dart';
import 'ndk_request.dart';
import 'nip_01_event.dart';

class RelayRequestState {
  String url;
  bool receivedEOSE = false;
  List<Filter> filters;

  RelayRequestState(this.url, this.filters);
}

class RequestState {
  ReplaySubject<Nip01Event> controller = ReplaySubject<Nip01Event>(
    maxSize: RX_REPLAYSUBJECT_MAX_EVENTS,
  );

  /// [networkController] used by engines to write their response
  StreamController<Nip01Event> networkController =
      StreamController<Nip01Event>();

  /// [cacheController] is the controller cacheRead writes to
  StreamController<Nip01Event> cacheController = StreamController<Nip01Event>();

  // ids that got already returned by this request
  Set<String> returnedIds = {};

  Stream<Nip01Event> get stream => request.timeout != null
      ? controller.stream.timeout(Duration(seconds: request.timeout!),
          onTimeout: (sink) {
          if (request.onTimeout != null) {
            request.onTimeout!.call(this);
          }
        })
      : controller.stream;

  String get id => request.id;

  bool get isSubscription => !request.closeOnEOSE;

  //! our requests tracking obj
  // key is relay url, value is RelayRequestState
  Map<String, RelayRequestState> requests = {};

  NdkRequest request;

  /// this is the working filter obj, gets initialized with user provided filters.
  /// Then on each step (cache, network) resolved filters get removed/updated
  final List<Filter> unresolvedFilters;

  RequestState(this.request) : unresolvedFilters = request.filters;

  bool get didAllRequestsReceivedEOSE =>
      !requests.values.any((element) => !element.receivedEOSE);

  bool get shouldClose =>
      request.closeOnEOSE && (requests.isEmpty || didAllRequestsReceivedEOSE);

  void addRequest(String url, List<Filter> filters) {
    if (!requests.containsKey(url)) {
      requests[url] = RelayRequestState(url, filters);
    }
  }
}
