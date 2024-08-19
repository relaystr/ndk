import '../domain_layer/entities/filter.dart';
import '../domain_layer/repositories/event_signer.dart';
import '../domain_layer/repositories/event_verifier.dart';
import '../shared/nips/nip01/helpers.dart';
import 'concurrency_check.dart';
import 'global_state.dart';
import 'init.dart';
import 'ndk_config.dart';
import 'ndk_request.dart';
import 'request_response.dart';
import '../domain_layer/entities/request_state.dart';

// some global obj that schuld be kept in memory by lib user
class Ndk {
  // placeholder
  final NdkConfig ndkConfig;
  static final GlobalState globalState = GlobalState();

  // global initialization use to access rdy repositories
  final Initialization _initialization;

  Ndk(this.ndkConfig)
      : _initialization = Initialization(
          ndkConfig: ndkConfig,
          globalState: globalState,
        );

  RequestResponse query({required List<Filter> filters}) {
    return requestNostrEvent(NdkRequest.query(Helpers.getRandomString(10), filters: filters));
  }

  subscription({required List<Filter> filters, String? id}) {
    return requestNostrEvent(NdkRequest.subscription(id ?? Helpers.getRandomString(10), filters: filters));
  }

  /// ! this is just an example
  RequestResponse requestNostrEvent(NdkRequest request) {
    RequestState requestState = RequestState(request);

    final response = RequestResponse(requestState.stream);

    final concurrency = ConcurrencyCheck(globalState);

    /// concurrency check - check if request is inFlight
    final streamWasReplaced = concurrency.check(requestState);
    if (streamWasReplaced) {
      return response;
    }

    // todo caching middleware
    // caching should write to response stream and keep track on what is unresolved to send the split filters to the engine
    _initialization.cacheRead
        .resolveUnresolvedFilters(requestState: requestState);

    /// handle request)

    switch (ndkConfig.engine) {
      case NdkEngine.LISTS:
        //todo: discuss/implement use of unresolvedFilters
        _initialization.relayManager!.handleRequest(requestState);
        break;

      case NdkEngine.JIT:
        _initialization.jitEngine!.handleRequest(requestState);
        break;

      default:
        throw UnimplementedError("Unknown engine");
    }

    /// cache network response
    // todo: discuss use of networkController.add() in engines, its something to keep in mind and therefore bad
    _initialization.cacheWrite.saveNetworkResponse(
      networkController: requestState.networkController,
      responseController: requestState.controller,
    );

    return response;
  }

  /// ! this is just an example
  /// event is event to publish
  /// broadcast config (could be optional) defines relays to broadcast to
  Future<dynamic> broadcastEvent(dynamic event, dynamic broadcastConfig) {
    // calls uncase with config
    throw UnimplementedError();
  }

  /// hot swap EventVerifier
  changeEventVerifier(EventVerifier newEventVerifier) {
    ndkConfig.eventVerifier = newEventVerifier;
  }

  /// hot swap EventSigner
  changeEventSigner(EventSigner newEventSigner) {
    ndkConfig.eventSigner = newEventSigner;
  }
}
