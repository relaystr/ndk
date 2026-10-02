import '../../entities/broadcast_response.dart';
import '../../entities/broadcast_state.dart';
import '../../entities/global_state.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/ndk_request.dart';
import '../../entities/relay_set.dart';
import '../../entities/request_state.dart';
import '../../repositories/event_signer.dart';
import 'network_engine.dart';

/// Routes each request to the engine that suits it, over one shared pool.
///
/// A request that names a [RelaySet] already knows which relays should serve
/// it, so the relay sets engine takes it. Everything else is resolved on the
/// fly by the JIT engine, which ranks relays from nip65 data as it goes.
///
/// Both engines run on the same [GlobalState.relays] pool, keyed by relay url
/// and identity. A socket opened for one engine is therefore reused by the
/// other whenever it already needs that relay: no engine opens a second
/// connection to a relay the pool already holds.
class CombinedEngine implements NetworkEngine {
  /// serves requests that did not name a relay set
  final NetworkEngine jitEngine;

  /// serves requests that did
  final NetworkEngine relaySetEngine;

  CombinedEngine({required this.jitEngine, required this.relaySetEngine});

  /// Which engine serves [request].
  ///
  /// A relay set is an explicit statement of where a request should go and
  /// takes precedence over anything an engine would have picked on its own.
  NetworkEngine engineFor(NdkRequest request) =>
      request.relaySet == null ? jitEngine : relaySetEngine;

  @override
  void handleRequest(RequestState state) {
    engineFor(state.request).handleRequest(state);
  }

  /// Broadcasts carry no relay set: the engine that resolves relays per
  /// request has nothing to pick from, so the JIT engine, which does the
  /// inbox/outbox gossip from nip65 data, always serves them.
  @override
  NdkBroadcastResponse handleEventBroadcast({
    required Nip01Event nostrEvent,
    required EventSigner? signer,
    required BroadcastState broadcastState,
    Iterable<String>? specificRelays,
  }) => jitEngine.handleEventBroadcast(
    nostrEvent: nostrEvent,
    signer: signer,
    broadcastState: broadcastState,
    specificRelays: specificRelays,
  );
}
