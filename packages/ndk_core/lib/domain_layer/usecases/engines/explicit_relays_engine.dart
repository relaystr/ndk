import 'dart:async';

import 'package:meta/meta.dart';

import '../../../config/bootstrap_relays.dart';
import '../../../shared/helpers/relay_helper.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/client_msg.dart';
import '../../entities/auth_policy.dart';
import '../../entities/broadcast_response.dart';
import '../../entities/broadcast_state.dart';
import '../../entities/connection_source.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/relay_connectivity.dart';
import '../../entities/relay_set.dart';
import '../../entities/request_state.dart';
import '../../repositories/event_signer.dart';
import '../relay_manager.dart';
import 'network_engine.dart';

/// Sends requests and broadcasts to the relays the caller names, or to the
/// bootstrap relays when it names none. Relay sets are left to engines that
/// extend this one.
class ExplicitRelaysEngine implements NetworkEngine {
  final RelayManager relayManager;

  final List<String> bootstrapRelays;

  ExplicitRelaysEngine({
    required this.relayManager,
    List<String>? bootstrapRelays,
  }) : bootstrapRelays = bootstrapRelays ?? DEFAULT_BOOTSTRAP_RELAYS;

  @override
  Future<void> handleRequest(RequestState state) async {
    Iterable<String>? relaysForRequest;

    if (state.request.explicitRelays != null &&
        state.request.explicitRelays!.isNotEmpty) {
      relaysForRequest = state.request.explicitRelays;
    } else {
      await relayManager.seedRelaysConnected;
      relaysForRequest = bootstrapRelays;
    }
    relaysForRequest = cleanRelayUrls(relaysForRequest!.toList());
    for (final url in relaysForRequest) {
      if (state.request.filters.isEmpty) {
        throw Exception("cannot do request with empty filters");
      }
      final List<Filter> filters = [];
      for (final filter in state.request.filters) {
        filters.addAll(RelaySet.sliceFilterAuthors(filter));
      }
      state.addRequestForRelay(url, filters);
    }
    relayManager.globalState.inFlightRequests[state.id] = state;

    state.closeIfNoRelays();

    for (final request in state.requests.values.toList()) {
      doRelayRequest(state.id, request);
    }
  }

  /// Sends [request] to its relay. One it cannot be sent to is reported as
  /// notSent before the send path ends, so the request never closes on that
  /// relay as merely disconnected.
  Future<bool> doRelayRequest(String id, RelayRequestState request) async {
    // a connection that is still opening is not one that is gone, and
    // _checkNetworkClose cannot tell them apart on its own
    final state = relayManager.globalState.inFlightRequests[id];
    if (state != null) {
      relayManager.beginPendingConnection(state);
    }
    try {
      final notSentReason = await _sendRelayRequest(id, request, state);
      if (notSentReason != null && state != null) {
        relayManager.failRelayRequest(
          state,
          request.key,
          request.filters,
          notSentReason,
        );
      }
      return notSentReason == null;
    } finally {
      if (state != null) {
        relayManager.endPendingConnection(state);
      }
    }
  }

  /// Null once sent, otherwise what kept [request] from being sent.
  Future<String?> _sendRelayRequest(
    String id,
    RelayRequestState request,
    RequestState? state,
  ) async {
    if (relayManager.globalState.blockedRelays.contains(request.url)) {
      Logger.log.w(
        () => "COULD NOT SEND REQUEST TO ${request.url} since relay is blocked",
      );
      return "relay is blocked";
    }

    final connected = await relayManager.reconnectConnection(
      request.key,
      connectionSource:
          ConnectionSource.explicit, // TODO improve this connection source
      force: false,
      as: state?.request.auth?.account,
      pausing: state,
    );
    // a timeout or a closeSubscription may have ended the request while the
    // connection was opening: nothing tracks it anymore, so nothing would ever
    // CLOSE what we would send here
    if (state != null && !relayManager.isStillInFlight(state)) {
      return "request ended while connecting";
    }
    if (connected) {
      RelayConnectivity? relay = relayManager.globalState.relays[request.key];
      if (relay == null) {
        // the connection was closed between opening it and looking it up
        Logger.log.w(
          () =>
              "COULD NOT SEND REQUEST TO ${request.url}, ${request.key} "
              "is gone",
        );
        return "connection closed before sending";
      }
      try {
        await relayManager.sendOrThrow(
          relay,
          ClientMsg(ClientMsgType.kReq, id: id, filters: request.filters),
        );
      } catch (e) {
        Logger.log.e(
          () => "COULD NOT SEND REQUEST TO ${request.url}:",
          error: e,
        );
        return "$e";
      }
      return null;
    } else {
      Logger.log.e(
        () =>
            "COULD NOT SEND REQUEST TO ${request.url} since socket seems to be not open",
      );
      return "could not connect";
    }
  }

  @override
  NdkBroadcastResponse handleEventBroadcast({
    required Nip01Event nostrEvent,
    required EventSigner? signer,
    required BroadcastState broadcastState,
    Iterable<String>? specificRelays,
  }) {
    unawaited(_broadcast(nostrEvent, signer, broadcastState, specificRelays));

    return NdkBroadcastResponse(
      publishEvent: nostrEvent,
      broadcastDoneStream: broadcastState.stateUpdates.map(
        (state) => state.broadcasts.values.toList(),
      ),
      broadcastDoneFuture: broadcastState.publishDoneFuture.then(
        (state) => state.broadcasts.values.toList(),
      ),
    );
  }

  Future<void> _broadcast(
    Nip01Event nostrEvent,
    EventSigner? signer,
    BroadcastState broadcastState,
    Iterable<String>? specificRelays,
  ) async {
    final Nip01Event workingEvent;
    try {
      workingEvent = signer != null
          ? await signer.sign(nostrEvent)
          : nostrEvent;
    } catch (e, stackTrace) {
      broadcastState.addError(e, stackTrace);
      return;
    }
    broadcastState.startTimeout();

    if (specificRelays != null) {
      await Future.wait(
        specificRelays.map(
          (relayUrl) =>
              doRelayBroadcast(relayUrl, workingEvent, broadcastState),
        ),
      );
    } else {
      await broadcastToDefaultRelays(workingEvent, broadcastState);
    }
    broadcastState.closeIfNoRelays();
  }

  /// Sends a broadcast that names no relay. Here it goes to the bootstrap
  /// relays; an engine with an outbox model overrides it.
  @protected
  Future<void> broadcastToDefaultRelays(
    Nip01Event event,
    BroadcastState broadcastState,
  ) => Future.wait(
    cleanRelayUrls(bootstrapRelays)
        .map((relayUrl) => doRelayBroadcast(relayUrl, event, broadcastState)),
  );

  /// Why [event] must not be sent after all, asked once a connection for it is
  /// open. Null sends it.
  @protected
  Future<String?> broadcastSkipReason(Nip01Event event) async => null;

  /// The flow:
  /// 1) register broadcast in relay manager's global state,
  ///     so that even failed to connect relays will be taken into account for broadcast done logic
  /// 2) make sure the relay is connected by calling reconnect
  /// 3) if connected was successfull send the event
  /// 4) otherwise call failBroadcast in order to publish a RelayBroadcastResponse
  ///   for that specific relay with an error message
  Future<void> doRelayBroadcast(
    String relayUrl,
    Nip01Event nostrEvent,
    BroadcastState broadcastState,
  ) async {
    final auth = broadcastState.auth;
    relayManager.registerRelayBroadcast(
      broadcastState: broadcastState,
      eventToPublish: nostrEvent,
      relayUrl: relayUrl,
    );

    RelayConnectivity? relayConnectivity;
    Object? error;
    try {
      relayConnectivity = await relayManager.connectionForBroadcast(
        relayUrl,
        auth,
        connectTimeout: 1,
        pausing: broadcastState,
      );
    } catch (e) {
      Logger.log.w(
        () => "Error during quick connect for $relayUrl in doRelayBroadcast",
        error: e,
      );
      error = e;
    }

    if (relayConnectivity != null) {
      final skipReason = await broadcastSkipReason(nostrEvent);
      if (skipReason != null) {
        Logger.log.d(
          () => 'skip broadcast ${nostrEvent.id} to $relayUrl: $skipReason',
        );
        relayManager.failBroadcast(broadcastState, relayUrl, skipReason);
        return;
      }

      await relayManager.sendOrThrow(
        relayConnectivity,
        ClientMsg(ClientMsgType.kEvent, event: nostrEvent),
      );
      return;
    }
    if (auth is AuthPolicyRequire) {
      relayManager.failBroadcast(
        broadcastState,
        relayUrl,
        "no connection bound to ${auth.account.pubkey} could be opened",
      );
      return;
    }
    relayManager.failBroadcast(
      broadcastState,
      relayUrl,
      "Could not connect to relay $relayUrl $error",
    );
  }
}
