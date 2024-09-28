import 'dart:async';

import '../../../domain_layer/repositories/nostr_transport.dart';
import '../../data_sources/websocket.dart';

/// A WebSocket-based implementation of the NostrTransport interface.
///
/// This class provides a WebSocket transport layer for Nostr protocol
/// communications, wrapping a WebsocketDS instance to handle the underlying
/// WebSocket operations.
class WebSocketNostrTransport implements NostrTransport {
  /// The underlying WebSocket data source.
  final WebsocketDS _websocketDS;

  /// Creates a new WebSocketNostrTransport instance.
  ///
  /// [_websocketDS] is the WebSocket data source to be used for communication.
  WebSocketNostrTransport(this._websocketDS) {
    ready = _websocketDS.ready();
  }

  /// A Future that completes when the WebSocket connection is ready.
  @override
  late Future<void> ready;

  /// Closes the WebSocket connection.
  ///
  /// Returns a Future that completes when the connection has been closed.
  @override
  Future<void> close() {
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
