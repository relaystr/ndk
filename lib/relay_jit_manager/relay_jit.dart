import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';

class RelayJit extends Relay {
  RelayJit(String url) : super(url);

  /// used to lookup if this relay is suitable for a given request
  List<RelayJitAssignedPubkey> assignedPubkeys = [];

  /// all active subscriptions on this relay
  List<WIPSubscription> activeSubscriptions = [];

  /// gets incremented on every touch => search if it has a pubkey assigned
  int touched = 0;

  /// gets incremented when there is a pubkey match
  int touchUseful = 0;

  double get relayUsefulness => touchUseful / touched;
}

class RelayJitAssignedPubkey {
  final String pubkey;
  final ReadWriteMarker direction;

  RelayJitAssignedPubkey(this.pubkey, this.direction);
}

// todo: just a placeholder
class WIPSubscription {}
