import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

// coverage:ignore-start

/// Data source for making websocket requests
class WebsocketDS {
  /// the websocket channel
  final WebSocketChannel webSocketChannel;

  bool _ready = false;
  bool _readySettled = false;
  bool _ended = false;

  /// create new instance of WebsocketDS
  WebsocketDS(this.webSocketChannel) {
    webSocketChannel.ready.then(
      (_) {
        _ready = true;
        _readySettled = true;
      },
      onError: (_) {
        _readySettled = true;
      },
    );
  }

  /// listen to the websocket channel
  StreamSubscription<dynamic> listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    return webSocketChannel.stream.listen(
      onData,
      onDone: () {
        _ended = true;
        onDone?.call();
      },
      onError: onError,
    );
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
    // a local close never ends the channel's stream
    _ended = true;
    return webSocketChannel.sink.close();
  }

  /// check if the websocket is open
  bool isOpen() {
    return _ready && !_ended;
  }

  /// check if the websocket is still connecting
  bool isConnecting() {
    return !_readySettled && !_ended;
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
