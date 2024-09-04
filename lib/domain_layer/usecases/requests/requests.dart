import 'concurrency_check.dart';
import '../../entities/global_state.dart';
import '../../entities/ndk_request.dart';
import '../../entities/request_response.dart';
import '../../entities/filter.dart';
import '../../entities/relay_set.dart';
import '../../entities/request_state.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../cache_read/cache_read.dart';
import '../cache_write/cache_write.dart';
import '../jit_engine.dart';
import '../relay_sets_engine.dart';

class Requests {
  static const int DEFAULT_QUERY_TIMEOUT = 5;

  final GlobalState _globalState;
  final CacheRead _cacheRead;
  final CacheWrite _cacheWrite;
  final RelaySetsEngine? _requestManager;
  final JitEngine? _jitEngine;

  Requests({
    required GlobalState globalState,
    required CacheRead cacheRead,
    required CacheWrite cacheWrite,
    RelaySetsEngine? requestManager,
    JitEngine? jitEngine,
  })  : _jitEngine = jitEngine,
        _requestManager = requestManager,
        _cacheWrite = cacheWrite,
        _cacheRead = cacheRead,
        _globalState = globalState;

  /// low level nostr query
  /// [id] is automatically provided
  /// [explicitRelays] when specified only these relays are used. No inbox/outbox
  NdkResponse query({
    required List<Filter> filters,
    String idPrefix = '',
    RelaySet? relaySet,
    bool cacheRead = true,
    bool cacheWrite = true,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
  }) {
    return requestNostrEvent(NdkRequest.query(
      idPrefix + Helpers.getRandomString(10),
      filters: filters,
      relaySet: relaySet,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      explicitRelays: explicitRelays,
      desiredCoverage: desiredCoverage ?? 2,
    ));
  }

  /// low level nostr subscription
  /// [id] is automatically provided but can be changed
  /// [explicitRelays] when specified only these relays are used. No inbox/outbox
  NdkResponse subscription({
    required List<Filter> filters,
    String idPrefix = '',
    String? id,
    RelaySet? relaySet,
    bool cacheRead = false,
    bool cacheWrite = false,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
  }) {
    return requestNostrEvent(NdkRequest.subscription(
      "$idPrefix${id ?? Helpers.getRandomString(10)}",
      filters: filters,
      relaySet: relaySet,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      explicitRelays: explicitRelays,
      desiredCoverage: desiredCoverage ?? 2,
    ));
  }

  /// low level access to request events from the nostr network
  /// use only if you don't find a prebuilt use case and .query .subscription do not work for you
  NdkResponse requestNostrEvent(NdkRequest request) {
    RequestState state = RequestState(request);

    final response = NdkResponse(state.id, state.stream);

    final concurrency = ConcurrencyCheck(_globalState);

    /// avoids sending events to response stream before a listener could be attached
    Future<void> asyncStuff() async {
      //todo: duplication check per request

      /// cache new responses
      _cacheWrite.saveNetworkResponse(
        writeToCache: request.cacheWrite,
        inputStream: state.controller.stream,
      );

      /// concurrency check - check if request is inFlight
      final streamWasReplaced = request.cacheRead && concurrency.check(state);
      if (streamWasReplaced) {
        return;
      }

      // caching should write to response stream and keep track on what is unresolved to send the split filters to the engine
      if (request.cacheRead) {
        await _cacheRead.resolveUnresolvedFilters(requestState: state);
      }

      /// handle request
      if (_requestManager != null) {
        await _requestManager.handleRequest(state);
      } else if (_jitEngine != null) {
        _jitEngine.handleRequest(state);
      } else {
        throw UnimplementedError("Unknown engine");
      }
    }

    asyncStuff();

    // Return the response immediately
    return response;
  }
}
