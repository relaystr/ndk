import 'dart:async';

import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/filter.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/relay_connectivity.dart';
import '../../../entities/request_state.dart';
import '../../relay_manager.dart';

/// Strategy Description:
///
/// blast the request to all connected relays without adding the pubkey to the relay
///
class RelayJitBlastAllStrategy {
  /// send out the request
  static void handleRequest({
    required RequestState requestState,
    required Filter filter,
    required List<RelayConnectivity<JitEngineRelayConnectivityData>>
        connectedRelays,
    required bool closeOnEOSE,
    required RelayManager relayManager,
    required List<String> bootstrapRelays,
  }) {
    for (final connectedRelay in connectedRelays) {
      // skip if the relay is not in the bootstrap relays
      if (!bootstrapRelays.contains(connectedRelay.url)) continue;
      unawaited(_blastTo(connectedRelay, requestState, filter, relayManager));
    }
  }

  static Future<void> _blastTo(
    RelayConnectivity<JitEngineRelayConnectivityData> connectedRelay,
    RequestState requestState,
    Filter filter,
    RelayManager relayManager,
  ) async {
    final target = await relayManager.connectionForRequest(
      requestState,
      connectedRelay,
    );
    if (target == null || !relayManager.isStillInFlight(requestState)) {
      return;
    }

    /// register request
    relayManager.registerRelayRequest(
      reqId: requestState.id,
      connectionKey: target.key,
      filters: [filter],
    );
    relayManager.send(
      target,
      ClientMsg(ClientMsgType.kReq, id: requestState.id, filters: [filter]),
    );
  }
}
