import 'dart:async';

import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/filter.dart';
import '../../../entities/relay_connectivity.dart';
import '../../../entities/request_state.dart';
import '../../../entities/tuple.dart';
import '../../relay_manager.dart';

/// Strategy Description:
///
/// blast the request to all connected relays without adding the pubkey to the relay
///
class RelayJitRequestSpecificStrategy {
  /// send out the request
  static Future<void> handleRequest({
    required RequestState requestState,
    required Filter filter,
    required bool closeOnEOSE,
    required RelayManager relayManager,
    required Iterable<String> specificRelays,
  }) async {
    // Ask for every named relay. [RelayManager.connectRelay] is idempotent and
    // already awaits a connect someone else started, which is what makes this
    // safe on a shared pool: the relay sets engine may be opening this very
    // relay right now.
    //
    // Skipping a relay that is merely connecting would be wrong: the send below
    // picks its targets from the connected relays only, so a relay skipped here
    // would silently never receive the request.
    final List<Future<Tuple<bool, String>>> connectFutures = [];
    for (final sRelay in specificRelays) {
      connectFutures.add(
        relayManager.connectRelay(
          dirtyUrl: sRelay,
          connectionSource: ConnectionSource.explicit,
        ),
      );
    }
    await Future.wait(connectFutures);

    // filter connected relays && specific relays
    final specificConnectedRelays = relayManager.connectedAnonymousRelays
        .where((relay) => specificRelays.contains(relay.url))
        .toList();

    for (final connectedRelay in specificConnectedRelays) {
      unawaited(_sendTo(connectedRelay, requestState, filter, relayManager));
    }
  }

  static Future<void> _sendTo(
    RelayConnectivity connectedRelay,
    RequestState requestState,
    Filter filter,
    RelayManager relayManager,
  ) async {
    relayManager.beginPendingConnection(requestState);
    try {
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
    } finally {
      relayManager.endPendingConnection(requestState);
    }
  }
}
