import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/filter.dart';
import '../../../entities/request_state.dart';
import '../../../entities/tuple.dart';
import '../../relay_manager.dart';

/// Strategy Description:
///
/// blast the request to all connected relays without adding the pubkey to the relay
///
class RelayJitRequestSpecificStrategy {
  /// send out the request
  static void handleRequest({
    required RequestState requestState,
    required Filter filter,
    required bool closeOnEOSE,
    required RelayManager relayManager,
    required Iterable<String> specificRelays,
  }) async {
    // filter relays we need to connect to first
    final List<Future<Tuple<bool, String>>> connectFutures = [];
    for (final sRelay in specificRelays) {
      final isConnected = relayManager.isRelayConnected(sRelay);
      final tryingToConnect = relayManager.isRelayConnecting(sRelay);
      if (isConnected || tryingToConnect) continue;
      connectFutures.add(relayManager.connectRelay(
        dirtyUrl: sRelay,
        connectionSource: ConnectionSource.explicit,
      ));
    }
    await Future.wait(connectFutures);

    // filter connected relays && specific relays
    final specificConnectedRelays = relayManager.connectedRelays
        .where((relay) => specificRelays.contains(relay.url))
        .toList();

    for (final connectedRelay in specificConnectedRelays) {
      final clientMsg = ClientMsg(
        ClientMsgType.kReq,
        id: requestState.id,
        filters: [filter],
      );

      /// register request
      relayManager.registerRelayRequest(
        reqId: requestState.id,
        relayUrl: connectedRelay.url,
        filters: [filter],
      );
      relayManager.send(connectedRelay, clientMsg);
    }
  }
}
