// ignore_for_file: avoid_print

import 'dart:core';
import 'dart:math';

import '../../config/broadcast_defaults.dart';

import 'package:ndk_core/shared/logger/logger.dart';
import 'package:ndk_core/shared/nips/nip01/event_kind_classification.dart';
import 'package:ndk_core/shared/nips/nip01/helpers.dart';
import 'package:ndk_core/domain_layer/entities/broadcast_state.dart';
import 'package:ndk_core/domain_layer/entities/filter.dart';
import 'package:ndk_core/domain_layer/entities/ndk_request.dart';
import 'package:ndk_core/domain_layer/entities/nip_01_event.dart';
import 'package:ndk_core/domain_layer/entities/relay_set.dart';

import '../entities/request_response.dart';

import 'package:ndk_core/domain_layer/entities/request_state.dart';

import '../repositories/stores/event_store.dart';
import '../repositories/stores/user_relay_list_store.dart';

import 'package:ndk_core/domain_layer/usecases/engines/explicit_relays_engine.dart';

import 'user_relay_lists/user_relay_lists.dart';

class RelaySetsEngine extends ExplicitRelaysEngine {
  static const Duration kDefaultStreamIdleTimeout = Duration(seconds: 5);

  final EventStore _eventStore;
  final UserRelayListStore _userRelayListStore;

  /// engine that pre-calculates relay sets for gossip
  RelaySetsEngine({
    required super.relayManager,
    required EventStore eventStore,
    required UserRelayListStore userRelayListStore,
    super.bootstrapRelays,
  }) : _eventStore = eventStore,
       _userRelayListStore = userRelayListStore;

  @override
  Future<String?> broadcastSkipReason(Nip01Event event) async {
    // checked once the connection is there: a newer version may have been
    // persisted while it was opening, and that one supersedes this send
    if (await _shouldSkipObsoleteReplaceableBroadcast(event)) {
      return 'obsolete replaceable event skipped';
    }
    return null;
  }

  Future<bool> _shouldSkipObsoleteReplaceableBroadcast(Nip01Event event) async {
    if (!EventKindClassification.isReplaceableKind(event.kind)) {
      return false;
    }

    final dTag = event.getDtag();
    final visibleEvents = await _eventStore.loadEvents(
      pubKeys: [event.pubKey],
      kinds: [event.kind],
      tags:
          EventKindClassification.isAddressableKind(event.kind) && dTag != null
          ? {
              'd': [dTag],
            }
          : null,
      limit: 1,
    );

    if (visibleEvents.isEmpty) {
      return false;
    }

    return visibleEvents.single.id != event.id;
  }

  Future<void> doNostrRequestWithRelaySet(
    RequestState state, {
    bool splitRequestsByPubKeyMappings = true,
  }) async {
    if (state.unresolvedFilters.isEmpty || state.request.relaySet == null) {
      return;
    }
    RelaySet relaySet = state.request.relaySet!;
    for (final filter in state.unresolvedFilters) {
      if (splitRequestsByPubKeyMappings) {
        relaySet.splitIntoRequests(filter, state);
        print(
          "request for ${filter.authors != null ? filter.authors!.length : 0} authors with kinds: ${filter.kinds} made requests to ${state.requests.length} relays",
        );

        if (state.requests.isEmpty && relaySet.fallbackToBootstrapRelays) {
          print(
            "making fallback requests to ${bootstrapRelays.length} bootstrap relays for ${filter.authors != null ? filter.authors!.length : 0} authors with kinds: ${filter.kinds}",
          );
          for (final url in bootstrapRelays) {
            state.addRequestForRelay(url, RelaySet.sliceFilterAuthors(filter));
          }
        }
      } else {
        for (final url in relaySet.urls) {
          state.addRequestForRelay(url, RelaySet.sliceFilterAuthors(filter));
        }
      }
    }
    relayManager.globalState.inFlightRequests[state.id] = state;

    state.closeIfNoRelays();

    for (final request in state.requests.values.toList()) {
      doRelayRequest(state.id, request);
    }
  }

  @override
  Future<void> handleRequest(RequestState state) async {
    if (state.request.relaySet == null) {
      return super.handleRequest(state);
    }
    if (state.request.explicitRelays == null ||
        state.request.explicitRelays!.isEmpty) {
      await relayManager.seedRelaysConnected;
    }
    return await doNostrRequestWithRelaySet(state);
  }

  //! dead code
  Future<NdkResponse> requestRelays(
    String name,
    Iterable<String> urls,
    Filter filter, {
    Duration timeout = kDefaultStreamIdleTimeout,
    bool closeOnEOSE = true,
  }) async {
    String id = Helpers.getSecureRandomHex(16);
    RequestState state = RequestState(
      closeOnEOSE
          ? NdkRequest.query(
              id,
              name: name,
              filters: [filter],
              timeoutDuration: timeout,
            )
          : NdkRequest.subscription(id, name: name, filters: []),
    );

    for (final url in urls) {
      state.addRequestForRelay(url, RelaySet.sliceFilterAuthors(filter));
    }
    relayManager.globalState.inFlightRequests[state.id] = state;

    for (final request in state.requests.values.toList()) {
      doRelayRequest(state.id, request);
    }

    return NdkResponse(
      state.id,
      state.stream,
      relayOutcomes: () => state.relayOutcomes,
      relayOutcomesStream: () => state.relayOutcomesStream,
      relayOutcomesDone: state.controller.done.then((_) => state.relayOutcomes),
    );
  }

  /// Own outbox, then the inbox of every p-tagged pubkey.
  @override
  Future<void> broadcastToDefaultRelays(
    Nip01Event workingEvent,
    BroadcastState broadcastState,
  ) async {
    // =====================================================================================
    // own outbox
    // =====================================================================================
    // TODO should not only depend on cached, but go fetch it if not present in cache
    final nip65List = (await UserRelayLists.getUserRelayListCacheLatest(
      pubkeys: [workingEvent.pubKey],
      userRelayListStore: _userRelayListStore,
    ));
    // make a copy of the keys since connectRelay may mutate the underlying map
    // several connections can share a url, and broadcasting twice to the
    // same relay would duplicate the event
    List<String> writeRelaysUrls = relayManager.globalState.relays.keys
        .map((key) => key.url)
        .toSet()
        .toList();
    if (nip65List.isNotEmpty) {
      writeRelaysUrls = nip65List.first.relays.entries
          .where((element) => element.value.isWrite)
          .map((e) => e.key)
          .toList();
    } else {
      Logger.log.w(
        () => "could not find user relay list from nip65, using default bootstrap relays",
      );
    }

    await Future.wait(
      writeRelaysUrls.map(
        (relayUrl) => doRelayBroadcast(relayUrl, workingEvent, broadcastState),
      ),
    );

    // =====================================================================================
    // other inbox
    // =====================================================================================
    if (workingEvent.pTags.isNotEmpty) {
      final nip65Data = await UserRelayLists.getUserRelayListCacheLatest(
        pubkeys: workingEvent.pTags,
        userRelayListStore: _userRelayListStore,
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
          min(
            completeList.length,
            BroadcastDefaults.MAX_INBOX_RELAYS_TO_BROADCAST,
          ),
        );
        myWriteRelayUrlsOthers.addAll(maxList);
      }

      await Future.wait(
        myWriteRelayUrlsOthers.map(
          (relayUrl) =>
              doRelayBroadcast(relayUrl, workingEvent, broadcastState),
        ),
      );
    }
  }
}
