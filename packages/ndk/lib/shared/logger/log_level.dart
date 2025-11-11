/// Log levels for the NDK logger.
/// 
/// Defines the severity levels for logging messages.
enum LogLevel {
  /// Log everything - lowest priority
  all(0),

  /// Trace level - for very detailed debugging
  trace(1),

  /// Debug level - for debugging information
  debug(2),

  /// Info level - for informational messages
  info(3),

  /// Warning level - for warning messages
  warning(4),

  /// Error level - for error messages
  error(5),

  /// Fatal level - for fatal error messages
  fatal(6),

  /// Off - logging disabled
  off(7);

  /// The priority value of this log level
  final int value;

  const LogLevel(this.value);

  /// Check if this level should be logged based on the minimum level
  bool shouldLog(LogLevel minLevel) {
    return value >= minLevel.value;
  }
}
