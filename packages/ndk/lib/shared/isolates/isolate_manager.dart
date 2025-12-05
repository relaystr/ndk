import 'dart:async';
import 'dart:isolate';

class IsolateConfig {
  Isolate isolate;
  SendPort sendPort;
  IsolateConfig(this.isolate, this.sendPort);
}

class IsolateManager {
  static IsolateManager? _instance;
  static IsolateManager get instance {
    _instance ??= IsolateManager._();
    return _instance!;
  }

  Isolate? _encodeIsolate;
  Isolate? _computeIsolate;

  SendPort? _encodeSendPort;
  SendPort? _computeSendPort;
  final Completer<void> _readyCompleter = Completer<void>();

  IsolateManager._() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _encodeSendPort = await _createIsolate((sendPort) {
        _encodeIsolate = sendPort.isolate;
        return sendPort.sendPort;
      });
      _computeSendPort = await _createIsolate((sendPort) {
        _computeIsolate = sendPort.isolate;
        return sendPort.sendPort;
      });

      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    } catch (e) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(e);
      }
    }
  }

  Future<SendPort> _createIsolate(Function(IsolateConfig) isolateConfig) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    final sendPort = await receivePort.first as SendPort;
    isolateConfig(IsolateConfig(isolate, sendPort));
    return sendPort;
  }

  Future<R> _runTask<Q, R>(
    R Function(Q) task,
    Q argument,
    SendPort? sendPort,
  ) async {
    if (sendPort == null) {
      throw StateError('Isolate not initialized');
    }

    final completer = Completer<R>();
    final port = ReceivePort();
    sendPort.send([task, argument, port.sendPort]);
    port.listen((message) {
      port.close();
      if (message is Map && message['error'] != null) {
        completer.completeError(message['error']);
      } else {
        completer.complete(message as R);
      }
    });
    return completer.future;
  }

  Future<void> get ready => _readyCompleter.future;

  /// dedicated for decoding/encoding json
  Future<R> runInEncodingIsolate<Q, R>(
    R Function(Q) task,
    Q argument,
  ) async {
    await ready;
    return _runTask(task, argument, _encodeSendPort);
  }

  /// dedicated for compute operations (like crypto, hashing, etc)
  Future<R> runInComputeIsolate<Q, R>(
    R Function(Q) task,
    Q argument,
  ) async {
    await ready;
    return _runTask(task, argument, _computeSendPort);
  }

  Future<void> dispose() async {
    _encodeIsolate?.kill(priority: Isolate.immediate);
    _computeIsolate?.kill(priority: Isolate.immediate);

    _encodeIsolate = null;
    _computeIsolate = null;

    _encodeSendPort = null;
    _computeSendPort = null;
    _instance = null;
  }
}

void _isolateEntry(SendPort sendPort) {
  final port = ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((message) {
    if (message is! List || message.length != 3) {
      return;
    }

    final task = message[0] as Function;
    final argument = message[1];
    final replyPort = message[2] as SendPort;

    try {
      final result = task(argument);
      replyPort.send(result);
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('_isolateEntry Error: $e\n$stackTrace');
      replyPort.send({'error': 'Error: $e'});
    }
  });
}
