import 'package:ndk/domain_layer/usecases/inbox_outbox/get_nip_65_data.dart';
import 'package:ndk/entities.dart';

import '../../../../config/broadcast_defaults.dart';
import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/request_state.dart';
import '../../../repositories/cache_manager.dart';
import '../relay_jit.dart';
import 'broadcast_strategies_shared.dart';

/// broadcast to other read relays
class RelayJitBroadcastOtherReadStrategy {
  /// publish event to nip65 inbox of specified people
  /// [pubkeysOfInbox] list of pubkeys, the inbox relays of these pubkeys are used
  /// [onMessage] callback for new connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayJit> connectedRelays,
    required CacheManager cacheManager,
    required Function(Nip01Event, RequestState) onMessage,
    required String privateKey,
    required List<String> pubkeysOfInbox,
  }) async {
    final nip65Data = getNip65Data(pubkeysOfInbox, cacheManager);

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
      onMessage: onMessage,
      relaysToConnect: notConnectedRelays,
      connectionSource: ConnectionSource.BROADCAST_OTHER,
    );

    // list of relays without the failed ones
    final List<String> actualBroadcastList = myWriteRelayUrls
        .where((element) => !couldNotConnectRelays.contains(element))
        .toList();

    // sign event
    eventToPublish.sign(privateKey);

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

    return couldNotConnectRelays;
  }
}
