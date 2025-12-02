import '../../config/logger_defaults.dart';
import 'console_output.dart';
import 'log_level.dart';
import 'ndk_logger.dart';

/// A mixin class that provides a logger instance.
// coverage:ignore-start
mixin class Logger {
  /// Expose the Level enum as a getter
  static const logLevels = LogLevels();

  /// The logger instance.
  static NdkLogger log = NdkLogger(
    level: defaultLogLevel,
    outputs: [ConsoleOutput()],
  );

  /// Set the log level of the logger.
  static void setLogLevel(LogLevel level) {
    log.level = level;
  }
}
// coverage:ignore-end

/// A class that provides log levels.
// coverage:ignore-start
class LogLevels {
  ///
  const LogLevels();

  /// [LogLevel] all - log everything
  LogLevel get all => LogLevel.all;

  /// [LogLevel] trace - log everything
  LogLevel get trace => LogLevel.trace;

  /// [LogLevel] debug - log debug and above
  LogLevel get debug => LogLevel.debug;

  /// [LogLevel] info - log info and above
  LogLevel get info => LogLevel.info;

  /// [LogLevel] warning - log warning and above
  LogLevel get warning => LogLevel.warning;

  /// [LogLevel] error - log error and above
  LogLevel get error => LogLevel.error;

  /// [LogLevel] fatal - log fatal and above
  LogLevel get fatal => LogLevel.fatal;

  /// [LogLevel] off - log nothing
  LogLevel get off => LogLevel.off;
}
// coverage:ignore-end
