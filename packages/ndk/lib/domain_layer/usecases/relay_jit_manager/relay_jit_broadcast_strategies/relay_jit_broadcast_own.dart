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

/// broadcast to own outbox relays
class RelayJitBroadcastOutboxStrategy {
  /// publish event to nip65 outbox relays
  /// [onMessage] callback for new connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayConnectivity<JitEngineRelayConnectivityData>>
        connectedRelays,
    required CacheManager cacheManager,
    required RelayManagerLight relayManager,
    required EventSigner signer,
  }) async {
    final nip65Data = await UserRelayLists.getUserRelayListCacheLatestSingle(
      pubkey: eventToPublish.pubKey,
      cacheManager: cacheManager,
    );

    if (nip65Data == null) {
      throw "could not find nip65 data for event";
    }

    /// get all relays where write marker is write

    final writeRelaysUrls = nip65Data.relays.entries
        .where((element) => element.value.isWrite)
        .map((e) => e.key)
        .toList();

    // check connection status
    final notConnectedRelays = checkConnectionStatus(
      connectedRelays: connectedRelays,
      toCheckRelays: writeRelaysUrls,
    );

    // connect missing relays
    final couldNotConnectRelays = await connectRelays(
      connectedRelays: connectedRelays,
      relaysToConnect: notConnectedRelays,
      connectionSource: ConnectionSource.BROADCAST_OWN,
      relayManager: relayManager,
    );

    // list of relays without the failed ones
    final List<String> actualBroadcastList = writeRelaysUrls
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
      relayManager.send(relay, myClientMsg);
    }

    // todo: look into onMessage and decipher different event types

    return couldNotConnectRelays;
  }
}
