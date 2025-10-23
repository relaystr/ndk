import 'log_event.dart';

/// Abstract interface for logger outputs.
/// 
/// Implement this interface to create custom log outputs
/// (console, file, network, etc.)
abstract class LogOutput {
  /// Called when a log event should be output.
  void output(LogEvent event);

  /// Called when the logger is being destroyed.
  /// Override to perform cleanup (close files, connections, etc.)
  void destroy() {}
}
