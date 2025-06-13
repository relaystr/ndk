import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_connectivity.dart';
import '../../relay_manager.dart';

/// broadcast to specific relays
class RelayJitBroadcastSpecificRelaysStrategy {
  /// [specificRelays] urls of relays you want to publish to
  static Future broadcast({
    required Nip01Event eventToPublish,
    required List<RelayConnectivity<JitEngineRelayConnectivityData>>
        connectedRelays,
    required RelayManager relayManager,
    required List<String> specificRelays,
  }) async {
    void sendToRelay({
      required RelayConnectivity relay,
    }) {
      final myClientMsg = ClientMsg(
        ClientMsgType.kEvent,
        event: eventToPublish,
      );
      relayManager.send(relay, myClientMsg);
    }

    for (final relayUrl in specificRelays) {
      // register relay broadcast
      relayManager.registerRelayBroadcast(
        eventToPublish: eventToPublish,
        relayUrl: relayUrl,
      );

      final isConnected = relayManager.isRelayConnected(relayUrl);
      if (isConnected) {
        sendToRelay(
          relay: connectedRelays.firstWhere(
            (element) => element.url == relayUrl,
          ),
        );
        continue;
      }

      relayManager
          .connectRelay(
        dirtyUrl: relayUrl,
        connectionSource: ConnectionSource.broadcastSpecific,
      )
          .then((success) {
        if (!success.first) {
          relayManager.failBroadcast(
            eventToPublish.id,
            relayUrl,
            "connection failed",
          );
          return;
        }
        final relay = relayManager.connectedRelays
            .firstWhere((element) => element.url == relayUrl);

        sendToRelay(relay: relay);
      });
    }
  }
}
