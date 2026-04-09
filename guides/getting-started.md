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

## Install

```bash
flutter pub add ndk_rust_verifier
flutter pub add ndk_amber
```

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
