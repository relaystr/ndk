import '../../../../config/broadcast_defaults.dart';
import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_connectivity.dart';
import '../../../repositories/cache_manager.dart';
import '../../../repositories/event_signer.dart';
import '../../relay_manager_light.dart';
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
    required RelayManagerLight relayManager,
    required EventSigner signer,
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
        BroadcastDefaults.MAX_INBOX_RELAYS_TO_BROADCAST,
      );
      myWriteRelayUrls.addAll(maxList);
    }

    // check connection status
    final notConnectedRelays = checkConnectionStatus(
      connectedRelays: connectedRelays,
      toCheckRelays: myWriteRelayUrls,
    );

    // connect missing relays
    final couldNotConnectRelays = await connectRelays(
      connectedRelays: connectedRelays,
      relayManager: relayManager,
      relaysToConnect: notConnectedRelays,
      connectionSource: ConnectionSource.BROADCAST_OTHER,
    );

    // list of relays without the failed ones
    final List<String> actualBroadcastList = myWriteRelayUrls
        .where((element) => !couldNotConnectRelays.contains(element))
        .toList();

    // sign event
    await signer.sign(eventToPublish);

    final ClientMsg myClientMsg = ClientMsg(
      ClientMsgType.EVENT,
      event: eventToPublish,
    );

    // broadcast event
    for (var relayUrl in actualBroadcastList) {
      final relay =
          connectedRelays.firstWhere((element) => element.url == relayUrl);

      // register relay broadcast
      relayManager.registerRelayBroadcast(
        eventToPublish: eventToPublish,
        relayUrl: relay.url,
      );
      relayManager.send(relay, myClientMsg);
    }

    return couldNotConnectRelays;
  }
}
