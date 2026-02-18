import 'dart:async';
import 'dart:isolate';

const int encodingIsolatePoolSize = 20;
const int computeIsolatePoolSize = 20;

typedef StreamComputeTask<Q, P> = FutureOr<void> Function(
  Q argument,
  void Function(P progress) emit,
);

class IsolateConfig {
  Isolate isolate;
  SendPort sendPort;
  IsolateConfig(this.isolate, this.sendPort);
}

class IsolatePool {
  final List<IsolateConfig> _isolates = [];
  int _currentIndex = 0;

  List<IsolateConfig> get isolates => _isolates;

  void add(IsolateConfig config) {
    _isolates.add(config);
  }

  SendPort getNextSendPort() {
    if (_isolates.isEmpty) {
      throw StateError('Isolate pool is empty');
    }
    final sendPort = _isolates[_currentIndex].sendPort;
    _currentIndex = (_currentIndex + 1) % _isolates.length;
    return sendPort;
  }

  void killAll() {
    for (final config in _isolates) {
      config.isolate.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _currentIndex = 0;
  }
}

class IsolateManager {
  static IsolateManager? _instance;
  static IsolateManager get instance {
    _instance ??= IsolateManager._();
    return _instance!;
  }

  final IsolatePool _encodePool = IsolatePool();
  final IsolatePool _computePool = IsolatePool();
  final Completer<void> _readyCompleter = Completer<void>();

  IsolateManager._() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize encoding isolate pool
      for (int i = 0; i < encodingIsolatePoolSize; i++) {
        final config = await _createIsolate();
        _encodePool.add(config);
      }

      // Initialize compute isolate pool
      for (int i = 0; i < computeIsolatePoolSize; i++) {
        final config = await _createIsolate();
        _computePool.add(config);
      }

      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    } catch (e) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(e);
      }
    }
  }

  Future<IsolateConfig> _createIsolate() async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    final sendPort = await receivePort.first as SendPort;
    return IsolateConfig(isolate, sendPort);
  }

  Future<R> _runTask<Q, R>(
    R Function(Q) task,
    Q argument,
    IsolatePool pool,
  ) async {
    final sendPort = pool.getNextSendPort();

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
    return _runTask(task, argument, _encodePool);
  }

  /// dedicated for compute operations (like crypto, hashing, etc)
  Future<R> runInComputeIsolate<Q, R>(
    R Function(Q) task,
    Q argument,
  ) async {
    await ready;
    return _runTask(task, argument, _computePool);
  }

  /// dedicated for compute operations that need streaming progress updates
  ///
  /// Example:
  /// ```dart
  /// Stream<int> progress = IsolateManager.instance
  ///     .runInComputeIsolateStream<String, int>(
  ///   (path, emit) async {
  ///     emit(0);
  ///     // ...do work in chunks and emit updates...
  ///     emit(100);
  ///   },
  ///   '/tmp/file.bin',
  /// );
  ///
  /// await for (final value in progress) {
  ///   print('progress: $value%');
  /// }
  /// ```
  Stream<P> runInComputeIsolateStream<Q, P>(
    StreamComputeTask<Q, P> task,
    Q argument,
  ) async* {
    await ready;

    final sendPort = _computePool.getNextSendPort();
    final port = ReceivePort();
    sendPort.send(['stream', task, argument, port.sendPort]);

    await for (final message in port) {
      if (message is Map && message['type'] == 'progress') {
        yield message['data'] as P;
      } else if (message is Map && message['type'] == 'done') {
        port.close();
        break;
      } else if (message is Map && message['error'] != null) {
        port.close();
        throw Exception(message['error']);
      }
    }
  }

  Future<void> dispose() async {
    _encodePool.killAll();
    _computePool.killAll();
    _instance = null;
  }
}

void _isolateEntry(SendPort sendPort) {
  final port = ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((message) async {
    if (message is! List || message.isEmpty) {
      return;
    }

    if (message[0] == 'stream' && message.length == 4) {
      final task = message[1] as Function;
      final argument = message[2];
      final replyPort = message[3] as SendPort;

      try {
        void emit(dynamic progress) {
          replyPort.send({'type': 'progress', 'data': progress});
        }

        final result = task(argument, emit);
        if (result is Future) {
          await result;
        }

        replyPort.send({'type': 'done'});
      } catch (e, stackTrace) {
        // ignore: avoid_print
        print('_isolateEntry Stream Error: $e\n$stackTrace');
        replyPort.send({'error': 'Error: $e'});
      }
      return;
    }

    if (message.length != 3) {
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
