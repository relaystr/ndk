---
icon: database
order: 98
---

NDK keeps two local stores side by side:

- the **event cache** (`CacheManager`) — Nostr events, contact lists, metadata, NIP-05 records, relay sets, fetched ranges, etc.
- the **blob cache** (`BlobCacheManager`) — binary payloads from Blossom servers, content-addressed by SHA-256.

Both are pluggable: pick the backend that fits your platform, or supply your own.

> **Tip:** keep these databases dedicated to NDK and spin up a secondary database for your own app data.

## Event cache

The simplest backend is `MemCacheManager`, an in-memory cache useful for testing and small apps.

Available databases:

- `MemCacheManager`
- [`DbObjectBox`](https://pub.dev/packages/ndk_objectbox)
- [`SembastCacheManager`](https://pub.dev/packages/sembast_cache_manager)
- [`DriftCacheManager`](https://pub.dev/packages/ndk_drift)

If you want your own database, implement the `CacheManager` interface. Contributions for more backends are welcome.

```dart objectbox example
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';

...

  DbObjectBox myObjectboxDb = DbObjectBox();
  await myObjectboxDb.dbRdy;
  final CacheManager db = myObjectboxDb;

  final ndkConfig = NdkConfig(
    cache: db,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
```

```dart sembast example
import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

...

  final tempDir = await Directory.systemTemp.createTemp('sembast_cache_db');
  final db = await SembastCacheManager.create(databasePath: tempDir.path);

  final ndkConfig = NdkConfig(
    cache: db,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
```

```dart drift example
import 'package:ndk/ndk.dart';
import 'package:ndk_drift/ndk_drift.dart';

...

  // Uses 'ndk_cache_debug' in debug mode, 'ndk_cache' in release
  final db = await DriftCacheManager.create();

  // Or with a custom database name
  // final db = await DriftCacheManager.create(dbName: 'my_app_cache');

  final ndkConfig = NdkConfig(
    cache: db,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
```

> **Tip:** A simple way to keep your own entities is to use a factory method to convert ndk events to your own entities.

```dart tip: conversion - glue code
/// from camelus.app - nostr_note_model.dart
class NostrNoteModel extends NostrNote {
  ...

  // convert from ndk event to your own entity with additional fields
  factory NostrNoteModel.fromNDKEvent(Nip01Event nip01event) {
    final myTags =
        nip01event.tags.map((tag) => NostrTagModel.fromJson(tag)).toList();

    return NostrNoteModel(
      id: nip01event.id,
      pubkey: nip01event.pubKey,
      created_at: nip01event.createdAt,
      kind: nip01event.kind,
      content: nip01event.content,
      sig: nip01event.sig,
      tags: myTags,
      sig_valid: nip01event.validSig,
      sources: nip01event.sources,
    );
  }
  ...
}
```

## Blob cache

Conceptually a *local Blossom server* without the network layer: the API mirrors a remote Blossom server's surface (`saveBlob`, `getBlob`, `hasBlob`, `listBlobs`, `removeBlob`) and reuses the same entities (`BlobDescriptor`, `BlobResponse`).

If you don't configure `blobCache`, NDK falls back to an in-memory `IdbBlobCacheManager` (one per `Ndk`, lost on process exit). Pass your own factory for persistence.

### Native: persistent cache

Use `idb_io` (or [`idb_sqflite`](https://pub.dev/packages/idb_sqflite) for cross-process safety):

```dart
import 'package:idb_shim/idb_io.dart';
import 'package:ndk/ndk.dart';

final ndk = Ndk(
  NdkConfig(
    eventVerifier: Bip340EventVerifier(),
    cache: MemCacheManager(),
    blobCache: IdbBlobCacheManager(
      factory: getIdbFactoryIo()!,
      dbName: 'my_app_blob_cache',
    ),
  ),
);
```

### Web: persistent cache

```dart
import 'package:idb_shim/idb_browser.dart';
import 'package:ndk/ndk.dart';

final ndk = Ndk(
  NdkConfig(
    eventVerifier: Bip340EventVerifier(),
    cache: MemCacheManager(),
    blobCache: IdbBlobCacheManager(
      factory: getIdbFactory()!,
      dbName: 'my_app_blob_cache',
    ),
  ),
);
```

### Opting out

```dart
final ndk = Ndk(
  NdkConfig(
    eventVerifier: Bip340EventVerifier(),
    cache: MemCacheManager(),
    blobCache: const NoopBlobCacheManager(),
  ),
);
```

### How Blossom uses the cache

Once configured, the cache is consulted automatically by [Blossom](/usecases/blossom.md):

| Operation | Cache behaviour |
|---|---|
| `getBlob(sha256)` | check cache → on miss, fetch from server → save to cache |
| `downloadBlobToFile(...)` | check cache → on hit write bytes to file ; on miss stream from server (no auto-cache, would defeat streaming) |
| `uploadBlob(data)` | save to cache **before** the upload (local-first — the cache reflects what the user has, regardless of server outcome) |
| `uploadBlobFromFile(...)` | no auto-cache (streaming) |
| `deleteBlob(sha256)` | invalidates the cached entry |

`getBlob` and `uploadBlob` accept `cacheWrite: false` to skip the save step for one-off operations:

```dart
await ndk.blossom.getBlob(
  sha256: hash,
  serverUrls: [...],
  cacheWrite: false,
);
```

### Direct cache access

The cache is exposed via `ndk.config.blobCache`:

```dart
final cache = ndk.config.blobCache!;

await cache.saveBlob(data: bytes, mimeType: 'image/png');
final all = await cache.listBlobs();
final size = await cache.getTotalSize();
await cache.removeBlob(sha);
```

### Implementing your own backend

Implement `BlobCacheManager` directly and pass it as `blobCache`.

> **Heads up:** the cache has no eviction or quota — it grows indefinitely. Apps caching large media should plan their own cleanup.
