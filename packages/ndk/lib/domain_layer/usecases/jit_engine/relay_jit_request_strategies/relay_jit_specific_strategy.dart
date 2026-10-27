import 'dart:async';

import '../../../../shared/nips/nip01/client_msg.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/filter.dart';
import '../../../entities/relay_connection_key.dart';
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
    // filter relays we need to connect to first
    final List<Future<Tuple<bool, String>>> connectFutures = [];
    for (final sRelay in specificRelays) {
      // one still connecting is not skipped: connectRelay waits for it
      if (relayManager.isRelayConnected(sRelay)) continue;
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

    // after the sends above announced themselves, so failing these cannot end
    // the request before the connected relays had their turn
    final connectedUrls = specificConnectedRelays.map((r) => r.url).toSet();
    for (final url in specificRelays) {
      if (connectedUrls.contains(url)) continue;
      _fail(url, requestState, filter, relayManager);
    }
  }

  /// Reports [url] as a relay the request could not be sent to, on the
  /// connection the request's auth policy would have used. One no connection
  /// can satisfy is skipped, as [RequestState.addRequestForRelay] does, and
  /// one an earlier filter already reached keeps its outcome.
  static void _fail(
    String url,
    RequestState requestState,
    Filter filter,
    RelayManager relayManager,
  ) {
    final key = RelayConnectionKey.forAuth(url, requestState.request.auth);
    if (key == null || requestState.requests.containsKey(key)) return;
    relayManager.failRelayRequest(requestState, key, [
      filter,
    ], "could not connect");
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
      if (target == null) {
        _fail(connectedRelay.url, requestState, filter, relayManager);
        return;
      }
      if (!relayManager.isStillInFlight(requestState)) {
        return;
      }

      /// register request
      relayManager.registerRelayRequest(
        reqId: requestState.id,
        connectionKey: target.key,
        filters: [filter],
      );
      // an earlier filter may have left this entry notSent
      requestState.requests[target.key]!.markSent();
      relayManager.send(
        target,
        ClientMsg(ClientMsgType.kReq, id: requestState.id, filters: [filter]),
      );
    } finally {
      relayManager.endPendingConnection(requestState);
    }
  }
}
