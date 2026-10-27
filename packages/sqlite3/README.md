# ndk_sqlite3

A SQLite cache manager for [NDK](https://pub.dev/packages/ndk), in pure Dart.

- Runs without Flutter: command line tools, servers and bots, as well as Flutter apps.
- Queries the database instead of loading it in memory. Filters, replaceable events, NIP-09 deletions, NIP-40 expiration and eviction all run in SQL, so memory use does not grow with the cache.
- Nothing to install: [`sqlite3`](https://pub.dev/packages/sqlite3) bundles SQLite.

## Usage

```dart
import 'package:ndk/ndk.dart';
import 'package:ndk_sqlite3/ndk_sqlite3.dart';

final cache = SqliteCacheManager.open('ndk_cache.db');
final ndk = Ndk(NdkConfig(cache: cache, eventVerifier: Bip340EventVerifier()));

// ...

await ndk.destroy();
await cache.close();
```

`open` enables WAL journaling. To set up the connection yourself, pass an opened database instead:

```dart
import 'package:sqlite3/sqlite3.dart';

final cache = SqliteCacheManager(sqlite3.openInMemory());
```

SQLite calls are synchronous: each cache call blocks the calling isolate until its queries finish.
