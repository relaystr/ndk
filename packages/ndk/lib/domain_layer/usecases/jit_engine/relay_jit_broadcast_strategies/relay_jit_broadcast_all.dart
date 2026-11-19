import 'package:ndk_core/shared/nips/nip01/client_msg.dart';
import 'package:ndk_core/domain_layer/entities/broadcast_state.dart';
import 'package:ndk_core/domain_layer/entities/nip_01_event.dart';
import 'package:ndk_core/domain_layer/entities/relay_connectivity.dart';
import 'package:ndk_core/domain_layer/usecases/relay_manager.dart';

/// used to spread gossip information on as many relays as possible
class RelayJitBroadcastAllStrategy {
  /// broadcasts to all connected relays
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayConnectivity> connectedRelays,
    required RelayManager relayManger,
    required BroadcastState broadcastState,
  }) async {
    final ClientMsg myClientMsg = ClientMsg(
      ClientMsgType.kEvent,
      event: eventToPublish,
    );

    // broadcast event

    for (final relay in connectedRelays) {
      relayManger.registerRelayBroadcast(
        broadcastState: broadcastState,
        eventToPublish: eventToPublish,
        relayUrl: relay.url,
      );
      relayManger.send(relay, myClientMsg);
    }
  }
}
