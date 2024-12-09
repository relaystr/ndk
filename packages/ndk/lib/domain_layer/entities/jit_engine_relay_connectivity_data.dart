import '../usecases/engines/network_engine.dart';
import 'read_write_marker.dart';

/// additional data for the JIT engine
class JitEngineRelayConnectivityData {
  List<RelayJitAssignedPubkey> assignedPubkeys = [];

  /// gets incremented on every touch => search if it has a pubkey assigned
  int touched = 1;

  /// gets incremented when there is a pubkey match
  int touchUseful = 0;

  /// describes how often the relay was used and returned something useful
  double get relayUsefulness => touchUseful / touched;

  /// adds pubkeys with a direction to assigned Pubkeys
  void addPubkeysToAssignedPubkeys(
      List<String> pubkeys, ReadWriteMarker direction) {
    for (var pubkey in pubkeys) {
      assignedPubkeys.add(RelayJitAssignedPubkey(pubkey, direction));
    }
  }
}

/// Represents a relay jit assigned pubkey
class RelayJitAssignedPubkey {
  /// hex pubkey
  final String pubkey;

  /// direction the assignment
  final ReadWriteMarker direction;

  /// Creates a new relay jit assigned pubkey
  RelayJitAssignedPubkey(this.pubkey, this.direction);
}

/// Factory for creating additional data for the engine
class JitEngineRelayConnectivityDataFactory
    implements EngineAdditionalDataFactory<JitEngineRelayConnectivityData> {
  @override
  JitEngineRelayConnectivityData call() {
    // create a new instance of the data
    return JitEngineRelayConnectivityData();
  }
}
