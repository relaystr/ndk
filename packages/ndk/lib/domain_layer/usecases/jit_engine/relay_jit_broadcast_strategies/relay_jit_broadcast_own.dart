import '../../../../shared/logger/logger.dart';
import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_connectivity.dart';
import '../../../repositories/cache_manager.dart';
import '../../relay_manager.dart';
import '../../user_relay_lists/user_relay_lists.dart';

/// broadcast to own outbox relays
class RelayJitBroadcastOutboxStrategy {
  /// publish event to nip65 outbox relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayConnectivity<JitEngineRelayConnectivityData>>
        connectedRelays,
    required CacheManager cacheManager,
    required RelayManager relayManager,
    required List<String> bootstrapRelays,
  }) async {
    final nip65Data = await UserRelayLists.getUserRelayListCacheLatestSingle(
      pubkey: eventToPublish.pubKey,
      cacheManager: cacheManager,
    );

    List<String> writeRelaysUrls;

    if (nip65Data == null) {
      Logger.log.w(() =>
          "broadcast - could not find nip65 data for ${eventToPublish.pubKey}, using DEFAULT_BOOTSTRAP_RELAYS for now. \nPlease ensure nip65Data exists to use outbox model => UserRelayLists usecase");

      writeRelaysUrls = bootstrapRelays;
    } else {
      /// get all relays where write marker is write

      writeRelaysUrls = nip65Data.relays.entries
          .where((element) => element.value.isWrite)
          .map((e) => e.key)
          .toList();
    }

    // Deduplicate relay URLs
    final uniqueRelayUrls = writeRelaysUrls.toSet().toList();

    // function to send message to relay
    void sendToRelay({
      required RelayConnectivity relay,
    }) {
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
        final isConnected = relayManager.isRelayConnected(relayUrl);
        if (isConnected) {
          try {
            final relay = connectedRelays.firstWhere(
              (element) => element.url == relayUrl,
            );
            sendToRelay(relay: relay);
          } catch (e) {
            relayManager.failBroadcast(
              eventToPublish.id,
              relayUrl,
              "relay not found in connected list",
            );
          }
          return;
        }

        final success = await relayManager.connectRelay(
          dirtyUrl: relayUrl,
          connectionSource: ConnectionSource.broadcastOwn,
        );
        if (!success.first) {
          relayManager.failBroadcast(
            eventToPublish.id,
            relayUrl,
            "connection failed",
          );
          return;
        }

        try {
          final relay = relayManager.connectedRelays
              .firstWhere((element) => element.url == relayUrl);
          sendToRelay(relay: relay);
        } catch (e) {
          relayManager.failBroadcast(
            eventToPublish.id,
            relayUrl,
            "relay not found after connection",
          );
        }
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
}
