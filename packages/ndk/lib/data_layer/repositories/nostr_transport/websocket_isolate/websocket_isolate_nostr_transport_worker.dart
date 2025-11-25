part of 'websocket_isolate_nostr_transport.dart';

class _WebSocketIsolateWorker {
  final SendPort _mainSendPort;
  final ReceivePort _receivePort = ReceivePort();
  final Map<int, WebSocket> _connections = {};
  final Map<int, List<StreamSubscription>> _subscriptions = {};

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
      _closeConnection(message.connectionId);
    }
  }

  Future<void> _closeConnection(int connectionId) async {
    _connections[connectionId]?.close();
    _connections.remove(connectionId);

    // Cancel all subscriptions for this connection
    final subs = _subscriptions.remove(connectionId);
    if (subs != null) {
      for (final sub in subs) {
        await sub.cancel();
      }
    }
  }

  void _connect(int connectionId, String url) async {
    final backoff = BinaryExponentialBackoff(
      initial: Duration(seconds: 1),
      maximumStep: 10,
    );

    final webSocket = WebSocket(Uri.parse(url), backoff: backoff);
    _connections[connectionId] = webSocket;

    final subscriptions = <StreamSubscription>[];

    final connectionSub = webSocket.connection.listen(
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
    subscriptions.add(connectionSub);

    final messagesSub = webSocket.messages.listen(
      (message) {
        //? this is an expensive operation
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
        _closeConnection(connectionId);
      },
    );
    subscriptions.add(messagesSub);

    _subscriptions[connectionId] = subscriptions;
  }
}
