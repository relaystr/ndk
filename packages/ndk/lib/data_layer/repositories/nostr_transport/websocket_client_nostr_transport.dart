import 'dart:async';

import 'package:web_socket_client/web_socket_client.dart';

import '../../../domain_layer/repositories/nostr_transport.dart';
import '../../../shared/logger/logger.dart';
import '../../data_sources/websocket_channel.dart';
import '../../data_sources/websocket_client.dart';

/// A WebSocket-based implementation of the NostrTransport interface.
///
/// This class provides a WebSocket transport layer for Nostr protocol
/// communications, wrapping a WebsocketDS instance to handle the underlying
/// WebSocket operations.
class WebSocketClientNostrTransport implements NostrTransport {
  /// The underlying WebSocket data source.
  final WebsocketDSClient _websocketDS;
  late StreamSubscription<ConnectionState> _stateStreamSubscription;

  /// Creates a new WebSocketNostrTransport instance.
  ///
  /// [_websocketDS] is the WebSocket data source to be used for communication.
  WebSocketClientNostrTransport(this._websocketDS, [Function? onReconnect]) {
    Completer completer = Completer();
    ready = completer.future;

    ///! this code is causing the performance issue, or upstream by onReconnect()
    // _stateStreamSubscription = _websocketDS.ws.connection.listen((state) {
    //   Logger.log.t("${_websocketDS.url} connection state changed to $state");
    //   if (state is Connected || state is Reconnected) {
    //     if (!completer.isCompleted) {
    //       completer.complete();
    //     }
    //     if (state is Reconnected && onReconnect != null) {
    //       onReconnect.call();
    //     }
    //   } else if (state is Disconnected) {
    //     completer = Completer();
    //     ready = completer.future;
    //   } else if (state is Connecting || state is Reconnecting) {
    //     // Do nothing, just waiting for (re)connection to be established
    //   } else {
    //     Logger.log.w(
    //         "${_websocketDS.url} connection state changed to unknown state: $state");
    //   }
    // });
  }

  /// A Future that completes when the WebSocket connection is ready.
  @override
  late Future<void> ready;

  /// Closes the WebSocket connection.
  ///
  /// Returns a Future that completes when the connection has been closed.
  @override
  Future<void> close() async {
    await _stateStreamSubscription.cancel();
    return _websocketDS.close();
  }

  /// Listens for data on the WebSocket connection.
  ///
  /// [onData] is called whenever data is received.
  /// [onError] is called if an error occurs (optional).
  /// [onDone] is called when the stream is closed (optional).
  ///
  /// Returns a StreamSubscription that can be used to control the subscription.
  @override
  StreamSubscription listen(void Function(dynamic p1) onData,
      {Function? onError, void Function()? onDone}) {
    return _websocketDS.listen(onData, onError: onError, onDone: onDone);
  }

  /// Sends data through the WebSocket connection.
  ///
  /// [data] is the data to be sent.
  @override
  void send(data) {
    _websocketDS.send(data);
  }

  /// Checks if the WebSocket connection is currently open.
  ///
  /// Returns true if the connection is open, false otherwise.
  @override
  bool isOpen() {
    return _websocketDS.isOpen();
  }

  /// Gets the close code of the WebSocket connection.
  ///
  /// Returns the close code if the connection has been closed, null otherwise.
  @override
  int? closeCode() {
    return _websocketDS.closeCode();
  }

  /// Gets the close reason of the WebSocket connection.
  ///
  /// Returns the close reason if the connection has been closed, null otherwise.
  @override
  String? closeReason() {
    return _websocketDS.closeReason();
  }
}
