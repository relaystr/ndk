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
  static const Duration kDefaultStreamIdleTimeout = Duration(seconds: 5);

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

  Future<bool> doRelayRequest(String id, RelayRequestState request) async {
    if (_globalState.blockedRelays.contains(request.url)) {
      Logger.log
          .w("COULD NOT SEND REQUEST TO ${request.url} since relay is blocked");
      return false;
    }

    final connected = await _relayManager.reconnectRelay(request.url,
        connectionSource:
            ConnectionSource.explicit // TODO improve this connection source
        );
    if (connected) {
      RelayConnectivity? relay = _globalState.relays[request.url];
      if (relay != null) {
        relay.stats.activeRequests++;
        try {
          _relayManager.send(
              relay,
              ClientMsg(
                ClientMsgType.kReq,
                id: id,
                filters: request.filters,
              ));
        } catch (e) {
          Logger.log.e("COULD NOT SEND REQUEST TO ${request.url}:", error: e);
          return false;
        }
      }
      return true;
    } else {
      Logger.log.e(
          "COULD NOT SEND REQUEST TO ${request.url} since socket seems to be not open");
      return false;
    }
  }

  // =====================================================================================

  Future<void> doNostrRequestWithRelaySet(RequestState state,
      {bool splitRequestsByPubKeyMappings = true}) async {
    if (state.unresolvedFilters.isEmpty || state.request.relaySet == null) {
      return;
    }
    RelaySet relaySet = state.request.relaySet!;
    for (final filter in state.unresolvedFilters) {
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
    }
    _globalState.inFlightRequests[state.id] = state;
    for (MapEntry<String, RelayRequestState> entry in state.requests.entries) {
      doRelayRequest(state.id, entry.value);
    }
  }

  @override
  Future<void> handleRequest(RequestState state) async {
    await _relayManager.seedRelaysConnected;

    if (state.request.relaySet != null) {
      return await doNostrRequestWithRelaySet(state);
    }
    Iterable<String>? relaysForRequest;

    if (state.request.explicitRelays != null &&
        state.request.explicitRelays!.isNotEmpty) {
      // for (final url in state.request.explicitRelays!) {
      //   await _relayManager.connectRelay(
      //       dirtyUrl: url, connectionSource: ConnectionSource.explicit);
      // }
      relaysForRequest = state.request.explicitRelays;
    } else {
      relaysForRequest = _bootstrapRelays;
    }
    for (final url in relaysForRequest!) {
      if (state.request.filters.isEmpty) {
        throw Exception("cannot do request with empty filters");
      }
      final List<Filter> filters = [];
      for (final filter in state.request.filters) {
        filters.addAll(RelaySet.sliceFilterAuthors(filter));
      }
      state.addRequest(url, filters);
    }
    _globalState.inFlightRequests[state.id] = state;

    for (MapEntry<String, RelayRequestState> entry in state.requests.entries) {
      doRelayRequest(state.id, entry.value).then((sent) {
        if (!sent) {
          state.requests.remove(entry.value.url);
        }
      });
    }
  }

  Future<NdkResponse> requestRelays(
    String name,
    Iterable<String> urls,
    Filter filter, {
    Duration timeout = kDefaultStreamIdleTimeout,
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

    for (MapEntry<String, RelayRequestState> entry in state.requests.entries) {
      doRelayRequest(state.id, entry.value).then((sent) {
        if (!sent) {
          state.requests.remove(entry.value.url);
        }
      });
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
              connectionSource: ConnectionSource.broadcastSpecific);
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
                  ClientMsgType.kEvent,
                  event: nostrEvent,
                ));
          }
        }
        return;
      }
      // =====================================================================================
      // own outbox
      // =====================================================================================
      // TODO should not only depend on cached, but go fetch it if not present in cache
      final nip65List = (await UserRelayLists.getUserRelayListCacheLatest(
        pubkeys: [nostrEvent.pubKey],
        cacheManager: _cacheManager,
      ));
      var writeRelaysUrls = _relayManager.globalState.relays.keys;
      if (nip65List.isNotEmpty) {
        writeRelaysUrls = nip65List.first.relays.entries
            .where((element) => element.value.isWrite)
            .map((e) => e.key)
            .toList();
      } else {
        Logger.log.w(
            "could not find user relay list from nip65, using default bootstrap relays");
      }

      for (final relayUrl in writeRelaysUrls) {
        final isConnected =
            _globalState.relays[relayUrl]?.relayTransport?.isOpen() ?? false;
        if (isConnected) {
          continue;
        }

        await _relayManager.connectRelay(
          dirtyUrl: relayUrl,
          connectionSource: ConnectionSource.broadcastOwn,
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
              ClientMsgType.kEvent,
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
              connectionSource: ConnectionSource.broadcastOther);
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
                ClientMsgType.kEvent,
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
