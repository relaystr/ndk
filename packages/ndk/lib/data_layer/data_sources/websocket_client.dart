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
    return ws.messages.listen(onData, onDone: onDone, onError: onError);
  }

  void send(dynamic data) {
    return ws.send(data);
  }

  void close() {
    return ws.close();
  }

  bool isOpen() {
    final state = ws.connection.state;
    return state is Connected || state is Reconnected;
  }

  bool isConnecting() {
    return ws.connection.state == Connecting() ||
        ws.connection.state == Reconnecting();
  }

  int? closeCode() {
    final state = ws.connection.state;
    return state is Disconnected ? state.code : null;
  }

  String? closeReason() {
    final state = ws.connection.state;
    return state is Disconnected ? state.reason : null;
  }
}
// coverage:ignore-end
