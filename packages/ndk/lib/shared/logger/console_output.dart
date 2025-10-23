import 'log_event.dart';
import 'log_output.dart';

/// Console output for the logger that prints to stdout.
/// 
/// This output adds an "NDK: " prefix to all log messages.
class ConsoleOutput implements LogOutput {
  /// Whether to include timestamps in the output
  final bool includeTimestamp;

  /// Constructor
  ConsoleOutput({this.includeTimestamp = false});

  @override
  void output(LogEvent event) {
    final buffer = StringBuffer('NDK: ');

    if (includeTimestamp) {
      buffer.write('[${_formatTimestamp(event.timestamp)}] ');
    }

    buffer.write('[${event.level.name.toUpperCase()}] ');
    buffer.write(event.message);

    if (event.error != null) {
      buffer.write('\nError: ${event.error}');
    }

    if (event.stackTrace != null) {
      buffer.write('\n${event.stackTrace}');
    }

    // ignore: avoid_print
    print(buffer.toString());
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  @override
  void destroy() {
    // Nothing to clean up for console output
  }
}
