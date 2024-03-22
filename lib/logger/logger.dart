import 'package:logger/logger.dart' as my_logger;

mixin class Logger {
  static var myPrinter = my_logger.PrettyPrinter(
    methodCount: 0,
    printEmojis: false,
    printTime: false,
    //noBoxingByDefault: true,
  );

  static my_logger.Logger log = my_logger.Logger(
    printer: myPrinter,
    level: my_logger.Level.debug,
  );

  static setLogLevel(my_logger.Level level) {
    log = my_logger.Logger(
      printer: myPrinter,
      level: level,
    );
  }
}
