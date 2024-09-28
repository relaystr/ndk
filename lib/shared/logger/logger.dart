import 'package:logger/logger.dart' as lib_logger;

// coverage:ignore-start
mixin class Logger {
  static const _defaultLogLevel = lib_logger.Level.debug;

  static final _myPrinter = lib_logger.PrettyPrinter(
      methodCount: 0,
      printEmojis: false,
      dateTimeFormat: lib_logger.DateTimeFormat.none
      //noBoxingByDefault: true,
      );

  static lib_logger.Logger log = lib_logger.Logger(
    printer: _myPrinter,
    level: _defaultLogLevel,
  );

  static setLogLevel(lib_logger.Level level) {
    log = lib_logger.Logger(
      printer: _myPrinter,
      level: level,
    );
  }
}
// coverage:ignore-end