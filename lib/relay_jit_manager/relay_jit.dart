import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';

class RelayJit extends Relay {
  RelayJit(String url) : super(url);

  /// used to lookup if this relay is suitable for a given request
  List<RelayJitAssignedPubkey> assignedPubkeys = [];
}

class RelayJitAssignedPubkey {
  final String pubkey;
  final ReadWriteMarker direction;

  RelayJitAssignedPubkey(this.pubkey, this.direction);
}
