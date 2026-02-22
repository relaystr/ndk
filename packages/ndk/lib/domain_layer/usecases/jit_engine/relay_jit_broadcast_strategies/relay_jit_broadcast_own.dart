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

    for (final relayUrl in writeRelaysUrls) {
      // register relay broadcast
      relayManager.registerRelayBroadcast(
        eventToPublish: eventToPublish,
        relayUrl: relayUrl,
      );

      final isConnected = relayManager.isRelayConnected(relayUrl);
      if (isConnected) {
        sendToRelay(
          relay: connectedRelays.firstWhere(
            (element) => element.url == relayUrl,
          ),
        );
        continue;
      }
      relayManager
          .connectRelay(
        dirtyUrl: relayUrl,
        connectionSource: ConnectionSource.broadcastOwn,
      )
          .then((success) {
        if (!success.first) {
          relayManager.failBroadcast(
            eventToPublish.id,
            relayUrl,
            "connection failed",
          );
          return;
        }
        final relay = relayManager.connectedRelays
            .firstWhere((element) => element.url == relayUrl);

        sendToRelay(relay: relay);
      });
    }
  }
}
