/// Shared test suite for CacheManager implementations.
///
/// This library provides a reusable test suite that can be run against any
/// [CacheManager] implementation to verify it correctly implements the
/// interface contract.
///
/// ## Usage
///
/// In your test file, import this library and call [runCacheManagerTestSuite]:
///
/// ```dart
/// import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';
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

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import 'package:ndk/entities.dart';
import 'package:ndk/domain_layer/repositories/cache_manager.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/data_layer/repositories/signers/bip340_event_signer.dart';

part 'cache_manager_test_suite_clear_all.dart';
part 'cache_manager_test_suite_contact_list.dart';
part 'cache_manager_test_suite_cashu.dart';
part 'cache_manager_test_suite_event.dart';
part 'cache_manager_test_suite_metadata.dart';
part 'cache_manager_test_suite_nip05.dart';
part 'cache_manager_test_suite_relay_set.dart';
part 'cache_manager_test_suite_search.dart';
part 'cache_manager_test_suite_user_relay_list.dart';

/// A factory function that creates a new [CacheManager] instance for testing.
typedef CacheManagerFactory = Future<CacheManager> Function();

/// A teardown function that cleans up after tests.
typedef CacheManagerTearDown = Future<void> Function(CacheManager cacheManager);

/// Runs the complete test suite for a [CacheManager] implementation.
///
/// Parameters:
/// - [name]: A descriptive name for the cache manager being tested.
/// - [createCacheManager]: A factory function that creates a fresh instance
///   of the cache manager for each test.
/// - [cleanUp]: An optional cleanup function called after each test.
///   This should close/dispose the cache manager.
///
/// Example:
/// ```dart
/// runCacheManagerTestSuite(
///   name: 'IsarCacheManager',
///   createCacheManager: () async {
///     final cacheManager = IsarCacheManager();
///     await cacheManager.init();
///     return cacheManager;
///   },
///   cleanUp: (cm) async => await cm.close(),
/// );
/// ```
void runCacheManagerTestSuite({
  required String name,
  required CacheManagerFactory createCacheManager,
  CacheManagerTearDown? cleanUp,
}) {
  final eventSignerFactory = Bip340EventSignerFactory();

  group('$name CacheManager Test Suite', () {
    late CacheManager cacheManager;

    setUp(() async {
      cacheManager = await createCacheManager();
    });

    tearDown(() async {
      if (cleanUp != null) {
        await cleanUp(cacheManager);
      }
    });

    group('Event Operations', () {
      _runEventTests(() => cacheManager, eventSignerFactory);
    });

    group('Metadata Operations', () {
      _runMetadataTests(() => cacheManager);
    });

    group('ContactList Operations', () {
      _runContactListTests(() => cacheManager);
    });

    group('Nip05 Operations', () {
      _runNip05Tests(() => cacheManager);
    });

    group('UserRelayList Operations', () {
      _runUserRelayListTests(() => cacheManager);
    });

    group('RelaySet Operations', () {
      _runRelaySetTests(() => cacheManager);
    });

    group('Search Operations', () {
      _runSearchTests(() => cacheManager);
    });

    group('ClearAll Operations', () {
      _runClearAllTests(() => cacheManager);
    });

    group('Cashu Operations', () {
      _runCashuTests(() => cacheManager);
    });
  });
}
