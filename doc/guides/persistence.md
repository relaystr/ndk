---
icon: database
order: 98
---

Ndk comes with several database offerings. The simplest is the `MemCacheManager` which is an in-memory cache. This is useful for testing and small applications.

If you are building a real app, prefer a persistent cache backend. NDK stores events, delivery state, and decrypted payload sidecars in the configured cache backend.

For a behavioral overview of how the cache works from an app perspective, see [Cache Behavior](/guides/cache-behavior.md).

Available databases:

- `MemCacheManager`
- [`DbObjectBox`](https://pub.dev/packages/ndk_objectbox)
- [`SembastCacheManager`](https://pub.dev/packages/sembast_cache_manager)
- [`DriftCacheManager`](https://pub.dev/packages/ndk_drift)

## Which cache backend to use

### `MemCacheManager`

Best when:

- writing tests
- prototyping quickly
- building command-line tools or short-lived processes
- you do not need cache state to survive app restart

Why:

- simplest setup
- fastest to get running
- keeps all cache behavior while the process is alive

Limitations:

- all events, delivery state, and decrypted payload sidecars are lost on restart

### `SembastCacheManager`

Best when:

- you want a simple persistent backend with minimal setup
- you want one option that works well across Dart and Flutter targets
- you want persistent local-first behavior without adding a heavier database stack

Why:

- easy to integrate
- good default choice for many apps
- supports persistent cache behavior, including delivery recovery after restart

Good fit:

- small to medium apps
- apps where simplicity matters more than squeezing maximum database performance

### `DriftCacheManager`

Best when:

- your app already uses Drift or SQLite
- web cache performance is especially important for your app
- you want stronger SQL-style querying and schema control
- you want one persistent backend that fits naturally into a larger app data layer

Why:

- highest-performing web cache backend in NDK based on project performance testing
- good fit for apps that already think in terms of SQLite tables and migrations
- easier choice if your app team is already comfortable with Drift tooling

Good fit:

- medium to larger apps
- web apps with heavier cache usage
- apps with an existing SQLite-centric architecture

### `DbObjectBox`

Best when:

- you want a persistent backend optimized around a dedicated embedded database
- you expect large local datasets and care about read/write performance
- you are comfortable bringing in a more specialized storage dependency

Why:

- good option for high-volume local persistence
- good fit for apps where the NDK cache is a substantial part of the local data layer

Good fit:

- larger apps
- apps with heavy local event storage needs

## Practical recommendation

If you just want a good default:

- start with `SembastCacheManager`

If your app already uses SQLite/Drift heavily:

- use `DriftCacheManager`

If web performance is your main concern:

- use `DriftCacheManager`

If you need maximum simplicity and do not care about restart persistence:

- use `MemCacheManager`

If the cache is large and central to your app and you want a dedicated embedded database:

- evaluate `DbObjectBox`

> **Tip:** You can use a hybrid approach:
>
> - use `DriftCacheManager` when the detected platform is web
> - use `DbObjectBox` on non-web platforms
>
> This is a good fit when:
>
> - you want the strongest web cache performance
> - you want ObjectBox for native and desktop persistence
> - you are comfortable selecting the backend at runtime based on platform

If you want your own database, you need to implement the `CacheManager` interface. Contributions for more database implementations are welcome!

Its recommended to use the database only for ndk and spin up a secondary db for your own app data.

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
