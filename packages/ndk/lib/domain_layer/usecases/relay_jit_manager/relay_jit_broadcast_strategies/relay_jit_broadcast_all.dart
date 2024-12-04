import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_connectivity.dart';
import '../../../repositories/event_signer.dart';

/// used to spread gossip information on as many relays as possible
class RelayJitBroadcastAllStrategy {
  /// broadcasts to all connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayConnectivity> connectedRelays,
    required EventSigner signer,
  }) async {
    // sign event
    await signer.sign(eventToPublish);

    final ClientMsg myClientMsg = ClientMsg(
      ClientMsgType.EVENT,
      event: eventToPublish,
    );

    // broadcast event

    for (var relay in connectedRelays) {
      relay.relayTransport!.send(myClientMsg);
    }
  }
}
