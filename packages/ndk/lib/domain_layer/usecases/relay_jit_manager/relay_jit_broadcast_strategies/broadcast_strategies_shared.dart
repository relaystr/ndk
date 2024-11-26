import '../../../entities/connection_source.dart';
import '../../../entities/nip_01_event.dart';
import '../../../entities/request_state.dart';
import '../relay_jit.dart';

/// checks if [toCheckRelays] are in [connectedRelays]
/// [returns] list of relays that are not in connectedRelays
List<String> checkConnectionStatus({
  required List<RelayJit> connectedRelays,
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
/// [onMessage] callback for new connected relays
/// [returns] list of relays where the connection failed
Future<List<String>> connectRelays({
  required List<String> relaysToConnect,
  required List<RelayJit> connectedRelays,
  required Function(Nip01Event, RequestState) onMessage,
  required ConnectionSource connectionSource,
}) async {
  final List<String> couldNotConnectRelays = [];
  for (final relayUrl in relaysToConnect) {
    RelayJit newRelay = RelayJit(
      url: relayUrl,
      onMessage: onMessage,
    );

    // add the relay to the connected relays
    connectedRelays.add(newRelay);

    final success = await newRelay.connect(connectionSource: connectionSource);
    if (!success) {
      couldNotConnectRelays.add(relayUrl);
    }
  }
  return couldNotConnectRelays;
}
