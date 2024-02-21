import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit.dart';
import 'package:dart_ndk/request.dart';

List<Relay> SEED_RELAYs = [
  Relay('wss://relay.camelus.app'),
  Relay('wss://relay.snort.social'),
  Relay('wss://relay.damus.io'),
  Relay('wss://nostr.lu.ke'),
  Relay('wss://relay.mostr.pub')
];

class RelayJitManager {
  List<RelayJit> connectedRelays = [];

  /// If you request anything from the nostr network put it here and
  /// the relay jit manager will try to find the right relay and use it
  /// if no relay is found the request will be blasted to all connected relays (on start seed Relays)
  handleRequest(NostrRequest request, {desiredCoverage = 2}) {}

  doesRelayCoverPubkey(
      RelayJit relay, String pubkey, ReadWriteMarker direction) {
    for (RelayJitAssignedPubkey assignedPubkey in relay.assignedPubkeys) {
      if (assignedPubkey.pubkey == pubkey) {
        switch (direction) {
          case ReadWriteMarker.readOnly:
            return assignedPubkey.direction.isRead;
          case ReadWriteMarker.writeOnly:
            return assignedPubkey.direction.isWrite;
          case ReadWriteMarker.readWrite:
            return assignedPubkey.direction == ReadWriteMarker.readWrite;
          default:
            return false;
        }
      }
    }
    return false;
  }
}
