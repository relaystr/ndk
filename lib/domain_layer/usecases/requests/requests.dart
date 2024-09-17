import 'dart:async';

import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/filter.dart';
import '../../entities/global_state.dart';
import '../../entities/ndk_request.dart';
import '../../entities/relay_set.dart';
import '../../entities/request_response.dart';
import '../../entities/request_state.dart';
import '../../repositories/event_verifier.dart';
import '../cache_read/cache_read.dart';
import '../cache_write/cache_write.dart';
import '../engines/network_engine.dart';
import '../stream_response_cleaner/stream_response_cleaner.dart';
import 'concurrency_check.dart';
import 'verify_event_stream.dart';

class Requests {
  static const int DEFAULT_QUERY_TIMEOUT = 5;

  final GlobalState _globalState;
  final CacheRead _cacheRead;
  final CacheWrite _cacheWrite;
  final NetworkEngine _engine;
  final EventVerifier _eventVerifier;

  Requests({
    required GlobalState globalState,
    required CacheRead cacheRead,
    required CacheWrite cacheWrite,
    required NetworkEngine networkEngine,
    required EventVerifier eventVerifier,
  })  : _engine = networkEngine,
        _cacheWrite = cacheWrite,
        _cacheRead = cacheRead,
        _globalState = globalState,
        _eventVerifier = eventVerifier;

  /// low level nostr query
  /// [id] is automatically provided
  /// [name] is used as id prefix => name-randomString
  /// [explicitRelays] when specified only these relays are used. No inbox/outbox
  /// [cacheRead] if the cache should be used to retrieve results
  /// [cacheWrite] if the query results schuld be written to cache
  /// [desiredCoverage] determines how many relays per pubkey are queried
  NdkResponse query({
    required List<Filter> filters,
    String name = '',
    RelaySet? relaySet,
    bool cacheRead = true,
    bool cacheWrite = true,
    int? timeout,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
  }) {
    return requestNostrEvent(NdkRequest.query(
      '$name-${Helpers.getRandomString(10)}',
      name: name,
      filters: filters,
      relaySet: relaySet,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      timeout: timeout,
      explicitRelays: explicitRelays,
      desiredCoverage: desiredCoverage ?? 2,
    ));
  }

  /// low level nostr subscription
  /// [id] is automatically provided but can be changed
  /// [explicitRelays] when specified only these relays are used. No inbox/outbox
  NdkResponse subscription({
    required List<Filter> filters,
    String name = '',
    String? id,
    RelaySet? relaySet,
    bool cacheRead = false,
    bool cacheWrite = false,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
  }) {
    return requestNostrEvent(NdkRequest.subscription(
      "$name-${id ?? Helpers.getRandomString(10)}",
      name: name,
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

    // register event verification - removes invalid events from the stream
    final verifiedNetworkStream = VerifyEventStream(
      unverifiedStreamInput: state.networkController.stream,
      eventVerifier: _eventVerifier,
    )();

    /// register cache new responses
    _cacheWrite.saveNetworkResponse(
      writeToCache: request.cacheWrite,
      inputStream: verifiedNetworkStream,
    );

    // register listener
    StreamResponseCleaner(
      inputStreams: [
        verifiedNetworkStream,
        state.cacheController.stream,
      ],
      trackingSet: state.returnedIds,
      outController: state.controller,
    )();

    /// avoids sending events to response stream before a listener could be attached
    Future<void> asyncStuff() async {
      /// concurrency check - check if request is inFlight
      final streamWasReplaced = request.cacheRead && concurrency.check(state);
      if (streamWasReplaced) {
        return;
      }

      // caching should write to response stream and keep track on what is unresolved to send the split filters to the engine
      if (request.cacheRead) {
        await _cacheRead.resolveUnresolvedFilters(
          requestState: state,
          outController: state.cacheController,
        );
      }

      /// handle request
      _engine.handleRequest(state);
    }

    asyncStuff();

    // Return the response immediately
    return response;
  }
}
