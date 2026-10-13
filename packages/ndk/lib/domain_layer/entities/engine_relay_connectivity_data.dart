import 'jit_engine_relay_connectivity_data.dart';

/// Per-connection data for the engines that share one connection pool.
///
/// The pool is keyed by relay url and identity, never by engine, so a socket
/// opened for one engine is handed to another whenever the other one already
/// needs that relay. A connection therefore has to carry the bookkeeping of
/// every engine that may be given it, which is what this composite is for:
/// adding an engine means adding a slot here, not a new type parameter on
/// [RelayConnectivity] and [RelayManager].
class EngineRelayConnectivityData {
  EngineRelayConnectivityData({JitEngineRelayConnectivityData? jit})
    : jit = jit ?? JitEngineRelayConnectivityData();

  /// JIT ranking and coverage bookkeeping.
  ///
  /// Always present: the JIT engine is installed in every engine mode, so any
  /// connection may end up being ranked by it.
  final JitEngineRelayConnectivityData jit;
}
