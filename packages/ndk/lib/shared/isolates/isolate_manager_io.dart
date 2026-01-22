import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../logger/logger.dart';
import '../simple_profiler.dart';

final int encodingIsolatePoolSize = Platform.numberOfProcessors ~/ 2;
final int computeIsolatePoolSize = Platform.numberOfProcessors ~/ 2;

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
    final profiler = SimpleProfiler('IsolateManager Initialization');

    try {
      Logger.log.d(
          "Initializing encoding isolate pool size = $encodingIsolatePoolSize");
      // Initialize encoding isolate pool
      for (int i = 0; i < encodingIsolatePoolSize; i++) {
        final config = await _createIsolate();
        _encodePool.add(config);
      }
      profiler.checkpoint(
          'Encoding isolate pool initialized ($encodingIsolatePoolSize isolates)');

      Logger.log.d(
          "Initializing compute isolate pool size = $encodingIsolatePoolSize");
      // Initialize compute isolate pool
      for (int i = 0; i < computeIsolatePoolSize; i++) {
        final config = await _createIsolate();
        _computePool.add(config);
      }
      profiler.checkpoint(
          'Compute isolate pool initialized ($computeIsolatePoolSize isolates)');

      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      Logger.log.d("Finished initializing isolate pools");

      profiler.end();
    } catch (e) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(e);
        Logger.log.e("Error initializing isolate pools", error: e);
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

  Future<void> dispose() async {
    _encodePool.killAll();
    _computePool.killAll();
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
