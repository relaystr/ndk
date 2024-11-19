import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/nip_01_event.dart';
import '../../../repositories/event_signer.dart';
import '../relay_jit.dart';

/// used to spread gossip information on as many relays as possible
class RelayJitBroadcastAllStrategy {
  /// broadcasts to all connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayJit> connectedRelays,
    required EventSigner signer,
  }) async {
    // sign event
    await signer.sign(eventToPublish);

    final ClientMsg myClientMsg = ClientMsg(
      ClientMsgType.EVENT,
      event: eventToPublish,
    );

    // broadcast event

    List<Future> waitForAll = [];
    for (var relay in connectedRelays) {
      final result = relay.send(myClientMsg);
      waitForAll.add(result);
    }

    return Future.wait(waitForAll);
  }
}
