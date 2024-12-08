import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/relay_connectivity.dart';
import '../../relay_manager_light.dart';
import 'broadcast_strategies_shared.dart';

/// broadcast to specific relays
class RelayJitBroadcastSpecificRelaysStrategy {
  /// [specificRelays] urls of relays you want to publish to
  /// [returns] list of relays that failed to connect
  static Future<List<String>> broadcast({
    required Nip01Event eventToPublish,
    required List<RelayConnectivity<JitEngineRelayConnectivityData>>
        connectedRelays,
    required RelayManagerLight relayManager,
    required String privateKey,
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
      connectionSource: ConnectionSource.BROADCAST_SPECIFIC,
    );

    // list of relays without the failed ones
    final List<String> actualBroadcastList = specificRelays
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
      relayManager.send(relay, myClientMsg);
    }

    return couldNotConnectRelays;
  }
}
