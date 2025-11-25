part of 'websocket_isolate_nostr_transport.dart';

/// Singleton manager for the shared WebSocket isolate
class _WebSocketIsolateManager {
  static _WebSocketIsolateManager? _instance;
  static _WebSocketIsolateManager get instance {
    _instance ??= _WebSocketIsolateManager._();
    return _instance!;
  }

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  final ReceivePort _receivePort = ReceivePort();
  StreamSubscription? _receivePortSubscription;
  final Completer<void> _readyCompleter = Completer<void>();
  final Map<int, StreamController<NostrMessageRaw>> _connectionControllers = {};
  final Map<int, void Function(_IsolateMessageType)> _stateCallbacks = {};
  int _nextConnectionId = 0;

  _WebSocketIsolateManager._() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isolate = await Isolate.spawn(
        _isolateEntry,
        _receivePort.sendPort,
      );

      _receivePortSubscription = _receivePort.listen((message) {
        _handleIsolateMessage(message);
      });
    } catch (e) {
      Logger.log.e("Failed to spawn shared WebSocket isolate: $e");
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(e);
      }
    }
  }

  void _handleIsolateMessage(dynamic message) {
    if (message is _IsolateMessage) {
      final isolateMsg = message;
      final controller = _connectionControllers[isolateMsg.connectionId];
      if (controller == null) return;

      switch (isolateMsg.type) {
        case _IsolateMessageType.message:
          if (isolateMsg.data != null) {
            controller.add(isolateMsg.data!);
          }
          break;
        case _IsolateMessageType.error:
          if (isolateMsg.error != null) {
            controller.addError(isolateMsg.error!);
          }
          break;
        case _IsolateMessageType.done:
          if (!controller.isClosed) {
            controller.close();
          }
          break;
        case _IsolateMessageType.ready:
        case _IsolateMessageType.reconnecting:
          // Notify state change via callback
          final stateCallback = _stateCallbacks[isolateMsg.connectionId];
          if (stateCallback != null) {
            stateCallback(isolateMsg.type);
          }
          break;
      }
      return;
    }

    if (message is SendPort) {
      _isolateSendPort = message;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      return;
    }
  }

  int _registerConnection(
    StreamController<NostrMessageRaw> controller,
    void Function(_IsolateMessageType) onStateChange,
  ) {
    final id = _nextConnectionId++;
    _connectionControllers[id] = controller;
    _stateCallbacks[id] = onStateChange;
    return id;
  }

  void _unregisterConnection(int connectionId) {
    _connectionControllers.remove(connectionId);
    _stateCallbacks.remove(connectionId);
  }

  Future<void> get ready => _readyCompleter.future;

  void sendCommand(_IsolateCommand command) {
    if (_isolateSendPort != null) {
      _isolateSendPort!.send(command);
    }
  }

  Future<void> dispose() async {
    for (final controller in _connectionControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _connectionControllers.clear();
    _stateCallbacks.clear();

    await _receivePortSubscription?.cancel();
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _instance = null;
  }
}
