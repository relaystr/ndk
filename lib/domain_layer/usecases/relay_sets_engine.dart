// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:core';

import '../../data_layer/repositories/cache_manager/mem_cache_manager.dart';
import '../../shared/logger/logger.dart';
import '../../shared/nips/nip01/helpers.dart';
import '../entities/filter.dart';
import '../entities/global_state.dart';
import '../entities/ndk_request.dart';
import '../entities/relay.dart';
import '../entities/relay_set.dart';
import '../entities/request_response.dart';
import '../entities/request_state.dart';
import '../repositories/cache_manager.dart';
import 'engines/network_engine.dart';
import 'relay_manager.dart';

class RelaySetsEngine implements NetworkEngine {
  static const int DEFAULT_STREAM_IDLE_TIMEOUT = 5;

  late GlobalState globalState;

  RelayManager relayManager;
  late CacheManager cacheManager;

  RelaySetsEngine({
    required this.relayManager,
    CacheManager? cacheManager,
    GlobalState? globalState,
  }) {
    this.cacheManager = cacheManager ?? MemCacheManager();
    this.globalState = globalState ?? GlobalState();
    relayManager.connect(urls: relayManager.bootstrapRelays);
  }

  // ====================================================================================================================

  bool doRelayRequest(String id, RelayRequestState request) {
    if (relayManager.isWebSocketOpen(request.url) &&
        (!relayManager.blockedRelays.contains(request.url))) {
      try {
        List<dynamic> list = ["REQ", id];
        list.addAll(request.filters.map((filter) => filter.toMap()));
        Relay? relay = relayManager.getRelay(request.url);
        if (relay != null) {
          relay.stats.activeRequests++;
          relayManager.send(request.url, jsonEncode(list));
        }
        return true;
      } catch (e) {
        print(e);
      }
    } else {
      print(
          "COULD NOT SEND REQUEST TO ${request.url} since socket seems to be not open");

      relayManager.reconnectRelay(request.url);
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
            "making fallback requests to ${relayManager.bootstrapRelays.length} bootstrap relays for ${filter.authors != null ? filter.authors!.length : 0} authors with kinds: ${filter.kinds}");
        for (var url in relayManager.bootstrapRelays) {
          state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
        }
      }
    } else {
      for (var url in relaySet.urls) {
        state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
      }
    }
    globalState.inFlightRequests[state.id] = state;
    Map<int?, int> kindsMap = {};
    globalState.inFlightRequests.forEach((key, request) {
      int? kind;
      if (request.requests.isNotEmpty &&
          request.requests.values.first.filters.first.kinds != null &&
          request.requests.values.first.filters.first.kinds!.isNotEmpty) {
        kind = request.requests.values.first.filters.first.kinds!.first;
      }
      int? count = kindsMap[kind];
      count ??= 0;
      count++;
      kindsMap[kind] = count;
    });
    print(
        "----------------NOSTR REQUESTS: ${globalState.inFlightRequests.length} || $kindsMap");
    for (MapEntry<String, RelayRequestState> entry in state.requests.entries) {
      doRelayRequest(state.id, entry.value);
    }
  }

  Future<NdkResponse> query(
    Filter filter,
    RelaySet? relaySet, {
    int idleTimeout = RelaySetsEngine.DEFAULT_STREAM_IDLE_TIMEOUT,
    bool splitRequestsByPubKeyMappings = true,
  }) async {
    RequestState state = RequestState(NdkRequest.query(
        Helpers.getRandomString(10),
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
    await relayManager.seedRelaysConnected;

    if (state.request.relaySet != null) {
      return await doNostrRequestWithRelaySet(state);
    }
    if (state.request.explicitRelays != null &&
        state.request.explicitRelays!.isNotEmpty) {
      for (var url in state.request.explicitRelays!) {
        state.addRequest(
            url, RelaySet.sliceFilterAuthors(state.request.filters.first));
      }
    } else {
      for (var url in relayManager.relays.keys) {
        state.addRequest(
            url, RelaySet.sliceFilterAuthors(state.request.filters.first));
      }
    }
    globalState.inFlightRequests[state.id] = state;

    /**********************************************************/
    Map<int?, int> kindsMap = {};
    globalState.inFlightRequests.forEach((key, request) {
      int? kind;
      if (request.requests.isNotEmpty &&
          request.requests.values.first.filters.first.kinds != null &&
          request.requests.values.first.filters.first.kinds!.isNotEmpty) {
        kind = request.requests.values.first.filters.first.kinds!.first;
      }
      int? count = kindsMap[kind];
      count ??= 0;
      count++;
      kindsMap[kind] = count;
    });
    print(
        "----------------NOSTR REQUESTS: ${globalState.inFlightRequests.length} || $kindsMap");
    /**********************************************************/

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

  Future<NdkResponse> requestRelays(Iterable<String> urls, Filter filter,
      {int timeout = DEFAULT_STREAM_IDLE_TIMEOUT,
      bool closeOnEOSE = true,
      Function()? onTimeout}) async {
    String id = Helpers.getRandomString(10);
    RequestState state = RequestState(closeOnEOSE
        ? NdkRequest.query(id, filters: [filter])
        : NdkRequest.subscription(
            id,
            filters: [],
          ));

    for (var url in urls) {
      state.addRequest(url, RelaySet.sliceFilterAuthors(filter));
    }
    globalState.inFlightRequests[state.id] = state;

    List<String> notSent = [];
    Map<int?, int> kindsMap = {};
    globalState.inFlightRequests.forEach((key, request) {
      int? kind;
      if (request.requests.isNotEmpty &&
          request.requests.values.first.filters.first.kinds != null &&
          request.requests.values.first.filters.first.kinds!.isNotEmpty) {
        kind = request.requests.values.first.filters.first.kinds!.first;
      }
      int? count = kindsMap[kind];
      count ??= 0;
      count++;
      kindsMap[kind] = count;
    });
    print(
        "----------------NOSTR REQUESTS: ${globalState.inFlightRequests.length} || $kindsMap");
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
}
