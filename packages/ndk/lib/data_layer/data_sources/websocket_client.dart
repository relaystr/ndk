import 'dart:async';

import 'package:web_socket_client/web_socket_client.dart';

// coverage:ignore-start
class WebsocketDSClient {
  final WebSocket ws;
  final String url;

  WebsocketDSClient(this.ws, this.url);

  StreamSubscription<dynamic> listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    return ws.messages
        .listen(onData, onDone: onDone, onError: onError);
  }

  void send(dynamic data) {
    return ws.send(data);
  }

  void close() {
    return ws.close();
  }

  bool isOpen() {
    return ws.connection.state == Connected() || ws.connection.state == Reconnected;
  }

  int? closeCode() {
    return ws.connection.state == Disconnected ? (ws.connection.state as Disconnected).code : null;
  }

  String? closeReason() {
    return ws.connection.state == Disconnected ? (ws.connection.state as Disconnected).reason : null;
  }
}
// coverage:ignore-end
