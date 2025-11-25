import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:web_socket_client/web_socket_client.dart';

import '../../../../domain_layer/repositories/nostr_transport.dart';
import '../../../../shared/logger/logger.dart';

part 'websocket_isolate_entities.dart';
part 'websocket_isolate_nostr_transport_worker.dart';
part 'websocket_isolate_nostr_transport_manager.dart';

class WebSocketIsolateNostrTransport implements NostrTransport {
  final String url;
  final Function? onReconnect;
  final Completer<void> _readyCompleter = Completer<void>();
  final StreamController<NostrMessageRaw> _messageController =
      StreamController<NostrMessageRaw>.broadcast();

  late final int _connectionId;
  final _WebSocketIsolateManager _manager = _WebSocketIsolateManager.instance;

  int? _closeCode;
  String? _closeReason;
  bool _isOpen = false;
  bool _isInitialized = false;

  WebSocketIsolateNostrTransport(this.url, this.onReconnect) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _manager.ready;

      _connectionId = _manager._registerConnection(
        _messageController,
        (state) {
          // Handle state changes from isolate
          switch (state) {
            case _IsolateMessageType.ready:
              _isOpen = true;
              if (!_readyCompleter.isCompleted) {
                _readyCompleter.complete();
              }
              break;
            case _IsolateMessageType.reconnecting:
              Logger.log.i("WebSocket reconnecting: $url");
              if (onReconnect != null) {
                onReconnect!();
              }
              break;
            case _IsolateMessageType.done:
              _isOpen = false;
              break;
            case _IsolateMessageType.message:
            case _IsolateMessageType.error:
              break;
          }
        },
      );

      _manager.sendCommand(
        _ConnectCommand(
          connectionId: _connectionId,
          url: url,
        ),
      );
    } catch (e) {
      Logger.log.e("Failed to initialize WebSocket for $url: $e");
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(e);
      }
    }
  }

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  bool isOpen() => _isOpen;

  @override
  int? closeCode() => _closeCode;

  @override
  String? closeReason() => _closeReason;

  @override
  void send(dynamic data) {
    if (_isOpen) {
      _manager.sendCommand(
        _SendCommand(
          connectionId: _connectionId,
          data: data,
        ),
      );
    } else {
      Logger.log.w("Attempted to send on closed/unready WebSocket: $url");
    }
  }

  @override
  Future<void> close() async {
    _manager.sendCommand(
      _CloseCommand(
        connectionId: _connectionId,
      ),
    );

    await Future.delayed(Duration(milliseconds: 100));

    _manager._unregisterConnection(_connectionId);

    if (!_messageController.isClosed) {
      await _messageController.close();
    }
  }

  @override
  StreamSubscription<dynamic> listen(
    void Function(NostrMessageRaw) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    return _messageController.stream
        .listen(onData, onError: onError, onDone: onDone);
  }

  @override
  set ready(Future<void> value) {
    // No-op: ready is managed internally.
  }
}

void _isolateEntry(SendPort mainSendPort) {
  _WebSocketIsolateWorker(mainSendPort);
}
