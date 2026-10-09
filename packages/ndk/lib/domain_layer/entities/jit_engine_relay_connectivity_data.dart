import 'read_write_marker.dart';

/// additional data for the JIT engine
class JitEngineRelayConnectivityData {
  List<RelayJitAssignedPubkey> assignedPubkeys = [];

  /// adds pubkeys with a direction to assigned Pubkeys
  void addPubkeysToAssignedPubkeys(
    List<String> pubkeys,
    ReadWriteMarker direction,
  ) {
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
