import 'log_level.dart';

/// ANSI color codes for terminal output
class LogColor {
  static const String reset = '\x1B[0m';
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String gray = '\x1B[90m';

  /// Get color for log level
  static String forLevel(LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return gray;
      case LogLevel.debug:
        return cyan;
      case LogLevel.info:
        return green;
      case LogLevel.warning:
        return yellow;
      case LogLevel.error:
        return red;
      case LogLevel.fatal:
        return magenta;
      case LogLevel.all:
        return blue;
      case LogLevel.off:
        return reset;
    }
  }

  /// Wrap text with color
  static String colorize(String text, String color) {
    return '$color$text$reset';
  }

  /// Colorize message based on log level
  static String colorizeLevel(LogLevel level, String text) {
    return colorize(text, forLevel(level));
  }
}
