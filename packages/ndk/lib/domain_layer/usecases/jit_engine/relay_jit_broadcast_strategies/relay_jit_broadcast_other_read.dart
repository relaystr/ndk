import 'dart:math';

import '../../../../config/broadcast_defaults.dart';
import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_connectivity.dart';
import '../../../repositories/cache_manager.dart';
import '../../relay_manager.dart';
import '../../user_relay_lists/user_relay_lists.dart';

/// broadcast to other read relays
class RelayJitBroadcastOtherReadStrategy {
  /// publish event to nip65 inbox of specified people
  /// [pubkeysOfInbox] list of pubkeys, the inbox relays of these pubkeys are used
  /// [onMessage] callback for new connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayConnectivity<JitEngineRelayConnectivityData>>
        connectedRelays,
    required CacheManager cacheManager,
    required RelayManager relayManager,
    required List<String> pubkeysOfInbox,
  }) async {
    final nip65Data = await UserRelayLists.getUserRelayListCacheLatest(
      pubkeys: pubkeysOfInbox,
      cacheManager: cacheManager,
    );

    List<String> myWriteRelayUrls = [];

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
      myWriteRelayUrls.addAll(maxList);
    }

    // Deduplicate relay URLs
    final uniqueRelayUrls = myWriteRelayUrls.toSet().toList();

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
          connectionSource: ConnectionSource.broadcastOther,
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
