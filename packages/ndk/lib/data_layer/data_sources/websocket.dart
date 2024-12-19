import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

// coverage:ignore-start

/// Data source for making websocket requests
class WebsocketDS {
  /// the websocket channel
  final WebSocketChannel webSocketChannel;

  /// create new instance of WebsocketDS
  WebsocketDS(this.webSocketChannel);

  /// listen to the websocket channel
  StreamSubscription<dynamic> listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    return webSocketChannel.stream
        .listen(onData, onDone: onDone, onError: onError);
  }

  /// send data to the websocket channel
  void send(dynamic data) {
    return webSocketChannel.sink.add(data);
  }

  /// signal that the websocket is ready
  Future<void> ready() {
    return webSocketChannel.ready;
  }

  /// close the websocket
  Future<void> close() {
    return webSocketChannel.sink.close();
  }

  /// check if the websocket is open
  bool isOpen() {
    return webSocketChannel.closeCode == null;
  }

  /// get the close code
  int? closeCode() {
    return webSocketChannel.closeCode;
  }

  /// get the close reason
  String? closeReason() {
    return webSocketChannel.closeReason;
  }
}
// coverage:ignore-end
