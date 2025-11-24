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

class WebSocketIsolateNostrTransport implements NostrTransport {
  final String url;
  final Function? onReconnect;
  final Completer<void> _readyCompleter = Completer<void>();
  final StreamController<NostrMessageRaw> _messageController =
      StreamController<NostrMessageRaw>.broadcast();

  late final ReceivePort _receivePort;
  SendPort? _isolateSendPort;
  Isolate? _isolate;

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

    _receivePort = ReceivePort();

    try {
      _isolate = await Isolate.spawn(
        _isolateEntry,
        _IsolateStartupData(
          sendPort: _receivePort.sendPort,
          url: url,
        ),
      );

      _receivePort.listen((message) {
        _handleIsolateMessage(message);
      });
    } catch (e) {
      Logger.log.e("Failed to spawn isolate for $url: $e");
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(e);
      }
    }
  }

  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
      return;
    }

    if (message is Map<String, dynamic>) {
      switch (message['type']) {
        case 'ready':
          _isOpen = true;
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete();
          }
          break;

        case 'message':
          // Message is raw string from WebSocket
          _messageController.add(message['data']);
          break;

        case 'reconnecting':
          Logger.log.i("WebSocket reconnecting: $url");
          if (onReconnect != null) {
            onReconnect!();
          }
          break;

        case 'error':
          Logger.log.e("WebSocket error from isolate: ${message['error']}");
          _messageController.addError(message['error']);
          break;

        case 'done':
          _closeCode = message['closeCode'];
          _closeReason = message['closeReason'];
          _isOpen = false;
          if (!_messageController.isClosed) {
            _messageController.close();
          }
          break;
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
    if (_isolateSendPort != null && _isOpen) {
      _isolateSendPort!.send({
        'command': 'send',
        'data': data,
      });
    } else {
      Logger.log.w("Attempted to send on closed/unready WebSocket: $url");
    }
  }

  @override
  Stream<NostrMessageRaw> get stream => _messageController.stream;

  @override
  Future<void> close() async {
    if (_isolateSendPort != null) {
      _isolateSendPort!.send({'command': 'close'});
    }

    await Future.delayed(Duration(milliseconds: 100));

    if (!_messageController.isClosed) {
      await _messageController.close();
    }
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
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

class _IsolateStartupData {
  final SendPort sendPort;
  final String url;

  _IsolateStartupData({
    required this.sendPort,
    required this.url,
  });
}

void _isolateEntry(_IsolateStartupData startupData) {
  _WebSocketIsolateWorker(startupData.sendPort, startupData.url);
}

class _WebSocketIsolateWorker {
  final SendPort _sendPort;
  final String _url;
  late final ReceivePort _receivePort;

  _WebSocketIsolateWorker(this._sendPort, this._url) {
    _receivePort = ReceivePort();
    _sendPort.send(_receivePort.sendPort);
    _connect();
  }

  void _connect() async {
    // Import web_socket_client in the isolate context
    final webSocket = await _createWebSocket();

    webSocket.connection.listen(
      (state) {
        if (state is Connected) {
          _sendPort.send({'type': 'ready'});
        } else if (state is Reconnecting) {
          _sendPort.send({'type': 'reconnecting'});
        } else if (state is Disconnected) {
          _sendPort.send({
            'type': 'done',
            'closeCode': null,
            'closeReason': 'Disconnected',
          });
        }
      },
      onError: (error) {
        _sendPort.send({
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

        // Send raw message to main isolate
        _sendPort.send({
          'type': 'message',
          'data': data,
        });
      },
      onError: (error) {
        _sendPort.send({
          'type': 'error',
          'error': error.toString(),
        });
      },
      onDone: () {
        _sendPort.send({
          'type': 'done',
          'closeCode': null,
          'closeReason': "Done",
        });
      },
    );

    // Listen for commands from main isolate
    _receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        switch (message['command']) {
          case 'send':
            webSocket.send(message['data']);
            break;
          case 'close':
            webSocket.close();
            _receivePort.close();
            break;
        }
      }
    });
  }

  Future<WebSocket> _createWebSocket() async {
    final backoff = BinaryExponentialBackoff(
      initial: Duration(seconds: 1),
      maximumStep: 10,
    );

    return WebSocket(Uri.parse(_url), backoff: backoff);
  }
}
