/// Shared test suite for CacheManager implementations.
///
/// This library provides a reusable test suite that can be run against any
/// [CacheManager] implementation to verify it correctly implements the
/// interface contract.
///
/// ## Usage
///
/// In your test file:
///
/// ```dart
/// import 'package:ndk/cache_manager_test_suite.dart';
///
/// void main() {
///   runCacheManagerTestSuite(
///     name: 'MyCacheManager',
///     createCacheManager: () async => MyCacheManager(),
///     cleanUp: (cacheManager) async => await cacheManager.close(),
///   );
/// }
/// ```
library;

export 'shared/test_utils/cache_manager_test_suite.dart';
