import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/nip_01_event.dart';
import '../relay_jit.dart';

/// used to spread gossip information on as many relays as possible
class RelayJitBroadcastAllStrategy {
  /// broadcasts to all connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayJit> connectedRelays,
    required String privateKey,
  }) async {
    // sign event
    eventToPublish.sign(privateKey);

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
