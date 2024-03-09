import 'package:dart_ndk/nips/nip01/client_msg.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

  WebSocketChannel? _channel;

  Future<bool> connect() {
    String? cleanUrl = Relay.cleanUrl(url);
    if (cleanUrl == null) {
      throw Exception("Invalid url");
    }
    _channel = WebSocketChannel.connect(Uri.parse(cleanUrl));
    return isReady();
  }

  Future<dynamic> disconnect() {
    if (_channel == null) {
      return Future.value(false);
    }
    return _channel!.sink.close();
  }

  Future<bool> isReady() async {
    if (_channel == null) {
      return false;
    }
    await _channel!.ready;
    return _channel!.closeCode == null;
  }

  send(ClientMsg msg) async {
    bool rdy = await isReady();
    if (!rdy) {
      throw Exception("Websocket not ready, unable to send message");
    }

    dynamic msgToSend = msg.toJson();
    _channel!.sink.add(msgToSend);
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
