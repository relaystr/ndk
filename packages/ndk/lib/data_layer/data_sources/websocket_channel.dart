import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketChannelDS {
  final WebSocketChannel ws;
  final String url;

  final Completer<void> _readyCompleter = Completer<void>();

  WebsocketChannelDS(this.ws, this.url) {
    ws.ready.then((_) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    });
  }

  StreamSubscription<dynamic> listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    return ws.stream.listen(onData, onDone: onDone, onError: onError);
  }

  void send(dynamic data) {
    return ws.sink.add(data);
  }

  Future<void> close() {
    return ws.sink.close();
  }

  bool isOpen() {
    final rdy = _readyCompleter.isCompleted;
    final notClosed = ws.closeCode == null;
    return rdy && notClosed;
  }

  int? closeCode() {
    return ws.closeCode;
  }

  String? closeReason() {
    return ws.closeReason;
  }
}
