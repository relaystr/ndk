# NDK Custom Logger

The NDK now uses a custom, modular logger implementation that is WASM-compatible (no `dart:io` dependency).

## Features

- **WASM Compatible**: No dependency on `dart:io`, making it suitable for web/WASM targets
- **Modular Output System**: Support for multiple log outputs (console, file, network, etc.)
- **Log Levels**: Support for trace, debug, info, warning, error, fatal, all, and off levels
- **Flexible Configuration**: Easy to configure and customize

## Usage

### Basic Usage

The logger is already configured and ready to use:

```dart
import 'package:ndk/ndk.dart';

// Use the static logger instance
Logger.log.d(() => 'Debug message');
Logger.log.i(() => 'Info message');
Logger.log.w(() => 'Warning message');
Logger.log.e(() => 'Error message');
```

### Setting Log Level

You can change the log level at runtime:

```dart
// Set to debug level
Logger.setLogLevel(LogLevel.debug);

// Or use the logLevels constants
Logger.setLogLevel(Logger.logLevels.warning);
```

### Available Log Levels

- `LogLevel.all` - Log everything (lowest priority)
- `LogLevel.trace` - Very detailed debugging
- `LogLevel.debug` - Debugging information
- `LogLevel.info` - Informational messages
- `LogLevel.warning` - Warning messages (default)
- `LogLevel.error` - Error messages
- `LogLevel.fatal` - Fatal error messages
- `LogLevel.off` - Disable logging

### Custom Log Outputs

You can create custom log outputs by implementing the `LogOutput` interface:

```dart
import 'package:ndk/ndk.dart';

class MyCustomOutput implements LogOutput {
  @override
  void output(LogEvent event) {
    // Handle the log event
    print('Custom: [${event.level.name}] ${event.message}');
  }

  @override
  void destroy() {
    // Cleanup when the logger is destroyed
  }
}

// Add the custom output to the logger
final customOutput = MyCustomOutput();
Logger.log.addOutput(customOutput);

// Now logs will go to both console and your custom output
Logger.log.i('This goes to multiple outputs');

// Remove when done
Logger.log.removeOutput(customOutput);
```

### Multiple Outputs

The logger supports sending logs to multiple outputs simultaneously:

```dart
// Add multiple outputs
Logger.log.addOutput(fileOutput);
Logger.log.addOutput(networkOutput);
Logger.log.addOutput(customOutput);

// Logs will be sent to console + all added outputs
Logger.log.i('This goes everywhere!');
```

### Custom Logger Instance

You can create custom logger instances for specific components:

```dart
final myLogger = NdkLogger(
  level: LogLevel.info,
  outputs: [
    ConsoleOutput(includeTimestamp: true),
    MyCustomOutput(),
  ],
);

myLogger.i('Message from custom logger');
```

## Configuration via NdkConfig

You can set the log level when initializing NDK:

```dart
final ndk = Ndk(NdkConfig(
  cache: MemCacheManager(),
  eventVerifier: Bip340EventVerifier(),
  logLevel: LogLevel.debug,  // Set desired log level
));
```

## Migration from logger package

If you were using the `logger` package directly, update your code:

**Before:**
```dart
import 'package:logger/logger.dart' as lib_logger;
Logger.setLogLevel(lib_logger.Level.warning);
```

**After:**
```dart
import 'package:ndk/ndk.dart';
Logger.setLogLevel(LogLevel.warning);
```

## Example

See [example/logger_example.dart](../../example/logger_example.dart) for a complete example showing:
- Basic usage
- Custom outputs
- Multiple outputs
- Changing log levels
- Custom logger instances
