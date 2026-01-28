# ndk_cache_manager_test_suite

Shared test suite for CacheManager implementations in the NDK (Nostr Development Kit) ecosystem.

## Usage

In your cache manager implementation's test file:

```dart
import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';
import 'package:test/test.dart';
import 'your_cache_manager.dart';

void main() {
  runCacheManagerTestSuite(
    name: 'MyCacheManager',
    createCacheManager: () async {
      final cacheManager = MyCacheManager();
      await cacheManager.init();
      return cacheManager;
    },
    cleanUp: (cacheManager) async => await cacheManager.close(),
  );
}
```
