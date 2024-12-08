import '../../../entities/connection_source.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/relay_connectivity.dart';
import '../../relay_manager_light.dart';

/// checks if [toCheckRelays] are in [connectedRelays]
/// [returns] list of relays that are not in connectedRelays
List<String> checkConnectionStatus({
  required List<RelayConnectivity<JitEngineRelayConnectivityData>>
      connectedRelays,
  required List<String> toCheckRelays,
}) {
  List<String> notConnectedRelays = [];
  for (var relayUrl in toCheckRelays) {
    if (!connectedRelays.any((element) => element.url == relayUrl)) {
      notConnectedRelays.add(relayUrl);
    }
  }
  return notConnectedRelays;
}

/// connect relays
/// [relaysToConnect] the relays this function tries to connect
/// [connectedRelays] already connected relays

/// [returns] list of relays where the connection failed
Future<List<String>> connectRelays({
  required List<String> relaysToConnect,
  required List<RelayConnectivity<JitEngineRelayConnectivityData>>
      connectedRelays,
  required RelayManagerLight relayManager,
  required ConnectionSource connectionSource,
}) async {
  final List<String> couldNotConnectRelays = [];
  for (final relayUrl in relaysToConnect) {
    final success = await relayManager.connectRelay(
        connectionSource: connectionSource, dirtyUrl: relayUrl);

    if (!success.first) {
      couldNotConnectRelays.add(relayUrl);
    }
  }
  return couldNotConnectRelays;
}
