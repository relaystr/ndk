---
title: Getting started
icon: rocket
order: 100
---

# Getting started with NDK

## Install

Ndk has a core package `ndk` and optional packages like `amber` and `objectbox`

```bash
flutter pub add ndk
```

## Import

```dart
import 'package:ndk/ndk.dart';
```

## Usage

!!!
If you code with AI then your AI must read https://github.com/relaystr/ndk/blob/master/AI_GUIDE.md
!!!

!!!
We strongly recommend using `RustEventVerifier()` for client applications. It uses a separate thread for signature verification and is therefore more performant. \
!!!

```dart
import 'package:ndk/ndk.dart';

// init
final ndk = Ndk(
  NdkConfig(
    eventVerifier: RustEventVerifier(),
    cache: MemCacheManager(),
  ),
);

// usecase - query
final response = ndk.requests.query(
  filters: [
    Filter(
      authors: ['hexPubkey']
      kinds: [Nip01Event.TEXT_NODE_KIND],
      limit: 10,
    ),
  ],
);

// result
await for (final event in response.stream) {
  print(event);
}
```

[!ref create user accounts/login](/usecases/accounts.md)

$~~~~~~~~~~~$

## Install

```bash
flutter pub add ndk_amber
```

## Import

```dart
import 'package:ndk_amber/ndk_amber.dart';
```
