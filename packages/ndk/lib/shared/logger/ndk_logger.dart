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

  /// Log a trace message
  void t(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.trace, message, error, stackTrace);
  }

  /// Log a debug message
  void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Log an info message
  void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log a warning message
  void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log an error message
  void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log a fatal message
  void f(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  /// Internal logging method
  void _log(
    LogLevel logLevel,
    dynamic message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (!logLevel.shouldLog(level)) {
      return;
    }

    final event = LogEvent(
      level: logLevel,
      message: message.toString(),
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
