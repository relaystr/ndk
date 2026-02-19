import 'dart:async';

typedef StreamComputeTask<Q, P> = FutureOr<void> Function(
  Q argument,
  void Function(P progress) emit,
);

/// Web implementation of IsolateManager that runs tasks on the main thread.
/// Isolates are not supported on web platforms, so this implementation
/// executes tasks synchronously instead.
class IsolateManager {
  static IsolateManager? _instance;
  static IsolateManager get instance {
    _instance ??= IsolateManager._();
    return _instance!;
  }

  final Completer<void> _readyCompleter = Completer<void>();

  IsolateManager._() {
    // Immediately complete since there's no isolate initialization needed
    _readyCompleter.complete();
  }

  Future<void> get ready => _readyCompleter.future;

  /// On web, runs the task synchronously on the main thread
  Future<R> runInEncodingIsolate<Q, R>(
    R Function(Q) task,
    Q argument,
  ) async {
    await ready;
    return task(argument);
  }

  /// On web, runs the task synchronously on the main thread
  Future<R> runInComputeIsolate<Q, R>(
    R Function(Q) task,
    Q argument,
  ) async {
    await ready;
    return task(argument);
  }

  /// On web, runs the streaming task on the main thread
  Stream<P> runInComputeIsolateStream<Q, P>(
    StreamComputeTask<Q, P> task,
    Q argument,
  ) async* {
    await ready;

    final controller = StreamController<P>();

    try {
      final result = task(argument, controller.add);
      if (result is Future) {
        await result;
      }
      await controller.close();
    } catch (e, stackTrace) {
      controller.addError(e, stackTrace);
      await controller.close();
    }

    yield* controller.stream;
  }

  Future<void> dispose() async {
    _instance = null;
  }
}
