import 'log_event.dart';
import 'log_level.dart';
import 'log_output.dart';

/// Core logger implementation.
///
/// This logger supports:
/// - Multiple log outputs (console, file, network, etc.)
/// - Configurable log levels
/// - WASM compatibility (no dart:io dependency)
class NdkLogger {
  /// Current minimum log level
  LogLevel level;

  /// List of outputs where logs will be sent
  final List<LogOutput> _outputs;

  /// Constructor
  NdkLogger({
    required this.level,
    List<LogOutput>? outputs,
  }) : _outputs = outputs ?? [];

  /// Add an output to the logger
  void addOutput(LogOutput output) {
    _outputs.add(output);
  }

  /// Remove an output from the logger
  void removeOutput(LogOutput output) {
    _outputs.remove(output);
  }

  /// Clear all outputs
  void clearOutputs() {
    for (final output in _outputs) {
      output.destroy();
    }
    _outputs.clear();
  }

  /// Check whether a [logLevel] is currently enabled
  bool isEnabled(LogLevel logLevel) {
    return logLevel.shouldLog(level);
  }

  /// Log a trace message
  void t(Object? Function() message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.trace, message, error, stackTrace);
  }

  /// Log a debug message
  void d(Object? Function() message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Log an info message
  void i(Object? Function() message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log a warning message
  void w(Object? Function() message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log an error message
  void e(Object? Function() message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log a fatal message
  void f(Object? Function() message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  /// Internal logging method
  void _log(
    LogLevel logLevel,
    Object? Function() message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (!isEnabled(logLevel)) {
      return;
    }

    _emit(logLevel, message(), error, stackTrace);
  }

  void _emit(
    LogLevel logLevel,
    Object? message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final event = LogEvent(
      level: logLevel,
      message: message?.toString() ?? 'null',
      error: error,
      stackTrace: stackTrace,
    );

    for (final output in _outputs) {
      output.output(event);
    }
  }

  /// Close the logger and cleanup all outputs
  void close() {
    clearOutputs();
  }
}
