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
import 'broadcast_strategies_shared.dart';

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

    // check connection status
    final notConnectedRelays = checkConnectionStatus(
      connectedRelays: connectedRelays,
      toCheckRelays: myWriteRelayUrls,
    );

    // register relay broadcast
    for (final relayUrl in myWriteRelayUrls) {
      relayManager.registerRelayBroadcast(
        eventToPublish: eventToPublish,
        relayUrl: relayUrl,
      );
    }

    // connect missing relays
    final couldNotConnectRelays = await connectRelays(
      relayManager: relayManager,
      relaysToConnect: notConnectedRelays,
      connectionSource: ConnectionSource.broadcastOther,
    );

    for (final failedRelay in couldNotConnectRelays) {
      relayManager.failBroadcast(
        eventToPublish.id,
        failedRelay,
        "connection failed",
      );
    }

    // list of relays without the failed ones
    final List<String> actualBroadcastList = myWriteRelayUrls
        .where((element) => !couldNotConnectRelays.contains(element))
        .toList();

    final ClientMsg myClientMsg = ClientMsg(
      ClientMsgType.kEvent,
      event: eventToPublish,
    );

    // broadcast event
    for (var relayUrl in actualBroadcastList) {
      final relay = relayManager.connectedRelays
          .firstWhere((element) => element.url == relayUrl);

      relayManager.send(relay, myClientMsg);
    }

    return couldNotConnectRelays;
  }
}
