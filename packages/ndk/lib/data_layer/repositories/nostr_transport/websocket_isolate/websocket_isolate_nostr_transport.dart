import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:ndk/domain_layer/repositories/nostr_transport.dart';
import 'package:ndk/shared/logger/logger.dart';

import 'package:web_socket_client/web_socket_client.dart';

enum NostrMessageRawType {
  notice,
  event,
  eose,
  ok,
  closed,
  auth,
  unknown,
}

// needed until Nip01Event is refactored to be immutable
class Nip01EventRaw {
  final String id;

  final String pubKey;

  final int createdAt;

  final int kind;

  final List<List<String>> tags;

  final String content;

  final String sig;

  Nip01EventRaw({
    required this.id,
    required this.pubKey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });
}

class NostrMessageRaw {
  final NostrMessageRawType type;
  final Nip01EventRaw? nip01Event;
  final String? requestId;
  final dynamic otherData;

  NostrMessageRaw({
    required this.type,
    this.nip01Event,
    this.requestId,
    this.otherData,
  });
}

/// Message types for isolate communication
enum _IsolateMessageType {
  ready,
  reconnecting,
  message,
  error,
  done,
}

/// Internal message class for communication between main isolate and worker isolate
class _IsolateMessage {
  final int connectionId;
  final _IsolateMessageType type;
  final NostrMessageRaw? data;
  final String? error;
  final int? closeCode;
  final String? closeReason;

  _IsolateMessage({
    required this.connectionId,
    required this.type,
    this.data,
    this.error,
    this.closeCode,
    this.closeReason,
  });
}

/// Base class for commands sent from main isolate to worker isolate
abstract class _IsolateCommand {
  final int connectionId;

  _IsolateCommand({required this.connectionId});
}

class _ConnectCommand extends _IsolateCommand {
  final String url;

  _ConnectCommand({required super.connectionId, required this.url});
}

class _SendCommand extends _IsolateCommand {
  final dynamic data;

  _SendCommand({required super.connectionId, required this.data});
}

class _CloseCommand extends _IsolateCommand {
  _CloseCommand({required super.connectionId});
}

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

      _receivePort.listen((message) {
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
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _instance = null;
  }
}

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

class _WebSocketIsolateWorker {
  final SendPort _mainSendPort;
  final ReceivePort _receivePort = ReceivePort();
  final Map<int, WebSocket> _connections = {};

  _WebSocketIsolateWorker(this._mainSendPort) {
    _mainSendPort.send(_receivePort.sendPort);
    _receivePort.listen(_handleCommand);
  }

  void _handleCommand(dynamic message) {
    if (message is _ConnectCommand) {
      _connect(message.connectionId, message.url);
    } else if (message is _SendCommand) {
      _connections[message.connectionId]?.send(message.data);
    } else if (message is _CloseCommand) {
      _connections[message.connectionId]?.close();
      _connections.remove(message.connectionId);
    }
  }

  void _connect(int connectionId, String url) async {
    final backoff = BinaryExponentialBackoff(
      initial: Duration(seconds: 1),
      maximumStep: 10,
    );

    final webSocket = WebSocket(Uri.parse(url), backoff: backoff);
    _connections[connectionId] = webSocket;

    webSocket.connection.listen(
      (state) {
        if (state is Connected) {
          _mainSendPort.send(
            _IsolateMessage(
              connectionId: connectionId,
              type: _IsolateMessageType.ready,
            ),
          );
        } else if (state is Reconnecting) {
          _mainSendPort.send(
            _IsolateMessage(
              connectionId: connectionId,
              type: _IsolateMessageType.reconnecting,
            ),
          );
        } else if (state is Disconnected) {
          _mainSendPort.send(
            _IsolateMessage(
              connectionId: connectionId,
              type: _IsolateMessageType.done,
              closeCode: null,
              closeReason: 'Disconnected',
            ),
          );
        }
      },
      onError: (error) {
        _mainSendPort.send(
          _IsolateMessage(
            connectionId: connectionId,
            type: _IsolateMessageType.error,
            error: error.toString(),
          ),
        );
      },
    );

    webSocket.messages.listen(
      (message) {
        final eventJson = json.decode(message);
        final NostrMessageRaw data;

        switch (eventJson[0]) {
          case 'NOTICE':
            data = NostrMessageRaw(
              type: NostrMessageRawType.notice,
              otherData: eventJson,
            );
            break;
          case 'EVENT':
            Nip01EventRaw? nip01Event;
            try {
              final eventData = eventJson[2];
              nip01Event = Nip01EventRaw(
                id: eventData['id'],
                pubKey: eventData['pubkey'],
                createdAt: eventData['created_at'],
                kind: eventData['kind'],
                tags: List<List<String>>.from(
                  (eventData['tags'] as List).map(
                    (tag) => List<String>.from(tag),
                  ),
                ),
                content: eventData['content'],
                sig: eventData['sig'],
              );
            } catch (e) {
              nip01Event = null;
            }

            data = NostrMessageRaw(
              type: NostrMessageRawType.event,
              requestId: eventJson[1],
              nip01Event: nip01Event,
              otherData: nip01Event == null ? eventJson : null,
            );

            break;
          case 'EOSE':
            data = NostrMessageRaw(
                type: NostrMessageRawType.eose, otherData: eventJson);
            break;
          case 'OK':
            data = NostrMessageRaw(
              type: NostrMessageRawType.ok,
              otherData: eventJson,
            );
            break;
          case 'CLOSED':
            data = NostrMessageRaw(
              type: NostrMessageRawType.closed,
              otherData: eventJson,
            );
            break;
          case 'AUTH':
            data = NostrMessageRaw(
              type: NostrMessageRawType.auth,
              otherData: eventJson,
            );
            break;
          default:
            data = NostrMessageRaw(
              type: NostrMessageRawType.unknown,
              otherData: eventJson,
            );
            break;
        }

        _mainSendPort.send(
          _IsolateMessage(
            connectionId: connectionId,
            type: _IsolateMessageType.message,
            data: data,
          ),
        );
      },
      onError: (error) {
        _mainSendPort.send(
          _IsolateMessage(
            connectionId: connectionId,
            type: _IsolateMessageType.error,
            error: error.toString(),
          ),
        );
      },
      onDone: () {
        _mainSendPort.send(
          _IsolateMessage(
            connectionId: connectionId,
            type: _IsolateMessageType.done,
            closeCode: null,
            closeReason: "Done",
          ),
        );
        _connections.remove(connectionId);
      },
    );
  }
}
