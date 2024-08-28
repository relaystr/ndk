import 'concurrency_check.dart';
import '../../entities/global_state.dart';
import '../../entities/ndk_request.dart';
import '../../entities/request_response.dart';
import '../../entities/filter.dart';
import '../../entities/relay_set.dart';
import '../../entities/request_state.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../cache_read/cache_read.dart';
import '../cache_write/cache_write.dart';
import '../jit_engine.dart';
import '../relay_sets_engine.dart';

class Requests {
  static const int DEFAULT_QUERY_TIMEOUT = 5;

  GlobalState globalState;
  CacheRead cacheRead;
  CacheWrite cacheWrite;
  RelaySetsEngine? requestManager;
  JitEngine? jitEngine;

  Requests({
    required this.globalState,
    required this.cacheRead,
    required this.cacheWrite,
    this.requestManager,
    this.jitEngine,
  });

  NdkResponse query(
      {required List<Filter> filters,
      RelaySet? relaySet,
      bool cacheRead = true,
      bool cacheWrite = true,
      relays}) {
    return requestNostrEvent(NdkRequest.query(Helpers.getRandomString(10),
        filters: filters,
        relaySet: relaySet,
        cacheRead: cacheRead,
        cacheWrite: cacheWrite,
        relays: relays));
  }

  NdkResponse subscription(
      {required List<Filter> filters,
      String? id,
      RelaySet? relaySet,
      bool cacheRead = true,
      bool cacheWrite = true,
      relays}) {
    return requestNostrEvent(NdkRequest.subscription(
        id ?? Helpers.getRandomString(10),
        filters: filters,
        relaySet: relaySet,
        cacheRead: cacheRead,
        cacheWrite: cacheWrite,
        relays: relays));
  }

  NdkResponse requestNostrEvent(NdkRequest request) {
    RequestState state = RequestState(request);

    final response = NdkResponse(state.id, state.stream);

    final concurrency = ConcurrencyCheck(globalState);

    /// concurrency check - check if request is inFlight
    // final streamWasReplaced = request.cacheRead && concurrency.check(state);
    // if (streamWasReplaced) {
    //   return response;
    // }

    // todo caching middleware
    // caching should write to response stream and keep track on what is unresolved to send the split filters to the engine
    if (request.cacheRead) {
      cacheRead.resolveUnresolvedFilters(requestState: state);
    }

    /// handle request)

    if (requestManager != null) {
      requestManager!.handleRequest(state);
    } else if (jitEngine != null) {
      jitEngine!.handleRequest(state);
    } else {
      throw UnimplementedError("Unknown engine");
    }

    /// cache network response
    // todo: discuss use of networkController.add() in engines, its something to keep in mind and therefore bad
    if (request.cacheWrite) {
      cacheWrite.saveNetworkResponse(
        networkController: state.networkController,
        responseController: state.controller,
      );
    } else {
      state.networkController.stream.listen((event) {
        state.controller.add(event);
      }, onDone: () {
        state.controller.close();
      }, onError: (error) {
        Logger.log.e("⛔ $error ");
      });
    }

    return response;
  }
}
