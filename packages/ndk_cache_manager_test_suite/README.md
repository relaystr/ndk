# NDK Cache Manager Test Suite


A shared test suite for [NDK](https://pub.dev/packages/ndk) `CacheManager` implementations.\
Run the same comprehensive test suite against any cache backend — ObjectBox, Drift, Sembast, or your own — to verify it correctly implements the `CacheManager` interface contract.

## Usage

Add `ndk_cache_manager_test_suite` as a **dev dependency**:

```yaml
dev_dependencies:
  ndk_cache_manager_test_suite: <version>
```

Then in your test file:

```dart
import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';

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

## What's Tested

The suite covers all `CacheManager` operations:

| Group | What it verifies |
|-------|-----------------|
| **Event Operations** | Save, load, batch save, filter by pubKey/kind/tags, remove |
| **Metadata Operations** | Save, load, and query user metadata |
| **ContactList Operations** | Save, load, and query contact lists |
| **Nip05 Operations** | Save, load, and query NIP-05 domain verification data |
| **UserRelayList Operations** | Save, load, and query user relay lists |
| **RelaySet Operations** | Save, load, and query relay sets |
| **Search Operations** | Full-text search over events |
| **ClearAll Operations** | Bulk clear and database cleanup |
| **Cashu Operations** | Cashu token management (save, load, remove, spend) |



## Architecture

```
ndk                              ← no test dependency
  ↑
ndk_cache_manager_test_suite     ← depends on ndk + test (regular deps)
  ↑ (dev_dependency only)
├── objectbox                    ← runs shared suite
├── drift                        ← runs shared suite
└── ndk                          ← runs shared suite (sembast, mem)
```


# [Changelog 🔗](./CHANGELOG.md)
