// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:core';

import 'package:ndk/domain_layer/entities/broadcast_response.dart';

import '../../config/broadcast_defaults.dart';
import '../../shared/logger/logger.dart';
import '../../shared/nips/nip01/helpers.dart';
import '../entities/filter.dart';
import '../entities/global_state.dart';
import '../entities/ndk_request.dart';
import '../entities/nip_01_event.dart';
import '../entities/relay.dart';
import '../entities/relay_set.dart';
import '../entities/request_response.dart';
import '../entities/request_state.dart';
import '../repositories/cache_manager.dart';
import '../repositories/event_signer.dart';
import 'engines/network_engine.dart';
import 'inbox_outbox/get_nip_65_data.dart';
import 'relay_manager.dart';

class RelaySetsEngine implements NetworkEngine {
  static const int DEFAULT_STREAM_IDLE_TIMEOUT = 5;

  late GlobalState _globalState;

  final RelayManager _relayManager;

  final EventSigner? _signer;

  final CacheManager _cacheManager;

  /// engine that pre-calculates relay sets for gossip
  RelaySetsEngine({
    required RelayManager relayManager,
    required CacheManager cacheManager,
    EventSigner? signer,
    GlobalState? globalState,
  })  : _cacheManager = cacheManager,
        _signer = signer,
        _relayManager = relayManager {
    _globalState = globalState ?? GlobalState();
    _relayManager.connect(urls: _relayManager.bootstrapRelays);
  }

  // ====================================================================================================================

  bool doRelayRequest(String id, RelayRequestState request) {
    if (_relayManager.isWebSocketOpen(request.url) &&
        (!_relayManager.blockedRelays.contains(request.url))) {
      try {
        List<dynamic> list = ["REQ", id];
        list.addAll(request.filters.map((filter) => filter.toMap()));
        Relay? relay = _relayManager.getRelay(request.url);
        if (relay != null) {
          relay.stats.activeRequests++;
          _relayManager.send(request.url, jsonEncode(list));
        }
        return true;
      } catch (e) {
        print(e);
      }
    } else {
      print(
          "COULD NOT SEND REQUEST TO ${request.url} since socket seems to be not open");

      _relayManager.reconnectRelay(request.url);
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
            "making fallback requests to ${_relayManager.bootstrapRelays.length} bootstrap relays for ${filter.authors != null ? filter.authors!.length : 0} authors with kinds: ${filter.kinds}");
        for (var url in _relayManager.bootstrapRelays) {
          state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
        }
      }
    } else {
      for (var url in relaySet.urls) {
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
    int idleTimeout = RelaySetsEngine.DEFAULT_STREAM_IDLE_TIMEOUT,
    bool splitRequestsByPubKeyMappings = true,
  }) async {
    RequestState state = RequestState(NdkRequest.query(
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
    state.request.onTimeout = (state) {
      Logger.log.w(
          "request ${state.request.id} : ${state.request.filters} timed out after ${state.request.timeout}");
      for (var url in state.requests.keys) {
        _relayManager.sendCloseToRelay(url, state.id);
      }
      _relayManager.removeInFlightRequestById(state.id);
    };

    if (state.request.relaySet != null) {
      return await doNostrRequestWithRelaySet(state);
    }
    if (state.request.explicitRelays != null &&
        state.request.explicitRelays!.isNotEmpty) {
      for (var url in state.request.explicitRelays!) {
        await _relayManager.reconnectRelay(url);
        state.addRequest(
            url, RelaySet.sliceFilterAuthors(state.request.filters.first));
      }
    } else {
      for (var url in _relayManager.bootstrapRelays) {
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
      String name, Iterable<String> urls, Filter filter,
      {int timeout = DEFAULT_STREAM_IDLE_TIMEOUT,
      bool closeOnEOSE = true,
      Function()? onTimeout}) async {
    String id = Helpers.getRandomString(10);
    RequestState state = RequestState(closeOnEOSE
        ? NdkRequest.query(id, name: name, filters: [filter])
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
    required String privateKey,
    List<String>? specificRelays,
  }) {
    if (_signer == null) {
      throw "Cannot broadcast event without a signer";
    }

    Future<void> asyncStuff() async {
      // =====================================================================================
      // specific relays
      // =====================================================================================

      if (specificRelays != null) {
        for (final relayUrl in specificRelays) {
          final isConnected = _relayManager.isRelayConnected(relayUrl);
          if (isConnected) {
            continue;
          }
          await _relayManager.connectRelay(relayUrl);
        }
        _relayManager.broadcastEvent(
          nostrEvent,
          specificRelays,
          _signer,
        );
      }
      // =====================================================================================
      // own outbox
      // =====================================================================================
      final nip65Data = getNip65DataSingle(nostrEvent.pubKey, _cacheManager);
      final writeRelaysUrls = nip65Data.relays.entries
          .where((element) => element.value.isWrite)
          .map((e) => e.key)
          .toList();

      for (final relayUrl in writeRelaysUrls) {
        final isConnected = _relayManager.isRelayConnected(relayUrl);
        if (isConnected) {
          continue;
        }
        await _relayManager.connectRelay(relayUrl);
      }

      _relayManager.broadcastEvent(nostrEvent, writeRelaysUrls, _signer);

      // =====================================================================================
      // other inbox
      // =====================================================================================
      if (nostrEvent.pTags.isNotEmpty) {
        final nip65Data = getNip65Data(nostrEvent.pTags, _cacheManager);

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
            BroadcastDefaults.MAX_INBOX_RELAYS_TO_BROADCAST,
          );
          myWriteRelayUrlsOthers.addAll(maxList);
        }

        for (final relayUrl in myWriteRelayUrlsOthers) {
          final isConnected = _relayManager.isRelayConnected(relayUrl);
          if (isConnected) {
            continue;
          }
          await _relayManager.connectRelay(relayUrl);
        }
        _relayManager.broadcastEvent(
            nostrEvent, myWriteRelayUrlsOthers, _signer);
      }
    }

    asyncStuff();

    return NdkBroadcastResponse(publishedEvent: nostrEvent);
  }
}
