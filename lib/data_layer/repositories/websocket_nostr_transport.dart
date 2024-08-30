import 'dart:async';

import '../../domain_layer/repositories/nostr_transport.dart';
import '../data_sources/websocket.dart';

class WebSocketNostrTransport implements NostrTransport {
  WebsocketDS websocketDS;

  WebSocketNostrTransport(this.websocketDS) {
    ready = websocketDS.ready();
  }

  @override
  late Future<void> ready;

  @override
  Future<void> close() {
    return websocketDS.close();
  }

  @override
  StreamSubscription listen(void Function(dynamic p1) onData,
      {Function? onError, void Function()? onDone}) {
    return websocketDS.listen(onData, onError: onError, onDone: onDone);
  }

  @override
  void send(data) {
    websocketDS.send(data);
  }

  @override
  bool isOpen() {
    return websocketDS.isOpen();
  }

  @override
  int? closeCode() {
    return websocketDS.closeCode();
  }

  @override
  String? closeReason() {
    return websocketDS.closeReason();
  }
}
