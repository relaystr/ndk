import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/request_state.dart';
import '../../../repositories/cache_manager.dart';
import '../../../repositories/event_signer.dart';

import '../../inbox_outbox/inbox_outbox.dart';
import '../relay_jit.dart';
import 'broadcast_strategies_shared.dart';

/// broadcast to own outbox relays
class RelayJitBroadcastOutboxStrategy {
  /// publish event to nip65 outbox relays
  /// [onMessage] callback for new connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayJit> connectedRelays,
    required CacheManager cacheManager,
    required Function(Nip01Event, RequestState) onMessage,
    required EventSigner signer,
  }) async {
    final nip65Data = await InboxOutbox.getNip65CacheLatestSingle(
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
        onMessage: onMessage,
        relaysToConnect: notConnectedRelays,
        connectionSource: ConnectionSource.BROADCAST_OWN);

    // list of relays without the failed ones
    final List<String> actualBroadcastList = writeRelaysUrls
        .where((element) => !couldNotConnectRelays.contains(element))
        .toList();

    // sign event
    signer.sign(eventToPublish);

    final ClientMsg myClientMsg = ClientMsg(
      ClientMsgType.EVENT,
      event: eventToPublish,
    );

    // broadcast event
    for (var relayUrl in actualBroadcastList) {
      final relay =
          connectedRelays.firstWhere((element) => element.url == relayUrl);
      relay.send(myClientMsg);
    }

    // todo: look into onMessage and decipher different event types

    return couldNotConnectRelays;
  }
}
