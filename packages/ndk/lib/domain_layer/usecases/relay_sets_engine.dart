// ignore_for_file: avoid_print

import 'dart:core';
import 'dart:math';

import '../../config/bootstrap_relays.dart';
import '../../config/broadcast_defaults.dart';
import '../../shared/logger/logger.dart';
import '../../shared/nips/nip01/client_msg.dart';
import '../../shared/nips/nip01/helpers.dart';
import '../entities/broadcast_response.dart';
import '../entities/broadcast_state.dart';
import '../entities/connection_source.dart';
import '../entities/filter.dart';
import '../entities/global_state.dart';
import '../entities/ndk_request.dart';
import '../entities/nip_01_event.dart';
import '../entities/relay_connectivity.dart';
import '../entities/relay_set.dart';
import '../entities/request_response.dart';
import '../entities/request_state.dart';
import '../repositories/cache_manager.dart';
import '../repositories/event_signer.dart';
import 'engines/network_engine.dart';
import 'relay_manager.dart';
import 'user_relay_lists/user_relay_lists.dart';

class RelaySetsEngine implements NetworkEngine {
  static const Duration DEFAULT_STREAM_IDLE_TIMEOUT = Duration(seconds: 5);

  late GlobalState _globalState;

  final RelayManager _relayManager;

  final CacheManager _cacheManager;

  final List<String> _bootstrapRelays;

  /// engine that pre-calculates relay sets for gossip
  RelaySetsEngine({
    required RelayManager relayManager,
    required CacheManager cacheManager,
    required List<String>? bootstrapRelays,
    GlobalState? globalState,
  })  : _cacheManager = cacheManager,
        _relayManager = relayManager,
        _bootstrapRelays = bootstrapRelays ?? DEFAULT_BOOTSTRAP_RELAYS {
    _globalState = globalState ?? GlobalState();
  }

  // ====================================================================================================================

  bool doRelayRequest(String id, RelayRequestState request) {
    if (_relayManager.isRelayConnected(request.url) &&
        (!_globalState.blockedRelays.contains(request.url))) {
      try {
        RelayConnectivity? relay = _globalState.relays[request.url];
        if (relay != null) {
          relay.stats.activeRequests++;
          _relayManager.send(
              relay,
              ClientMsg(
                ClientMsgType.REQ,
                id: id,
                filters: request.filters,
              ));
        }
        return true;
      } catch (e) {
        print(e);
      }
    } else {
      print(
          "COULD NOT SEND REQUEST TO ${request.url} since socket seems to be not open");
      RelayConnectivity? relay = _globalState.relays[request.url];
      if (relay != null) {
        _relayManager.reconnectRelay(relay.url,
            connectionSource: relay.relay.connectionSource);
      }
    }
    return false;
  }

  // =====================================================================================

  Future<void> doNostrRequestWithRelaySet(RequestState state,
      {bool splitRequestsByPubKeyMappings = true}) async {
    if (state.unresolvedFilters.isEmpty || state.request.relaySet == null) {
      return;
    }
    // TODO support more than 1 filter
    RelaySet relaySet = state.request.relaySet!;
    Filter filter = state.unresolvedFilters.first;
    if (splitRequestsByPubKeyMappings) {
      relaySet.splitIntoRequests(filter, state);
      print(
          "request for ${filter.authors != null ? filter.authors!.length : 0} authors with kinds: ${filter.kinds} made requests to ${state.requests.length} relays");

      if (state.requests.isEmpty && relaySet.fallbackToBootstrapRelays) {
        print(
            "making fallback requests to ${_bootstrapRelays.length} bootstrap relays for ${filter.authors != null ? filter.authors!.length : 0} authors with kinds: ${filter.kinds}");
        for (final url in _bootstrapRelays) {
          state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
        }
      }
    } else {
      for (final url in relaySet.urls) {
        state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
      }
    }
    _globalState.inFlightRequests[state.id] = state;
    for (MapEntry<String, RelayRequestState> entry in state.requests.entries) {
      doRelayRequest(state.id, entry.value);
    }
  }

  Future<NdkResponse> query(
    Filter filter,
    RelaySet? relaySet, {
    required String name,
    Duration idleTimeout = RelaySetsEngine.DEFAULT_STREAM_IDLE_TIMEOUT,
    bool splitRequestsByPubKeyMappings = true,
  }) async {
    RequestState state = RequestState(NdkRequest.query(
        timeoutDuration: idleTimeout,
        Helpers.getRandomString(10),
        name: name,
        filters: [filter],
        relaySet: relaySet));
    await _doQuery(state);
    return NdkResponse(state.id, state.stream);
  }

  Future<void> _doQuery(RequestState state) async {
    handleRequest(state);
    state.networkController.stream.listen((event) {
      state.controller.add(event);
    }, onDone: () {
      state.controller.close();
    }, onError: (error) {
      Logger.log.e("⛔ $error ");
    });
  }

  @override
  Future<void> handleRequest(RequestState state) async {
    await _relayManager.seedRelaysConnected;

    if (state.request.relaySet != null) {
      return await doNostrRequestWithRelaySet(state);
    }
    if (state.request.explicitRelays != null &&
        state.request.explicitRelays!.isNotEmpty) {
      for (final url in state.request.explicitRelays!) {
        await _relayManager.connectRelay(
            dirtyUrl: url, connectionSource: ConnectionSource.EXPLICIT);
        state.addRequest(
            url, RelaySet.sliceFilterAuthors(state.request.filters.first));
      }
    } else {
      for (final url in _bootstrapRelays) {
        state.addRequest(
            url, RelaySet.sliceFilterAuthors(state.request.filters.first));
      }
    }
    _globalState.inFlightRequests[state.id] = state;

    List<String> notSent = [];
    for (MapEntry<String, RelayRequestState> entry in state.requests.entries) {
      if (!doRelayRequest(state.id, entry.value)) {
        notSent.add(entry.key);
      }
    }
    for (var url in notSent) {
      state.requests.remove(url);
    }
  }

  Future<NdkResponse> requestRelays(
    String name,
    Iterable<String> urls,
    Filter filter, {
    Duration timeout = DEFAULT_STREAM_IDLE_TIMEOUT,
    bool closeOnEOSE = true,
  }) async {
    String id = Helpers.getRandomString(10);
    RequestState state = RequestState(closeOnEOSE
        ? NdkRequest.query(
            id,
            name: name,
            filters: [filter],
            timeoutDuration: timeout,
          )
        : NdkRequest.subscription(
            id,
            name: name,
            filters: [],
          ));

    for (var url in urls) {
      state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
    }
    _globalState.inFlightRequests[state.id] = state;

    List<String> notSent = [];
    for (MapEntry<String, RelayRequestState> entry in state.requests.entries) {
      if (!doRelayRequest(state.id, entry.value)) {
        notSent.add(entry.key);
      }
    }
    for (var url in notSent) {
      state.requests.remove(url);
    }

    return NdkResponse(state.id, state.stream);
  }

  @override
  NdkBroadcastResponse handleEventBroadcast({
    required Nip01Event nostrEvent,
    required EventSigner? signer,
    required Stream<List<RelayBroadcastResponse>> doneStream,
    Iterable<String>? specificRelays,
  }) {
    Future<void> asyncStuff() async {
      // =====================================================================================
      // specific relays
      // =====================================================================================
      if (signer != null) {
        await signer.sign(nostrEvent);
      }

      if (specificRelays != null) {
        // check connectivity
        for (final relayUrl in specificRelays) {
          if (_relayManager.isRelayConnected(relayUrl)) {
            continue;
          }
          await _relayManager.connectRelay(
              dirtyUrl: relayUrl,
              connectionSource: ConnectionSource.BROADCAST_SPECIFIC);
        }
        // send out request
        for (final relayUrl in specificRelays) {
          _relayManager.registerRelayBroadcast(
            eventToPublish: nostrEvent,
            relayUrl: relayUrl,
          );

          final relayConnectivity =
              _relayManager.getRelayConnectivity(relayUrl);
          if (relayConnectivity != null) {
            _relayManager.send(
                relayConnectivity,
                ClientMsg(
                  ClientMsgType.EVENT,
                  event: nostrEvent,
                ));
          }
        }
        return;
      }
      // =====================================================================================
      // own outbox
      // =====================================================================================
      final nip65Data = (await UserRelayLists.getUserRelayListCacheLatest(
        pubkeys: [nostrEvent.pubKey],
        cacheManager: _cacheManager,
      ))
          .first;
      final writeRelaysUrls = nip65Data.relays.entries
          .where((element) => element.value.isWrite)
          .map((e) => e.key)
          .toList();

      for (final relayUrl in writeRelaysUrls) {
        final isConnected =
            _globalState.relays[relayUrl]?.relayTransport?.isOpen() ?? false;
        if (isConnected) {
          continue;
        }

        await _relayManager.connectRelay(
          dirtyUrl: relayUrl,
          connectionSource: ConnectionSource.BROADCAST_OWN,
        );
      }

      for (final relayUrl in writeRelaysUrls) {
        final relay = _globalState.relays[relayUrl];
        if (relay == null) {
          Logger.log.w("relay $relayUrl not found");
          continue;
        }

        _relayManager.registerRelayBroadcast(
          eventToPublish: nostrEvent,
          relayUrl: relayUrl,
        );

        _relayManager.send(
            relay,
            ClientMsg(
              ClientMsgType.EVENT,
              event: nostrEvent,
            ));
      }

      // =====================================================================================
      // other inbox
      // =====================================================================================
      if (nostrEvent.pTags.isNotEmpty) {
        final nip65Data = await UserRelayLists.getUserRelayListCacheLatest(
          pubkeys: nostrEvent.pTags,
          cacheManager: _cacheManager,
        );

        List<String> myWriteRelayUrlsOthers = [];

        /// filter read relays
        for (final userNip65 in nip65Data) {
          final completeList = userNip65.relays.entries
              .where((element) => element.value.isRead)
              .map((e) => e.key)
              .toList();

          // cut list of at a certain threshold
          final maxList = completeList.sublist(
            0,
            min(completeList.length,
                BroadcastDefaults.MAX_INBOX_RELAYS_TO_BROADCAST),
          );
          myWriteRelayUrlsOthers.addAll(maxList);
        }

        for (final relayUrl in myWriteRelayUrlsOthers) {
          final isConnected =
              _globalState.relays[relayUrl]?.relayTransport?.isOpen() ?? false;
          if (isConnected) {
            continue;
          }
          await _relayManager.connectRelay(
              dirtyUrl: relayUrl,
              connectionSource: ConnectionSource.BROADCAST_OTHER);
        }
        for (final relayUrl in myWriteRelayUrlsOthers) {
          final relay = _globalState.relays[relayUrl];

          if (relay == null) {
            Logger.log.w("relay $relayUrl not found");
            continue;
          }

          _relayManager.registerRelayBroadcast(
            eventToPublish: nostrEvent,
            relayUrl: relayUrl,
          );

          _relayManager.send(
              relay,
              ClientMsg(
                ClientMsgType.EVENT,
                event: nostrEvent,
              ));
        }
      }
    }

    asyncStuff();

    return NdkBroadcastResponse(
      publishEvent: nostrEvent,
      broadcastDoneStream: doneStream,
    );
  }
}
