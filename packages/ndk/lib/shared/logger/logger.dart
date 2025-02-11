import 'package:logger/logger.dart' as lib_logger;

import '../../config/logger_defaults.dart';

/// A mixin class that provides a logger instance.
// coverage:ignore-start
mixin class Logger {
  /// Expose the Level enum as a getter
  static const logLevels = LogLevels();

  static final _myPrinter = lib_logger.PrettyPrinter(
    methodCount: 0,
    printEmojis: false,
    dateTimeFormat: lib_logger.DateTimeFormat.none,
  );

  /// The logger instance.
  static lib_logger.Logger log = lib_logger.Logger(
    printer: _myPrinter,
    level: defaultLogLevel,
    output: MyConsoleOutput(),
  );

  /// Set the log level of the logger.
  static void setLogLevel(lib_logger.Level level) {
    /// override the logger
    log = lib_logger.Logger(
      printer: _myPrinter,
      level: level,
      output: MyConsoleOutput(),
    );
  }
}
// coverage:ignore-end

/// A class that provides log levels.
// coverage:ignore-start
class LogLevels {
  ///
  const LogLevels();

  /// [Level] all - log everything
  lib_logger.Level get all => lib_logger.Level.all;

  /// [Level] trace - log everything
  lib_logger.Level get trace => lib_logger.Level.trace;

  /// [Level] debug - log debug and above
  lib_logger.Level get debug => lib_logger.Level.debug;

  /// [Level] info - log info and above
  lib_logger.Level get info => lib_logger.Level.info;

  /// [Level] warning - log warning and above
  lib_logger.Level get warning => lib_logger.Level.warning;

  /// [Level] error - log error and above
  lib_logger.Level get error => lib_logger.Level.error;

  /// [Level] fatal - log fatal and above
  lib_logger.Level get fatal => lib_logger.Level.fatal;

  /// [Level] off - log nothing
  lib_logger.Level get off => lib_logger.Level.off;
}

// coverage:ignore-end

/// custom console output, includes NDK prefix
// coverage:ignore-start
class MyConsoleOutput extends lib_logger.LogOutput {
  @override
  void output(lib_logger.OutputEvent event) {
    for (var line in event.lines) {
      // ignore: avoid_print
      print("NDK: $line");
    }
  }
}
// coverage:ignore-end
