import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_connectivity.dart';
import '../../relay_manager.dart';

/// used to spread gossip information on as many relays as possible
class RelayJitBroadcastAllStrategy {
  /// broadcasts to all connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayConnectivity> connectedRelays,
    required RelayManager relayManger,
  }) async {
    final ClientMsg myClientMsg = ClientMsg(
      ClientMsgType.kEvent,
      event: eventToPublish,
    );

    // broadcast event

    for (final relay in connectedRelays) {
      relayManger.registerRelayBroadcast(
        eventToPublish: eventToPublish,
        relayUrl: relay.url,
      );
      relayManger.send(relay, myClientMsg);
    }
  }
}
