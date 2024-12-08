import 'read_write_marker.dart';

class JitEngineRelayConnectivityData {
  List<RelayJitAssignedPubkey> assignedPubkeys = [];

  /// gets incremented on every touch => search if it has a pubkey assigned
  int touched = 1;

  /// gets incremented when there is a pubkey match
  int touchUseful = 0;

  double get relayUsefulness => touchUseful / touched;

  /// adds pubkeys with a direction to assigned Pubkeys
  void addPubkeysToAssignedPubkeys(
      List<String> pubkeys, ReadWriteMarker direction) {
    for (var pubkey in pubkeys) {
      assignedPubkeys.add(RelayJitAssignedPubkey(pubkey, direction));
    }
  }
}

class RelayJitAssignedPubkey {
  final String pubkey;
  final ReadWriteMarker direction;

  RelayJitAssignedPubkey(this.pubkey, this.direction);
}
