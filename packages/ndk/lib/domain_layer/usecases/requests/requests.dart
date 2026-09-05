import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../config/request_defaults.dart';
import '../../../shared/helpers/bounded_lru_set.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/event_kind_classification.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/account.dart';
import '../../entities/event_filter.dart';
import '../../entities/filter.dart';
import '../../entities/global_state.dart';
import '../../entities/ndk_request.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/relay_auth.dart';
import '../../entities/relay_connectivity.dart';
import '../../entities/relay_set.dart';
import '../../entities/request_response.dart';
import '../../entities/request_state.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_verifier.dart';
import 'verified_event_cache.dart';
import '../cache_read/cache_read.dart';
import '../fetched_ranges/fetched_ranges.dart';
import '../engines/network_engine.dart';
import '../relay_manager.dart';
import '../stream_response_cleaner/stream_response_cleaner.dart';
import 'concurrency_check.dart';
import 'verify_event_stream.dart';

/// Internal state for tracking pagination progress on a single relay
class _RelayPaginationState {
  int? oldestTimestamp;
  int? currentUntil;
  bool exhausted = false;
}

/// A class that handles low-level Nostr network requests and subscriptions.
class Requests {
  static const int _persistedEventIdsMaxSize = 20000;

  final GlobalState _globalState;
  final CacheRead _cacheRead;
  final CacheManager _cacheManager;
  final NetworkEngine _engine;
  final RelayManager _relayManager;
  final EventVerifier _eventVerifier;
  final List<EventFilter> _eventOutFilters;
  final Duration _defaultQueryTimeout;
  FetchedRanges? _fetchedRanges;

  /// ids of events whose signature was already checked by this [Ndk]
  /// instance, so repeat delivery across relays/requests skips re-verifying
  final VerifiedEventMemCache _verifiedEventIds = VerifiedEventMemCache();

  /// Creates a new [Requests] instance
  ///
  /// [globalState] The global state of the application \
  /// [cacheRead] The cache reader for retrieving cached events \
  /// [cacheManager] The cache used to persist network-delivered events \
  /// [networkEngine] The engine for handling network requests \
  /// [eventVerifier] The verifier for validating Nostr events
  Requests({
    required GlobalState globalState,
    required CacheRead cacheRead,
    required CacheManager cacheManager,
    required NetworkEngine networkEngine,
    required RelayManager relayManager,
    required EventVerifier eventVerifier,
    required List<EventFilter> eventOutFilters,
    required Duration defaultQueryTimeout,
  })  : _engine = networkEngine,
        _relayManager = relayManager,
        _cacheManager = cacheManager,
        _cacheRead = cacheRead,
        _globalState = globalState,
        _eventVerifier = eventVerifier,
        _eventOutFilters = eventOutFilters,
        _defaultQueryTimeout = defaultQueryTimeout;

  /// Clears signature-verification reuse state owned by this NDK instance.
  void clearVerifiedEventCache() => _verifiedEventIds.clear();

  Stream<Nip01Event> _prepareNetworkStream(
    Stream<Nip01Event> verifiedNetworkStream, {
    required bool writeToCache,
  }) {
    if (!writeToCache) {
      return verifiedNetworkStream;
    }

    final persistedEventIds = BoundedLruSet<String>(
      maxSize: _persistedEventIdsMaxSize,
    );
    final persistenceInFlight = <String, Future<void>>{};

    return verifiedNetworkStream
        .flatMap(
          (event) => Stream.fromFuture(
            _persistAndFilterVisibleNetworkEvent(
              event,
              persistedEventIds: persistedEventIds,
              persistenceInFlight: persistenceInFlight,
            ),
          ),
        )
        .whereType<Nip01Event>()
        .shareReplay(maxSize: 1);
  }

  Future<Nip01Event?> _persistAndFilterVisibleNetworkEvent(
    Nip01Event event, {
    required BoundedLruSet<String> persistedEventIds,
    required Map<String, Future<void>> persistenceInFlight,
  }) async {
    // Ephemeral events (NIP-01 kinds 20000-29999) are non-persistent by
    // definition. They must not be written to cache — relays don't store them
    // either. Inbound events flow through to the subscriber but are not
    // persisted, preventing unbounded cache growth. Locally-created ephemeral
    // events (broadcast / pending-delivery) bypass this path and remain cached
    // for local-first delivery and retry.
    if (EventKindClassification.isEphemeralKind(event.kind)) {
      return event;
    }

    final existingPersistence = persistenceInFlight[event.id];
    if (existingPersistence != null) {
      await existingPersistence;
    } else if (persistedEventIds.add(event.id)) {
      final persistence = Future<void>.sync(
        () async {
          await _cacheManager.saveEventIfAbsent(event);
        },
      );
      persistenceInFlight[event.id] = persistence;
      try {
        await persistence;
      } catch (_) {
        persistedEventIds.remove(event.id);
        rethrow;
      } finally {
        if (identical(persistenceInFlight[event.id], persistence)) {
          persistenceInFlight.remove(event.id);
        }
      }
    }
    if (event.sources.isNotEmpty) {
      await _cacheManager.addEventSources(
        eventId: event.id,
        relayUrls: event.sources.toSet(),
      );
    }

    if (event.kind == 5) {
      return event;
    }

    final visible = await _cacheManager.loadEvents(ids: [event.id], limit: 1);

    return visible.any((candidate) => candidate.id == event.id) ? event : null;
  }

  /// Set the fetched ranges tracker for automatic range recording
  set fetchedRanges(FetchedRanges? fetchedRanges) =>
      _fetchedRanges = fetchedRanges;

  /// Performs a low-level Nostr query
  ///
  /// [filter] The filter to apply to the query \
  /// [filters] @deprecated A list of filters to apply to the query. Use [filter] instead \
  /// [name] An optional name used as an ID prefix \
  /// [relaySet] An optional set of relays to query \
  /// [cacheRead] Whether to read from cache \
  /// [cacheWrite] Whether to write results to cache \
  /// [timeout] An optional timeout in seconds for the query if not set ndk default will be used \
  /// [explicitRelays] A list of specific relays to use, bypassing inbox/outbox \
  /// [desiredCoverage] The number of relays per pubkey to query, default: 2 \
  /// [timeoutCallbackUserFacing] A user facing timeout callback, this callback should be given to the lib user \
  /// [timeoutCallback] An internal timeout callback, this callback should be used for internal error handling \
  /// [auth] which identity this query may be attributed to on relays (NIP-42), see [RelayAuth] \
  /// [authenticateAs] @deprecated use [auth] instead; [auth] wins when both are given \
  /// [paginate] If true, automatically paginates backwards through time to fetch all events in the range \
  ///
  /// Returns an [NdkResponse] containing the query result stream, future
  NdkResponse query({
    Filter? filter,
    @Deprecated(
      'Use filter instead. Multiple filters support will be removed in a future version.',
    )
    List<Filter>? filters,
    String name = '',
    RelaySet? relaySet,
    bool cacheRead = true,
    bool cacheWrite = true,
    Duration? timeout,
    Function()? timeoutCallbackUserFacing,
    Function()? timeoutCallback,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
    RelayAuth? auth,
    @Deprecated(
      'Use auth: RelayAuth.allow(account) instead. authenticateAs will be removed in a future version.',
    )
    List<Account>? authenticateAs,
    bool paginate = false,
  }) {
    if (filter == null && (filters == null || filters.isEmpty)) {
      throw ArgumentError('Either filter or filters must be provided');
    }
    final effectiveFilters = filter != null ? [filter] : filters!;
    final effectiveAuth =
        auth ?? RelayAuth.fromDeprecatedAccounts(authenticateAs);
    timeout ??= _defaultQueryTimeout;

    if (paginate) {
      return _paginatedQuery(
        filter: effectiveFilters.first,
        name: name,
        relaySet: relaySet,
        cacheRead: cacheRead,
        cacheWrite: cacheWrite,
        timeout: timeout,
        timeoutCallbackUserFacing: timeoutCallbackUserFacing,
        timeoutCallback: timeoutCallback,
        explicitRelays: explicitRelays,
        desiredCoverage: desiredCoverage,
        auth: effectiveAuth,
      );
    }

    return requestNostrEvent(
      NdkRequest.query(
        '$name-${Helpers.getRandomString(10)}',
        name: name,
        filters: effectiveFilters.map((e) => e.clone()).toList(),
        relaySet: relaySet,
        cacheRead: cacheRead,
        cacheWrite: cacheWrite,
        timeoutDuration: timeout,
        timeoutCallbackUserFacing: timeoutCallbackUserFacing,
        timeoutCallback: timeoutCallback,
        explicitRelays: explicitRelays,
        desiredCoverage:
            desiredCoverage ?? RequestDefaults.DEFAULT_BEST_RELAYS_MIN_COUNT,
        auth: effectiveAuth,
      ),
    );
  }

  /// Creates a low-level Nostr subscription
  ///
  /// [filter] The filter to apply to the subscription \
  /// [filters] @deprecated A list of filters to apply to the subscription. Use [filter] instead \
  /// [name] An optional name for the subscription \
  /// [id] An optional ID for the subscription, overriding name \
  /// [relaySet] An optional set of relays to subscribe to \
  /// [cacheRead] Whether to read from cache \
  /// [cacheWrite] Whether to write results to cache \
  /// [explicitRelays] A list of specific relays to use, bypassing inbox/outbox \
  /// [desiredCoverage] The number of relays per pubkey to subscribe to, default: 2 \
  /// [auth] which identity this subscription may be attributed to on relays (NIP-42), see [RelayAuth] \
  /// [authenticateAs] @deprecated use [auth] instead; [auth] wins when both are given \
  ///
  /// Returns an [NdkResponse] containing the subscription results as stream
  NdkResponse subscription({
    Filter? filter,
    @Deprecated(
      'Use filter instead. Multiple filters support will be removed in a future version.',
    )
    List<Filter>? filters,
    String name = '',
    String? id,
    RelaySet? relaySet,
    bool cacheRead = false,
    bool cacheWrite = false,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
    RelayAuth? auth,
    @Deprecated(
      'Use auth: RelayAuth.allow(account) instead. authenticateAs will be removed in a future version.',
    )
    List<Account>? authenticateAs,
  }) {
    if (filter == null && (filters == null || filters.isEmpty)) {
      throw ArgumentError('Either filter or filters must be provided');
    }
    final effectiveFilters = filter != null ? [filter] : filters!;
    final effectiveAuth =
        auth ?? RelayAuth.fromDeprecatedAccounts(authenticateAs);
    return requestNostrEvent(
      NdkRequest.subscription(
        id ?? "$name-${Helpers.getRandomString(10)}",
        name: name,
        filters: effectiveFilters.map((e) => e.clone()).toList(),
        relaySet: relaySet,
        cacheRead: cacheRead,
        cacheWrite: cacheWrite,
        explicitRelays: explicitRelays,
        desiredCoverage:
            desiredCoverage ?? RequestDefaults.DEFAULT_BEST_RELAYS_MIN_COUNT,
        auth: effectiveAuth,
      ),
    );
  }

  /// Closes a Nostr network subscription
  Future<void> closeSubscription(String subId, {String debugLabel = ""}) async {
    final state = _globalState.inFlightRequests[subId];

    if (state == null) {
      Logger.log.w(
        () =>
            "no relay urls found for subscription $subId, cannot close :: debug: $debugLabel",
      );
      return;
    }

    Iterable<RelayConnectivity> relays = _relayManager.connectedRelays
        .whereType<RelayConnectivity>()
        .where((relay) => state.requests.containsKey(relay.key));

    for (final relay in relays) {
      final request = state.requests[relay.key]!;
      // a request the relay ended itself, with a CLOSED or with the EOSE of a
      // query, is already closed on its side
      final endedOnRelay = request.receivedClosed ||
          (state.request.closeOnEOSE && request.receivedEOSE);
      if (endedOnRelay) {
        continue;
      }
      _relayManager.sendCloseToConnection(relay.key, subId);
    }

    await state.close();
    _globalState.inFlightRequests.remove(subId);
  }

  /// Close all subscriptions
  Future<void> closeAllSubscription() async {
    await Future.wait(
      _globalState.inFlightRequests.values.map(
        (state) => closeSubscription(state.id),
      ),
    );
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
      closeSubscription(state.id, debugLabel: "timeout");

      // call our internal timeout function
      request.timeoutCallback?.call();

      // call user defined timeout function
      request.timeoutCallbackUserFacing?.call();
    };

    // register event verification - removes invalid events from the stream
    final verifiedNetworkStream = VerifyEventStream(
      unverifiedStreamInput: state.networkController.stream,
      eventVerifier: _eventVerifier,
      verifiedEventCache: _verifiedEventIds,
    )();

    final preparedNetworkStream = _prepareNetworkStream(
      verifiedNetworkStream,
      writeToCache: request.cacheWrite,
    );

    // only the oldest timestamp per relay is needed, buffering the events
    // themselves would grow unbounded on long-lived subscriptions
    final oldestNetworkEventByRelay = <String, int>{};
    final trackedNetworkStream = _fetchedRanges == null
        ? preparedNetworkStream
        : preparedNetworkStream.map((event) {
            for (final source in event.sources) {
              final oldest = oldestNetworkEventByRelay[source];
              if (oldest == null || event.createdAt < oldest) {
                oldestNetworkEventByRelay[source] = event.createdAt;
              }
            }
            return event;
          });

    // register listener
    StreamResponseCleaner(
      inputStreams: [trackedNetworkStream, state.cacheController.stream],
      trackingSet: state.returnedIds,
      outController: state.controller,
      eventOutFilters: _eventOutFilters,
    )();

    // Record fetched ranges once the response stream is closed, meaning the
    // network stream has been fully drained. Closing on networkController.done
    // would run before verification finished pushing events downstream.
    state.controller.done.then((_) {
      _recordFetchedRanges(state, oldestNetworkEventByRelay);
    });

    // cleanup on close
    // use done future for replay subject
    state.controller.done.then((_) {
      _globalState.inFlightRequests.remove(state.id);
      Logger.log.d(() => "req done: ${state.id}");
    });

    /// avoids sending events to response stream before a listener could be attached
    Future<void> asyncStuff() async {
      /// concurrency check - check if request is inFlight
      final streamWasReplaced = request.cacheRead && concurrency.check(state);
      if (streamWasReplaced) {
        // Cancel timeout for duplicate - it will complete when original completes
        state.cancelTimeout();
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

      // a request that requires an identity nobody can sign for has no
      // connection to go out on, and its timeout would only delay the same
      // empty answer. The cache already had its say above
      final auth = state.request.auth;
      if (auth is RelayAuthRequire && !auth.account.signer.canSign()) {
        Logger.log.w(
          () =>
              "${state.id} requires ${auth.account.pubkey}, which cannot sign",
        );
        state.cancelTimeout();
        await state.networkController.close();
        return;
      }

      /// if there are any more filters left (not served by cacheRead)
      if (state.request.filters.isNotEmpty) {
        /// handle request
        _engine.handleRequest(state);
      } else {
        state.networkController.close();
      }
    }

    asyncStuff();

    // Return the response immediately
    return response;
  }

  /// Performs a paginated query that fetches all events in a time range
  /// by making multiple requests per relay, each time adjusting the `until` parameter
  /// to fetch older events until `since` is reached or no more events are returned.
  /// Pagination is done independently per relay to avoid skipping events.
  NdkResponse _paginatedQuery({
    required Filter filter,
    String name = '',
    RelaySet? relaySet,
    bool cacheRead = true,
    bool cacheWrite = true,
    Duration? timeout,
    Function()? timeoutCallbackUserFacing,
    Function()? timeoutCallback,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
    RelayAuth? auth,
  }) {
    final requestId = '$name-paginated-${Helpers.getRandomString(10)}';
    final aggregatedController = ReplaySubject<Nip01Event>();
    final seenEventIds = <String>{};

    Future<void> paginate() async {
      final since = filter.since;

      // First request to discover relays and get initial events
      final initialResponse = requestNostrEvent(
        NdkRequest.query(
          '$name-page-initial-${Helpers.getRandomString(5)}',
          name: name,
          filters: [filter.clone()],
          relaySet: relaySet,
          cacheRead: cacheRead,
          cacheWrite: cacheWrite,
          timeoutDuration: timeout,
          timeoutCallbackUserFacing: timeoutCallbackUserFacing,
          timeoutCallback: timeoutCallback,
          explicitRelays: explicitRelays,
          desiredCoverage:
              desiredCoverage ?? RequestDefaults.DEFAULT_BEST_RELAYS_MIN_COUNT,
          auth: auth,
        ),
      );

      final initialEvents = await initialResponse.future;

      // Emit initial events and discover relays
      final relayState = <String, _RelayPaginationState>{};

      for (final event in initialEvents) {
        if (!seenEventIds.contains(event.id)) {
          seenEventIds.add(event.id);
          aggregatedController.add(event);
        }

        // Track oldest timestamp per relay
        for (final relay in event.sources) {
          final state = relayState.putIfAbsent(
            relay,
            () => _RelayPaginationState(),
          );
          if (state.oldestTimestamp == null ||
              event.createdAt < state.oldestTimestamp!) {
            state.oldestTimestamp = event.createdAt;
          }
        }
      }

      // If no events or no relays discovered, we're done
      if (initialEvents.isEmpty || relayState.isEmpty) {
        await aggregatedController.close();
        return;
      }

      // Initialize relay states
      for (final entry in relayState.entries) {
        final state = entry.value;
        if (state.oldestTimestamp != null) {
          state.currentUntil = state.oldestTimestamp! - 1;
          // Check if already reached since
          if (since != null && state.oldestTimestamp! <= since) {
            state.exhausted = true;
          }
        } else {
          state.exhausted = true;
        }
      }

      // Paginate each relay independently
      while (relayState.values.any((s) => !s.exhausted)) {
        // Get active relays
        final activeRelays = relayState.entries
            .where((e) => !e.value.exhausted)
            .map((e) => e.key)
            .toList();

        // Make parallel requests to all active relays
        final futures = activeRelays.map((relay) async {
          final state = relayState[relay]!;
          final pageFilter = filter.clone();
          pageFilter.until = state.currentUntil;

          // no relaySet: it takes precedence over explicitRelays in the relay
          // sets engine, which would send this page to the whole set with the
          // `until` of a single relay
          final response = requestNostrEvent(
            NdkRequest.query(
              '$name-page-${Helpers.getRandomString(5)}',
              name: name,
              filters: [pageFilter],
              cacheRead: false, // Don't read from cache for subsequent pages
              cacheWrite: cacheWrite,
              timeoutDuration: timeout,
              timeoutCallbackUserFacing: timeoutCallbackUserFacing,
              timeoutCallback: timeoutCallback,
              explicitRelays: [relay],
              desiredCoverage: 1,
              auth: auth,
            ),
          );

          return MapEntry(relay, await response.future);
        });

        final results = await Future.wait(futures);

        // Process results
        for (final result in results) {
          final relay = result.key;
          final pageEvents = result.value;
          final state = relayState[relay]!;

          int? oldestTimestamp;
          for (final event in pageEvents) {
            if (!seenEventIds.contains(event.id)) {
              seenEventIds.add(event.id);
              aggregatedController.add(event);
            }
            // Track oldest timestamp for this relay
            if (oldestTimestamp == null || event.createdAt < oldestTimestamp) {
              oldestTimestamp = event.createdAt;
            }
          }

          if (pageEvents.isEmpty || oldestTimestamp == null) {
            state.exhausted = true;
          } else {
            state.currentUntil = oldestTimestamp - 1;
            // Check if reached since
            if (since != null && oldestTimestamp <= since) {
              state.exhausted = true;
            }
          }
        }
      }

      await aggregatedController.close();
    }

    // Start pagination asynchronously
    paginate();

    return NdkResponse(requestId, aggregatedController.stream);
  }

  /// Records fetched ranges for each relay that received EOSE
  /// - If events received: coverage starts at the oldest event received
  /// - If no events: use the filter bounds (0 to now when unbounded)
  ///
  /// [oldestEventByRelay] must only reflect events received from relays during
  /// this request. Cache hits would make the recorded range claim coverage the
  /// relay never actually served.
  void _recordFetchedRanges(
    RequestState state,
    Map<String, int> oldestEventByRelay,
  ) {
    if (_fetchedRanges == null) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final entry in state.requests.entries) {
      final relayUrl = entry.key.url;
      final relayState = entry.value;

      if (!relayState.receivedEOSE) continue;

      final oldestEvent = oldestEventByRelay[relayUrl];

      // Record fetched range for each filter sent to this relay
      for (final filter in relayState.filters) {
        int since = filter.since ?? 0;
        final int until = filter.until ?? now;

        if (oldestEvent != null) {
          // A relay can cap a response below the requested limit, or with no
          // limit in the filter at all (NIP-11 max_limit, which we don't read),
          // so a full response is indistinguishable from a truncated one. Only
          // claim coverage down to the oldest event received.
          since = oldestEvent;
        }

        _fetchedRanges!.addRange(
          filter: filter,
          relayUrl: relayUrl,
          since: since,
          until: until,
        );
      }
    }
  }
}
