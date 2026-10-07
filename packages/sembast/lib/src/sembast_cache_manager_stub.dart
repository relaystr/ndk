import 'package:sembast/sembast.dart' as sembast;

/// Stub database factory - should never be used
/// The conditional exports should ensure the correct platform implementation is used
final databaseFactory = throw UnsupportedError(
  'databaseFactory is not available in stub. '
  'Use platform-specific implementation via sembast_cache_manager_platform.dart',
);

/// Open a database - stub implementation that throws
Future<sembast.Database> openDatabase({
  String? databasePath,
  required String databaseName,
}) {
  throw UnsupportedError(
    'Cannot open Sembast database without dart:io or dart:js_interop. '
    'Use sembast_cache_manager_platform.dart for platform-specific imports.',
  );
}
