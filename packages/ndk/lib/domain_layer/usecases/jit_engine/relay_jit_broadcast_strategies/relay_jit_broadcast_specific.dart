import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../../shared/nips/nip01/event_kind_classification.dart';
import '../../../repositories/cache_manager.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/broadcast_state.dart';
import '../../../entities/relay_connectivity.dart';
import '../../relay_manager.dart';

/// broadcast to specific relays
class RelayJitBroadcastSpecificRelaysStrategy {
  /// [specificRelays] urls of relays you want to publish to
  static Future broadcast({
    required Nip01Event eventToPublish,
    required CacheManager cacheManager,
    required RelayManager relayManager,
    required List<String> specificRelays,
    required BroadcastState broadcastState,
  }) async {
    // Deduplicate relay URLs
    final uniqueRelayUrls = specificRelays.toSet().toList();

    // function to send message to relay
    void sendToRelay({required RelayConnectivity relay}) {
      final myClientMsg = ClientMsg(
        ClientMsgType.kEvent,
        event: eventToPublish,
      );
      relayManager.send(relay, myClientMsg);
    }

    // Function to handle broadcasting to a single relay
    Future<void> sendToUrl(String relayUrl) async {
      // register relay broadcast
      relayManager.registerRelayBroadcast(
        broadcastState: broadcastState,
        eventToPublish: eventToPublish,
        relayUrl: relayUrl,
      );

      try {
        final relay = await relayManager.connectionForBroadcast(
          relayUrl,
          broadcastState.auth,
          connectTimeout: 1,
          pausing: broadcastState,
        );
        if (relay == null) {
          relayManager.failBroadcast(
            broadcastState,
            relayUrl,
            "no connection could carry this broadcast",
          );
          return;
        }

        // checked once the connection is there: a newer version may have been
        // persisted while it was opening, and that one supersedes this send
        if (await _shouldSkipObsoleteReplaceableBroadcast(
          cacheManager: cacheManager,
          event: eventToPublish,
        )) {
          relayManager.failBroadcast(
            broadcastState,
            relayUrl,
            "obsolete replaceable event skipped",
          );
          return;
        }

        sendToRelay(relay: relay);
      } catch (e) {
        relayManager.failBroadcast(
          broadcastState,
          relayUrl,
          "broadcast error: $e",
        );
      }
    }

    // Broadcast to all relays in parallel
    await Future.wait(uniqueRelayUrls.map(sendToUrl), eagerError: false);
  }

  static Future<bool> _shouldSkipObsoleteReplaceableBroadcast({
    required CacheManager cacheManager,
    required Nip01Event event,
  }) async {
    if (!EventKindClassification.isReplaceableKind(event.kind)) {
      return false;
    }

    final dTag = event.getDtag();
    final visibleEvents = await cacheManager.loadEvents(
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
}
