---
icon: database
order: 98
---

Ndk comes with several database offerings. The simplest is the `MemCacheManager` which is an in-memory cache. This is useful for testing and small applications.

Available databases:

- `MemCacheManager`
- [`DbObjectBox`](https://pub.dev/packages/ndk_objectbox)
- [`IsarCacheManager`](https://pub.dev/packages/ndk_isar)

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
