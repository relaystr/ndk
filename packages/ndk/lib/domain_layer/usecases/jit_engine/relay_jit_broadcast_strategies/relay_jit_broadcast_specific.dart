import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../../shared/nips/nip01/event_kind_classification.dart';
import '../../../repositories/cache_manager.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_auth.dart';
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
    RelayAuth? auth,
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
        eventToPublish: eventToPublish,
        relayUrl: relayUrl,
      );

      try {
        if (!relayManager.isRelayConnected(relayUrl)) {
          final success = (await relayManager.connectRelay(
            dirtyUrl: relayUrl,
            connectionSource: ConnectionSource.broadcastSpecific,
            connectTimeout: 1,
          ))
              .first;
          if (!success) {
            relayManager.failBroadcast(
              eventToPublish.id,
              relayUrl,
              "connection failed",
            );
            return;
          }
        }

        if (await _shouldSkipObsoleteReplaceableBroadcast(
          cacheManager: cacheManager,
          event: eventToPublish,
        )) {
          relayManager.failBroadcast(
            eventToPublish.id,
            relayUrl,
            "obsolete replaceable event skipped",
          );
          return;
        }

        final relay = await relayManager.connectionForBroadcast(
          relayUrl,
          auth,
        );
        if (relay == null) {
          relayManager.failBroadcast(
            eventToPublish.id,
            relayUrl,
            "no connection could carry this broadcast",
          );
          return;
        }
        sendToRelay(relay: relay);
      } catch (e) {
        relayManager.failBroadcast(
          eventToPublish.id,
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
