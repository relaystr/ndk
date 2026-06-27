---
title: Getting started
icon: rocket
order: 100
---

# Getting started with NDK

## Install

NDK has a core package `ndk` and optional companion packages such as
`ndk_flutter`, `ndk_objectbox`, and `ndk_drift`.

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
We strongly recommend using `RustEventVerifier()` for client applications. It uses a separate thread for signature verification and is therefore more performant.

For **Flutter** apps, use `NdkEventVerifier` from the `ndk_flutter` package. It automatically picks `WebEventVerifier` on web (native Web Crypto APIs) and `RustEventVerifier` on native platforms.
!!!

### Prerequisites for using the rust verifier

- rust ( + toolchain for target)

Install Rust:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
````

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

## Core usage

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
flutter pub add ndk_flutter
```

## Import

```dart
import 'package:ndk_flutter/ndk_flutter.dart';
```

Use `ndk_flutter` when you want Flutter-specific integrations such as:

- `NdkEventVerifier`
- `Nip07EventSigner`
- `Nip55EventSigner`
- login and account widgets
