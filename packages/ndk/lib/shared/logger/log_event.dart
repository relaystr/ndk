import 'log_level.dart';

/// A log event that contains the log level, message, and optional error/stacktrace.
class LogEvent {
  /// The log level
  final LogLevel level;

  /// The log message
  final String message;

  /// Optional error object
  final Object? error;

  /// Optional stack trace
  final StackTrace? stackTrace;

  /// Timestamp when the log was created
  final DateTime timestamp;

  /// Constructor
  LogEvent({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  }) : timestamp = DateTime.now();
}
