import 'log_event.dart';
import 'log_output.dart';
import 'log_color.dart';

/// Console output with color support
class ConsoleOutput extends LogOutput {
  final bool useColors;
  final bool showTime;
  final bool detailedTime;

  ConsoleOutput({
    this.useColors = true,
    this.showTime = true,
    this.detailedTime = false,
  });

  @override
  void output(LogEvent event) {
    final levelStr = event.level.name.toUpperCase();

    String timestamp = '';
    if (showTime) {
      if (detailedTime) {
        timestamp = '${event.timestamp.toIso8601String()} ';
      } else {
        final hour = event.timestamp.hour.toString().padLeft(2, '0');
        final minute = event.timestamp.minute.toString().padLeft(2, '0');
        timestamp = '$hour:$minute ';
      }
    }

    String message;
    if (useColors) {
      final coloredLevel = LogColor.colorizeLevel(event.level, '[$levelStr]');
      message = '$timestamp$coloredLevel ${event.message}';
    } else {
      message = '$timestamp[$levelStr] ${event.message}';
    }

    if (event.error != null) {
      message += '\nError: ${event.error}';
    }
    if (event.stackTrace != null) {
      message += '\n${event.stackTrace}';
    }

    print(message);
  }

  @override
  void destroy() {
    // Nothing to cleanup for console output
  }
}
