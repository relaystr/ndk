import 'package:ndk/ndk.dart';
import 'package:ndk/shared/logger/log_event.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Logger', () {
    test('Logger levels should work correctly', () {
      // Test that log levels are properly ordered
      expect(LogLevel.all.value < LogLevel.trace.value, true);
      expect(LogLevel.trace.value < LogLevel.debug.value, true);
      expect(LogLevel.debug.value < LogLevel.info.value, true);
      expect(LogLevel.info.value < LogLevel.warning.value, true);
      expect(LogLevel.warning.value < LogLevel.error.value, true);
      expect(LogLevel.error.value < LogLevel.fatal.value, true);
      expect(LogLevel.fatal.value < LogLevel.off.value, true);
    });

    test('Log level shouldLog works correctly', () {
      // When minimum level is warning, only warning and above should log
      expect(LogLevel.trace.shouldLog(LogLevel.warning), false);
      expect(LogLevel.debug.shouldLog(LogLevel.warning), false);
      expect(LogLevel.info.shouldLog(LogLevel.warning), false);
      expect(LogLevel.warning.shouldLog(LogLevel.warning), true);
      expect(LogLevel.error.shouldLog(LogLevel.warning), true);
      expect(LogLevel.fatal.shouldLog(LogLevel.warning), true);
    });

    test('Logger can be configured with different levels', () {
      // Test that we can set different log levels
      Logger.setLogLevel(LogLevel.debug);
      expect(Logger.log.level, LogLevel.debug);

      Logger.setLogLevel(LogLevel.error);
      expect(Logger.log.level, LogLevel.error);

      // Reset to default
      Logger.setLogLevel(LogLevel.warning);
    });

    test('LogLevels constants work', () {
      // Test that the LogLevels class provides access to all levels
      expect(Logger.logLevels.all, LogLevel.all);
      expect(Logger.logLevels.trace, LogLevel.trace);
      expect(Logger.logLevels.debug, LogLevel.debug);
      expect(Logger.logLevels.info, LogLevel.info);
      expect(Logger.logLevels.warning, LogLevel.warning);
      expect(Logger.logLevels.error, LogLevel.error);
      expect(Logger.logLevels.fatal, LogLevel.fatal);
      expect(Logger.logLevels.off, LogLevel.off);
    });

    test('Logger can have multiple outputs', () {
      final testOutputs = <LogEvent>[];

      final testOutput = _TestLogOutput(testOutputs);

      Logger.log.addOutput(testOutput);
      Logger.setLogLevel(LogLevel.debug);

      Logger.log.d('Test message');

      expect(testOutputs.length, 1);
      expect(testOutputs.first.message, 'Test message');
      expect(testOutputs.first.level, LogLevel.debug);

      Logger.log.removeOutput(testOutput);

      // Reset to default
      Logger.setLogLevel(LogLevel.warning);
    });

    test('Logger respects log level filtering', () {
      final testOutputs = <LogEvent>[];
      final testOutput = _TestLogOutput(testOutputs);

      Logger.log.addOutput(testOutput);
      Logger.setLogLevel(LogLevel.warning);

      // These should not be logged
      Logger.log.t('Trace message');
      Logger.log.d('Debug message');
      Logger.log.i('Info message');

      // These should be logged
      Logger.log.w('Warning message');
      Logger.log.e('Error message');

      expect(testOutputs.length, 2);
      expect(testOutputs[0].level, LogLevel.warning);
      expect(testOutputs[1].level, LogLevel.error);

      Logger.log.removeOutput(testOutput);

      // Reset to default
      Logger.setLogLevel(LogLevel.warning);
    });

    test('Custom NdkLogger instance works independently', () {
      final testOutputs = <LogEvent>[];
      final testOutput = _TestLogOutput(testOutputs);

      final customLogger = NdkLogger(
        level: LogLevel.info,
        outputs: [testOutput],
      );

      customLogger.i('Info message');
      customLogger.d('Debug message'); // Should be filtered out

      expect(testOutputs.length, 1);
      expect(testOutputs.first.message, 'Info message');
    });
  });
}

/// Test log output that captures events in a list
class _TestLogOutput implements LogOutput {
  final List<LogEvent> events;

  _TestLogOutput(this.events);

  @override
  void output(LogEvent event) {
    events.add(event);
  }

  @override
  void destroy() {
    // Nothing to clean up
  }
}
