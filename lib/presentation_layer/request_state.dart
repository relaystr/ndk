import 'dart:async';

import '../domain_layer/entities/filter.dart';
import '../domain_layer/entities/nip_01_event.dart';
import '../domain_layer/usecases/relay_jit_manager/relay_jit.dart';
import 'ndk_request.dart';

class RelayRequestState {
  String url;
  bool receivedEOSE = false;
  List<Filter> filters;

  RelayRequestState(this.url, this.filters);
}

class RequestState {
  StreamController<Nip01Event> controller =
      StreamController<Nip01Event>.broadcast();

  Stream<Nip01Event> get stream => requestConfig.timeout != null
      ? controller.stream.timeout(Duration(seconds: requestConfig.timeout!),
      onTimeout: (sink) {
        if (requestConfig.onTimeout != null) {
          requestConfig.onTimeout!.call(this);
        }
      })
      : controller.stream;

  NdkRequest requestConfig;

  get id => requestConfig.id;

  //! our requests tracking obj
  Map<String, RelayRequestState> requests = {};

  // string is the relay url
  // TODO this class should not hold anything JIT specific
  Map<String, RelayJit> activeRelaySubscriptions = {};

  RequestState(this.requestConfig);

  bool get didAllRequestsReceivedEOSE =>
      !requests.values.any((element) => !element.receivedEOSE);

  bool get shouldClose =>
      requestConfig.closeOnEOSE && (requests.isEmpty || didAllRequestsReceivedEOSE);

  void addRequest(String url, List<Filter> filters) {
    if (!requests.containsKey(url)) {
      requests[url] = RelayRequestState(url, filters);
    }
  }
}
