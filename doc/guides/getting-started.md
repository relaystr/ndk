---

icon: rocket
level: 100
---
# Getting started

## Prerequisites

- dart SDK

### Prerequisites `ndk_rust_verifier`

- android SDK (also for desktop builds)
- flutter SDK
- rust ( + toolchain for target)

Rust toolchain android:

```bash
rustup target add \
    aarch64-linux-android \
    armv7-linux-androideabi \
    x86_64-linux-android \
    i686-linux-android
```

Rust toolchain ios:

```bash
# 64 bit targets (real device & simulator):
rustup target add aarch64-apple-ios x86_64-apple-ios
# New simulator target for Xcode 12 and later
rustup target add aarch64-apple-ios-sim
# 32 bit targets (you probably don't need these):
rustup target add armv7-apple-ios i386-apple-ios
```

## Install

Ndk has a core package `ndk` and optional packages like `rust_verifier` and `amber`.

```bash
flutter pub add ndk
```

Optional:

```bash
flutter pub add ndk_rust_verifier
flutter pub add ndk_amber
```

## Import

```dart
import 'package:ndk/ndk.dart';
```

Optional:

```dart
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';
import 'package:ndk_amber/ndk_amber.dart';
```

## Usage

> **more [examples 🔗](https://pub.dev/packages/ndk/example)**

```dart
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

// init
final ndk = Ndk(
  NdkConfig(
    eventVerifier: RustEventVerifier(),
    cache: MemCacheManager(),
  ),
);

// query
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

> We strongly recommend using `RustEventVerifier()` for client applications. It uses a separate thread for signature verification and is therefore more performant.
> $~~~~~~~~~~~$