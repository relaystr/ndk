# ndk_sembast

A [Sembast](https://pub.dev/packages/sembast) cache manager and wallets repository for [NDK](https://pub.dev/packages/ndk), in pure Dart.

- `SembastCacheManager` persists the NDK cache, in a database file on native platforms and in IndexedDB on the web.
- `SembastWalletsRepo` persists wallets. `SembastWalletsRepo.create` opens a database file, so it is native only; on the web, pass an opened Sembast database to the constructor.
- No Flutter required.

## Usage

```dart
import 'package:ndk/ndk.dart';
import 'package:ndk_sembast/ndk_sembast.dart';

// databasePath is required on native platforms and ignored on the web.
final cache = await SembastCacheManager.create(databasePath: '/path/to/db');
final walletsRepo = await SembastWalletsRepo.create(filename: 'wallets.db');

final ndk = Ndk(
  NdkConfig(
    cache: cache,
    walletsRepo: walletsRepo,
    eventVerifier: Bip340EventVerifier(),
  ),
);

// ...

await ndk.destroy();
await cache.close();
await walletsRepo.close();
```

More in [example/](example/).
