import 'package:dart_ndk/nips/nip01/client_msg.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';

class RelayJit extends Relay {
  RelayJit(String url) : super(url);

  /// used to lookup if this relay is suitable for a given request
  List<RelayJitAssignedPubkey> assignedPubkeys = [];

  /// all active subscriptions on this relay, id is the subscription id
  Map<String, RelayActiveSubscription> activeSubscriptions = {};

  /// gets incremented on every touch => search if it has a pubkey assigned
  int touched = 0;

  /// gets incremented when there is a pubkey match
  int touchUseful = 0;

  double get relayUsefulness => touchUseful / touched;

  send(ClientMsg msg) {
    dynamic msgToSend = msg.toJson();

    //todo: implement sending
    throw Exception("Sending - websocket not implemented yet");
  }

  // check if active relay subscriptions does already exist
  bool hasActiveSubscription(String id) {
    return activeSubscriptions.containsKey(id);
  }
}

class RelayJitAssignedPubkey {
  final String pubkey;
  final ReadWriteMarker direction;

  RelayJitAssignedPubkey(this.pubkey, this.direction);
}

class RelayActiveSubscription {
  final String id; // id of the original request
  final NostrRequestJit originalRequest;
  List<Filter> filters; // list of split filters

  RelayActiveSubscription(this.id, this.filters, this.originalRequest);
}
