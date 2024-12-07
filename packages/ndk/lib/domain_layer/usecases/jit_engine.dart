import 'dart:async';

import '../../shared/helpers/relay_helper.dart';
import '../../shared/logger/logger.dart';
import '../entities/broadcast_response.dart';
import '../entities/connection_source.dart';
import '../entities/global_state.dart';
import '../entities/jit_engine_relay_connectivity_data.dart';
import '../entities/nip_01_event.dart';
import '../entities/read_write_marker.dart';
import '../entities/relay_connectivity.dart';
import '../entities/request_state.dart';
import '../repositories/cache_manager.dart';
import '../repositories/event_signer.dart';
import 'engines/network_engine.dart';
import 'relay_jit_manager/relay_jit_broadcast_strategies/relay_jit_broadcast_all.dart';
import 'relay_jit_manager/relay_jit_broadcast_strategies/relay_jit_broadcast_other_read.dart';
import 'relay_jit_manager/relay_jit_broadcast_strategies/relay_jit_broadcast_own.dart';
import 'relay_jit_manager/relay_jit_request_strategies/relay_jit_blast_all_strategy.dart';
import 'relay_jit_manager/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';
import 'relay_manager_light.dart';

/// Just In Time Network Engine
/// This engine is responsible for handling all nostr network requests
class JitEngine with Logger implements NetworkEngine {
  /// event signer for signing events
  EventSigner? eventSigner;

  /// cache manager for caching events
  CacheManager cache;

  /// relays to ignore
  List<String> ignoreRelays;

  /// manager for all relays
  RelayManagerLight relayManagerLight;

  /// global state of the ndk
  GlobalState globalState;

  /// Creates a new JIT engine.
  JitEngine({
    this.eventSigner,
    required this.relayManagerLight,
    required this.cache,
    required this.ignoreRelays,
    required this.globalState,
  }) {}

  /// If you request anything from the nostr network put it here and
  /// the relay jit manager will try to find the right relay and use it
  /// if no relay is found the request will be blasted to all connected relays (on start seed Relays)
  @override
  void handleRequest(
    RequestState requestState,
  ) async {
    await relayManagerLight.seedRelaysConnected;

    final ndkRequest = requestState.request;

    //clean ignore relays
    List<String> cleanIgnoreRelays = cleanRelayUrls(ignoreRelays);

    /// ["REQ", <subscription_id>, <filters1>, <filters2>, ...]
    /// user can provide multiple filters
    for (var filter in requestState.unresolvedFilters) {
      // filter different types of filters/requests because each requires a different strategy

      if ((filter.authors != null && filter.authors!.isNotEmpty)) {
        RelayJitPubkeyStrategy.handleRequest(
          globalState: globalState,
          relayManager: relayManagerLight,
          requestState: requestState,
          cacheManager: cache,
          filter: filter,
          connectedRelays: relayManagerLight.connectedRelays
              as List<RelayConnectivity<JitEngineRelayConnectivityData>>,
          desiredCoverage: ndkRequest.desiredCoverage,
          closeOnEOSE: ndkRequest.closeOnEOSE,
          direction: ReadWriteMarker
              .writeOnly, // the author should write on the persons write relays
          ignoreRelays: cleanIgnoreRelays,
        );
        continue;
      }

      if (filter.pTags?.isNotEmpty != null && filter.pTags!.isNotEmpty) {
        RelayJitPubkeyStrategy.handleRequest(
          relayManager: relayManagerLight,
          globalState: globalState,
          requestState: requestState,
          cacheManager: cache,
          filter: filter,
          connectedRelays: relayManagerLight.connectedRelays
              as List<RelayConnectivity<JitEngineRelayConnectivityData>>,
          desiredCoverage: ndkRequest.desiredCoverage,
          closeOnEOSE: ndkRequest.closeOnEOSE,
          direction: ReadWriteMarker
              .readOnly, // others should mention on the persons read relays
          ignoreRelays: cleanIgnoreRelays,
        );
        continue;
      }

      if (filter.search != null) {
        throw UnimplementedError("search filter not implemented yet");
      }

      // if (filter.ids != null) {
      //   throw UnimplementedError("ids filter not implemented yet");
      // }

      /// unknown filter strategy, blast to all connected relays
      RelayJitBlastAllStrategy.handleRequest(
        requestState: requestState,
        filter: filter,
        connectedRelays: relayManagerLight.connectedRelays
            as List<RelayConnectivity<JitEngineRelayConnectivityData>>,
        closeOnEOSE: requestState.request.closeOnEOSE,
      );
    }
  }

  /// broadcasts given event using inbox/outbox (gossip) if explicit relays are given they are used instead
  /// [nostrEvent] event to publish
  /// [explicitRelays] used instead of gossip if set

  @override
  NdkBroadcastResponse handleEventBroadcast({
    required Nip01Event nostrEvent,
    required EventSigner mySigner,
    required Future<List<RelayBroadcastResponse>> doneFuture,
    Iterable<String>? specificRelays,
  }) {
    Future<void> asyncStuff() async {
      await relayManagerLight.seedRelaysConnected;

      if (specificRelays != null) {
        return RelayJitBroadcastAllStrategy.broadcast(
          eventToPublish: nostrEvent,
          connectedRelays: relayManagerLight.connectedRelays
              as List<RelayConnectivity<JitEngineRelayConnectivityData>>,
          signer: mySigner,
        );
      }

      // default publish to own outbox
      await RelayJitBroadcastOutboxStrategy.broadcast(
        eventToPublish: nostrEvent,
        connectedRelays: relayManagerLight.connectedRelays
            as List<RelayConnectivity<JitEngineRelayConnectivityData>>,
        cacheManager: cache,
        relayManager: relayManagerLight,
        signer: mySigner,
      );

      // check if we need to publish to others inboxes
      if (nostrEvent.pTags.isNotEmpty) {
        await RelayJitBroadcastOtherReadStrategy.broadcast(
          eventToPublish: nostrEvent,
          connectedRelays: relayManagerLight.connectedRelays
              as List<RelayConnectivity<JitEngineRelayConnectivityData>>,
          cacheManager: cache,
          relayManager: relayManagerLight,
          signer: mySigner,
          pubkeysOfInbox: nostrEvent.pTags,
        );
      }
    }

    asyncStuff();
    return NdkBroadcastResponse(
      publishEvent: nostrEvent,
      publishDoneFuture: doneFuture,
    );
  }

  /// close a relay subscription, the relay connection will be kept open and closed automatically (garbage collected)
  @override
  closeSubscription(String id) async {
    //await seedRelaysConnected;
    print("todo: cloes");
  }

  /// checks if relay covers given pubkey in given direction
  static bool doesRelayCoverPubkey(
    RelayConnectivity<JitEngineRelayConnectivityData> relay,
    String pubkey,
    ReadWriteMarker direction,
  ) {
    for (RelayJitAssignedPubkey assignedPubkey
        in relay.specificEngineData!.assignedPubkeys) {
      if (assignedPubkey.pubkey == pubkey) {
        switch (direction) {
          case ReadWriteMarker.readOnly:
            return assignedPubkey.direction.isRead;
          case ReadWriteMarker.writeOnly:
            return assignedPubkey.direction.isWrite;
          case ReadWriteMarker.readWrite:
            return assignedPubkey.direction == ReadWriteMarker.readWrite;
          default:
            return false;
        }
      }
    }
    return false;
  }

  /// add to response stream
  void onMessage(Nip01Event event, RequestState requestState) async {
    // add to response stream
    requestState.networkController.add(event);
  }

  static void onEoseReceivedFromRelay(RequestState requestState) async {
    // check if all subscriptions received EOSE (async) at the current time

    if (requestState.isSubscription) {
      return;
    }
    // for (var sub in requestState.activeRelaySubscriptions.values) {
    //   await sub.activeSubscriptions[requestState.id]?.eoseReceived;
    // }
    // requestState.networkController.close();

    print("todo eose");
  }
}
