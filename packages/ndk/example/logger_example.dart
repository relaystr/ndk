/// Example: Creating Custom Logger Outputs
/// 
/// The NDK logger is designed to be modular, allowing you to create
/// custom outputs for different logging backends.

import 'package:ndk/ndk.dart';

/// Example: Custom File Logger Output
/// Note: This is just an example structure - actual file logging would
/// require platform-specific implementations
class CustomFileOutput implements LogOutput {
  final String filePath;

  CustomFileOutput(this.filePath);

  @override
  void output(LogEvent event) {
    // In a real implementation, you would write to a file here
    // This might use platform-specific code (e.g., dart:io on native platforms)
    final message = '[${event.level.name.toUpperCase()}] ${event.message}';
    // writeToFile(filePath, message);
    print('Would write to $filePath: $message');
  }

  @override
  void destroy() {
    // Clean up file handles
  }
}

/// Example: Custom Network Logger Output
class NetworkLoggerOutput implements LogOutput {
  final String endpoint;

  NetworkLoggerOutput(this.endpoint);

  @override
  void output(LogEvent event) {
    // In a real implementation, you would send logs to a remote server
    final logData = {
      'level': event.level.name,
      'message': event.message,
      'timestamp': event.timestamp.toIso8601String(),
    };
    // sendToServer(endpoint, logData);
    print('Would send to $endpoint: $logData');
  }

  @override
  void destroy() {
    // Close network connections
  }
}

/// Example: Using the Logger with Custom Outputs
void main() {
  // Example 1: Use the default logger (already configured)
  Logger.log.d('This uses the default console output');

  // Example 2: Add multiple outputs
  final customFileOutput = CustomFileOutput('/tmp/ndk.log');
  final networkOutput = NetworkLoggerOutput('https://logs.example.com');

  Logger.log.addOutput(customFileOutput);
  Logger.log.addOutput(networkOutput);

  // Now logs will go to console, file, AND network
  Logger.log.i('This goes to all three outputs!');

  // Example 3: Change log level dynamically
  Logger.setLogLevel(LogLevel.debug);
  Logger.log.d('Debug message - now visible');

  Logger.setLogLevel(LogLevel.error);
  Logger.log.d('Debug message - now hidden');
  Logger.log.e('Error message - still visible');

  // Example 4: Access log levels
  Logger.setLogLevel(Logger.logLevels.trace);
  Logger.log.t('Trace message');

  // Example 5: Create a completely custom logger instance
  final myLogger = NdkLogger(
    level: LogLevel.info,
    outputs: [
      ConsoleOutput(includeTimestamp: true),
      customFileOutput,
    ],
  );

  myLogger.i('This is a custom logger instance');
  myLogger.w('Warning from custom logger');

  // Clean up
  Logger.log.removeOutput(customFileOutput);
  Logger.log.removeOutput(networkOutput);
}
