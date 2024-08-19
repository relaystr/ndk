import 'dart:async';

import 'filter.dart';
import 'nip_01_event.dart';
import '../usecases/relay_jit_manager/relay_jit.dart';
import '../../presentation_layer/ndk_request.dart';

class RelayRequestState {
  String url;
  bool receivedEOSE = false;
  List<Filter> filters;
  List<String> eventIdsToBeVerified = [];

  RelayRequestState(this.url, this.filters);
}

class RequestState {
  StreamController<Nip01Event> controller =
      StreamController<Nip01Event>();

  /// [networkController] used by engines to write their response
  StreamController<Nip01Event> networkController =
      StreamController<Nip01Event>.broadcast();

  Stream<Nip01Event> get stream => request.timeout != null
      ? controller.stream.timeout(Duration(seconds: request.timeout!),
          onTimeout: (sink) {
          if (request.onTimeout != null) {
            request.onTimeout!.call(this);
          }
        })
      : controller.stream;

  get id => request.id;

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
