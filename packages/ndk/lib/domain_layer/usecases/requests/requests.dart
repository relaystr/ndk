import 'dart:async';

import 'package:ndk/domain_layer/usecases/relay_manager.dart';

import '../../../config/request_defaults.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/event_filter.dart';
import '../../entities/filter.dart';
import '../../entities/global_state.dart';
import '../../entities/ndk_request.dart';
import '../../entities/relay_connectivity.dart';
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

/// A class that handles low-level Nostr network requests and subscriptions.
class Requests {
  final GlobalState _globalState;
  final CacheRead _cacheRead;
  final CacheWrite _cacheWrite;
  final NetworkEngine _engine;
  final RelayManager _relayManager;
  final EventVerifier _eventVerifier;
  final List<EventFilter> _eventOutFilters;
  final Duration _defaultQueryTimeout;

  /// Creates a new [Requests] instance
  ///
  /// [globalState] The global state of the application \
  /// [cacheRead] The cache reader for retrieving cached events \
  /// [cacheWrite] The cache writer for storing events \
  /// [networkEngine] The engine for handling network requests \
  /// [eventVerifier] The verifier for validating Nostr events
  Requests({
    required GlobalState globalState,
    required CacheRead cacheRead,
    required CacheWrite cacheWrite,
    required NetworkEngine networkEngine,
    required RelayManager relayManager,
    required EventVerifier eventVerifier,
    required List<EventFilter> eventOutFilters,
    required Duration defaultQueryTimeout,
  })  : _engine = networkEngine,
        _relayManager = relayManager,
        _cacheWrite = cacheWrite,
        _cacheRead = cacheRead,
        _globalState = globalState,
        _eventVerifier = eventVerifier,
        _eventOutFilters = eventOutFilters,
        _defaultQueryTimeout = defaultQueryTimeout;

  /// Performs a low-level Nostr query
  ///
  /// [filters] A list of filters to apply to the query \
  /// [name] An optional name used as an ID prefix \
  /// [relaySet] An optional set of relays to query \
  /// [cacheRead] Whether to read from cache \
  /// [cacheWrite] Whether to write results to cache \
  /// [timeout] An optional timeout in seconds for the query if not set ndk default will be used \
  /// [explicitRelays] A list of specific relays to use, bypassing inbox/outbox \
  /// [desiredCoverage] The number of relays per pubkey to query, default: 2 \
  /// [timeoutCallbackUserFacing] A user facing timeout callback, this callback should be given to the lib user \
  /// [timeoutCallback] An internal timeout callback, this callback should be used for internal error handling \
  ///
  /// Returns an [NdkResponse] containing the query result stream, future
  NdkResponse query({
    required List<Filter> filters,
    String name = '',
    RelaySet? relaySet,
    bool cacheRead = true,
    bool cacheWrite = true,
    Duration? timeout,
    Function()? timeoutCallbackUserFacing,
    Function()? timeoutCallback,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
  }) {
    if (timeout == null) {
      timeout = _defaultQueryTimeout;
    }

    return requestNostrEvent(NdkRequest.query(
      '$name-${Helpers.getRandomString(10)}',
      name: name,
      filters: filters.map((e) => e.clone()).toList(),
      relaySet: relaySet,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      timeoutDuration: timeout,
      timeoutCallbackUserFacing: timeoutCallbackUserFacing,
      timeoutCallback: timeoutCallback,
      explicitRelays: explicitRelays,
      desiredCoverage:
          desiredCoverage ?? RequestDefaults.DEFAULT_BEST_RELAYS_MIN_COUNT,
    ));
  }

  /// Creates a low-level Nostr subscription
  ///
  /// [filters] A list of filters to apply to the subscription \
  /// [name] An optional name for the subscription \
  /// [id] An optional ID for the subscription, overriding name \
  /// [relaySet] An optional set of relays to subscribe to \
  /// [cacheRead] Whether to read from cache \
  /// [cacheWrite] Whether to write results to cache \
  /// [explicitRelays] A list of specific relays to use, bypassing inbox/outbox \
  /// [desiredCoverage] The number of relays per pubkey to subscribe to, default: 2 \
  ///
  /// Returns an [NdkResponse] containing the subscription results as stream
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
      id ?? "$name-${Helpers.getRandomString(10)}",
      name: name,
      filters: filters.map((e) => e.clone()).toList(),
      relaySet: relaySet,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      explicitRelays: explicitRelays,
      desiredCoverage:
          desiredCoverage ?? RequestDefaults.DEFAULT_BEST_RELAYS_MIN_COUNT,
    ));
  }

  /// Closes a Nostr network subscription
  Future<void> closeSubscription(String subId) async {
    final relayUrls = _globalState.inFlightRequests[subId]?.requests.keys;
    if (relayUrls == null) {
      Logger.log.w("no relay urls found for subscription $subId, cannot close");
      return;
    }
    Iterable<RelayConnectivity> relays = _relayManager.connectedRelays
        .whereType<RelayConnectivity>()
        .where((relay) => relayUrls.contains(relay.url));

    for (final relay in relays) {
      this._relayManager.sendCloseToRelay(relay.url, subId);
    }
    // remove from in flight requests
    await _relayManager.removeInFlightRequestById(subId);
  }

  /// Close all subscriptions
  Future<void> closeAllSubscription() async {
    await Future.wait(_globalState.inFlightRequests.values.map((state) => closeSubscription(state.id)));
  }


  /// Performs a low-level Nostr event request
  ///
  /// This method should be used only if the prebuilt use cases and
  /// [query] or [subscription] methods do not meet your needs
  ///
  /// [request] The [NdkRequest] object containing request parameters
  ///
  /// Returns an [NdkResponse] containing the request results
  NdkResponse requestNostrEvent(NdkRequest request) {
    final state = RequestState(request);

    final response = NdkResponse(state.id, state.stream);

    final concurrency = ConcurrencyCheck(_globalState);

    // define on timeout behavior
    state.onTimeout = (RequestState state) {
      // closing in case relay is alive but not sending events
      closeSubscription(state.id);

      // call our internal timeout function
      request.timeoutCallback?.call();

      // call user defined timeout function
      request.timeoutCallbackUserFacing?.call();
    };

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
      eventOutFilters: _eventOutFilters,
    )();

    /// avoids sending events to response stream before a listener could be attached
    Future<void> asyncStuff() async {
      /// concurrency check - check if request is inFlight
      final streamWasReplaced = request.cacheRead && concurrency.check(state);
      if (streamWasReplaced) {
        return;
      } else {
        // add to in flight
        _globalState.inFlightRequests[state.id] = state;
      }

      // caching should write to response stream and keep track on what is unresolved to send the split filters to the engine
      if (request.cacheRead) {
        await _cacheRead.resolveUnresolvedFilters(
          requestState: state,
          outController: state.cacheController,
        );
      } else {
        /// close cache controller if not used
        state.cacheController.close();
      }

      /// handle request
      _engine.handleRequest(state);
    }

    asyncStuff();

    // Return the response immediately
    return response;
  }

}
