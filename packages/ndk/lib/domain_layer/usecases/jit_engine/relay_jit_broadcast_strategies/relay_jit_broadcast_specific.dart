import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_connectivity.dart';
import '../../relay_manager.dart';
import 'broadcast_strategies_shared.dart';

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
    // check connection status
    final notConnectedRelays = checkConnectionStatus(
      connectedRelays: connectedRelays,
      toCheckRelays: specificRelays,
    );

    // connect missing relays
    final couldNotConnectRelays = await connectRelays(
      connectedRelays: connectedRelays,
      relayManager: relayManager,
      relaysToConnect: notConnectedRelays,
      connectionSource: ConnectionSource.broadcastSpecific,
    );

    // list of relays without the failed ones
    final List<String> actualBroadcastList = specificRelays
        .where((element) => !couldNotConnectRelays.contains(element))
        .toList();

    final ClientMsg myClientMsg = ClientMsg(
      ClientMsgType.kEvent,
      event: eventToPublish,
    );

    // broadcast event
    for (var relayUrl in actualBroadcastList) {
      if (connectedRelays.isEmpty) {
        throw Exception("No connected relays");
      }

      final relay = relayManager.connectedRelays
          .firstWhere((element) => element.url == relayUrl);

      relayManager.registerRelayBroadcast(
        eventToPublish: eventToPublish,
        relayUrl: relay.url,
      );

      relayManager.send(relay, myClientMsg);
    }

    return couldNotConnectRelays;
  }
}
