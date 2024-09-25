import 'dart:async';

import '../../../domain_layer/repositories/nostr_transport.dart';
import '../../data_sources/websocket.dart';

class WebSocketNostrTransport implements NostrTransport {
  final WebsocketDS _websocketDS;

  WebSocketNostrTransport(this._websocketDS) {
    ready = _websocketDS.ready();
  }

  @override
  late Future<void> ready;

  @override
  Future<void> close() {
    return _websocketDS.close();
  }

  @override
  StreamSubscription listen(void Function(dynamic p1) onData,
      {Function? onError, void Function()? onDone}) {
    return _websocketDS.listen(onData, onError: onError, onDone: onDone);
  }

  @override
  void send(data) {
    _websocketDS.send(data);
  }

  @override
  bool isOpen() {
    return _websocketDS.isOpen();
  }

  @override
  int? closeCode() {
    return _websocketDS.closeCode();
  }

  @override
  String? closeReason() {
    return _websocketDS.closeReason();
  }
}
