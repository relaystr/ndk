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
  final Map<String, StreamController<NostrMessageRaw>> _connectionControllers =
      {};
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
    if (message is SendPort) {
      _isolateSendPort = message;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      return;
    }

    if (message is Map<String, dynamic>) {
      final connectionId = message['connectionId'] as String?;
      if (connectionId == null) return;

      final controller = _connectionControllers[connectionId];
      if (controller == null) return;

      switch (message['type']) {
        case 'message':
          controller.add(message['data']);
          break;
        case 'error':
          controller.addError(message['error']);
          break;
        case 'done':
          if (!controller.isClosed) {
            controller.close();
          }
          break;
      }
    }
  }

  String _registerConnection(StreamController<NostrMessageRaw> controller) {
    final id = 'conn_${_nextConnectionId++}';
    _connectionControllers[id] = controller;
    return id;
  }

  void _unregisterConnection(String connectionId) {
    _connectionControllers.remove(connectionId);
  }

  Future<void> get ready => _readyCompleter.future;

  void sendCommand(String connectionId, Map<String, dynamic> command) {
    if (_isolateSendPort != null) {
      _isolateSendPort!.send({
        'connectionId': connectionId,
        ...command,
      });
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

  late final String _connectionId;
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

      _connectionId = _manager._registerConnection(_messageController);

      // Listen to messages for connection state changes
      _messageController.stream.listen(
        (message) {
          // Check for ready/reconnecting messages
          if (message.type == NostrMessageRawType.unknown &&
              message.otherData is Map<String, dynamic>) {
            final data = message.otherData as Map<String, dynamic>;
            if (data['_state'] == 'ready') {
              _isOpen = true;
              if (!_readyCompleter.isCompleted) {
                _readyCompleter.complete();
              }
            } else if (data['_state'] == 'reconnecting') {
              Logger.log.i("WebSocket reconnecting: $url");
              if (onReconnect != null) {
                onReconnect!();
              }
            }
          }
        },
        onDone: () {
          _isOpen = false;
        },
      );

      _manager.sendCommand(_connectionId, {
        'command': 'connect',
        'url': url,
      });
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
      _manager.sendCommand(_connectionId, {
        'command': 'send',
        'data': data,
      });
    } else {
      Logger.log.w("Attempted to send on closed/unready WebSocket: $url");
    }
  }

  @override
  Future<void> close() async {
    _manager.sendCommand(_connectionId, {
      'command': 'close',
    });

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
  final Map<String, WebSocket> _connections = {};

  _WebSocketIsolateWorker(this._mainSendPort) {
    _mainSendPort.send(_receivePort.sendPort);
    _receivePort.listen(_handleCommand);
  }

  void _handleCommand(dynamic message) {
    if (message is! Map<String, dynamic>) return;

    final connectionId = message['connectionId'] as String?;
    if (connectionId == null) return;

    final command = message['command'] as String?;

    switch (command) {
      case 'connect':
        final url = message['url'] as String?;
        if (url != null) {
          _connect(connectionId, url);
        }
        break;
      case 'send':
        final data = message['data'];
        _connections[connectionId]?.send(data);
        break;
      case 'close':
        _connections[connectionId]?.close();
        _connections.remove(connectionId);
        break;
    }
  }

  void _connect(String connectionId, String url) async {
    final backoff = BinaryExponentialBackoff(
      initial: Duration(seconds: 1),
      maximumStep: 10,
    );

    final webSocket = WebSocket(Uri.parse(url), backoff: backoff);
    _connections[connectionId] = webSocket;

    webSocket.connection.listen(
      (state) {
        if (state is Connected) {
          _mainSendPort.send({
            'connectionId': connectionId,
            'type': 'message',
            'data': NostrMessageRaw(
              type: NostrMessageRawType.unknown,
              otherData: {'_state': 'ready'},
            ),
          });
        } else if (state is Reconnecting) {
          _mainSendPort.send({
            'connectionId': connectionId,
            'type': 'message',
            'data': NostrMessageRaw(
              type: NostrMessageRawType.unknown,
              otherData: {'_state': 'reconnecting'},
            ),
          });
        } else if (state is Disconnected) {
          _mainSendPort.send({
            'connectionId': connectionId,
            'type': 'done',
            'closeCode': null,
            'closeReason': 'Disconnected',
          });
        }
      },
      onError: (error) {
        _mainSendPort.send({
          'connectionId': connectionId,
          'type': 'error',
          'error': error.toString(),
        });
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

        _mainSendPort.send({
          'connectionId': connectionId,
          'type': 'message',
          'data': data,
        });
      },
      onError: (error) {
        _mainSendPort.send({
          'connectionId': connectionId,
          'type': 'error',
          'error': error.toString(),
        });
      },
      onDone: () {
        _mainSendPort.send({
          'connectionId': connectionId,
          'type': 'done',
          'closeCode': null,
          'closeReason': "Done",
        });
        _connections.remove(connectionId);
      },
    );
  }
}
