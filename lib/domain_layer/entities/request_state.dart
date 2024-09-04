import 'dart:async';

import 'filter.dart';
import 'nip_01_event.dart';
import '../usecases/relay_jit_manager/relay_jit.dart';
import 'ndk_request.dart';

class RelayRequestState {
  String url;
  bool receivedEOSE = false;
  List<Filter> filters;
  List<String> eventIdsToBeVerified = [];

  RelayRequestState(this.url, this.filters);
}

class RequestState {
  StreamController<Nip01Event> controller =
      StreamController<Nip01Event>.broadcast();

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

  get isSubscription => !request.closeOnEOSE;

  //! our requests tracking obj
  Map<String, RelayRequestState> requests = {};

  // string is the relay url
  // TODO this class should not hold anything JIT specific
  Map<String, RelayJit> activeRelaySubscriptions = {};

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
