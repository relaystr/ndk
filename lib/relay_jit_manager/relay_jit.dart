import 'dart:convert';

import 'package:dart_ndk/nips/nip01/client_msg.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';
import 'package:logger/logger.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

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

  /// returns true if the connection was successful
  Future<bool> connect() async {
    if (_channel != null) {
      logger.w("Relay already connected");
      return Future.value(true);
    }

    String? cleanUrl = Relay.cleanUrl(url);
    if (cleanUrl == null) {
      logger.w("invalid url $url => $cleanUrl");
      return false;
    }
    _channel = WebSocketChannel.connect(Uri.parse(cleanUrl));

    // ready check
    bool r = await isReady();
    if (!r) {
      logger.w("Relay not ready");
      return false;
    }

    _listen();
    logger.i("Relay connected: $url");
    return true;
  }

  _listen() {
    _channel!.stream.listen((event) {
      logger.i("Received message on $url: $event");
      if (event is! String) {
        logger.w("Received message is not a string: $event");
        return;
      }
      List<dynamic> eventJson = jsonDecode(event);

      if (eventJson[0] == 'EVENT') {
        return;
      }

      switch (eventJson[0]) {
        case 'EVENT':
          _handleIncomingEvent(eventJson);
          break;
        case 'OK':
          //["OK", <event_id>, <true|false>, <message>]
          logger.i("OK received: $eventJson");
          logger.f("OK not implemented! ");
          break;
        case 'EOSE':
          //["EOSE", <subscription_id>]
          logger.i("EOSE received, $eventJson");
          logger.f("EOSE not implemented!");
          break;

        case 'CLOSED':
          //["CLOSED", <subscription_id>, <message>]
          logger.i("CLOSED received: $eventJson");
          logger.f("EOSE not implemented!");
          break;

        case 'NOTICE':
          //["NOTICE", <message>]
          logger.i("NOTICE received: $eventJson");
          logger.f("NOTICE not implemented!");
          break;

        default:
          logger.w("Unknown message type: ${eventJson[0]}: $eventJson");
      }
    });
  }

  void _handleIncomingEvent(List<dynamic> eventJson) {
    Nip01Event msg = Nip01Event.fromJson(eventJson[2]);
    String msgId = eventJson[1];
    if (activeSubscriptions.containsKey(msgId)) {
      activeSubscriptions[msgId]!.originalRequest.onMessage(msg);
    }
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
    logger.i("send message to $url: $msgToSend");
  }

  // check if active relay subscriptions does already exist
  bool hasActiveSubscription(String id) {
    return activeSubscriptions.containsKey(id);
  }

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

class RelayActiveSubscription {
  final String id; // id of the original request
  final NostrRequestJit originalRequest;
  List<Filter> filters; // list of split filters

  RelayActiveSubscription(this.id, this.filters, this.originalRequest);
}
