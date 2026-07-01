---
title: Getting started
icon: rocket
order: 100
---

# Getting started with NDK

NDK ships as two packages that work together:

- **`ndk`** — the core library: relay gossip (inbox/outbox), requests, caching, signers, and high-level usecases. Pure Dart, no Flutter dependency.
- **`ndk_flutter`** — Flutter integration on top of `ndk`: a platform-aware event verifier, Flutter signers, login persistence, and ready-to-use widgets.

If you are building a **Flutter app** (the common case), start with `ndk_flutter` — it depends on `ndk` and gives you the best defaults for each platform automatically. Use the core `ndk` package alone only for pure-Dart projects (CLIs, servers).

!!!
Looking for a ready-to-run tool instead of a library? NDK also ships a prebuilt **CLI** for querying relays and managing wallets. See [the CLI guide](./cli.md).
!!!

## Flutter apps (recommended)

### Install

```bash
flutter pub add ndk ndk_flutter
```

### Import

```dart
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
```

### Initialize

`NdkEventVerifier` (from `ndk_flutter`) is the recommended verifier for Flutter apps. It automatically selects the best backend for the current platform:

- **Web** → `WebEventVerifier` (native Web Crypto APIs)
- **Android / iOS / desktop** → `RustEventVerifier` (offloaded to a separate thread)

This means you write one line and get the optimal verifier everywhere, with no conditional imports or platform checks.

```dart
final ndk = Ndk(
  NdkConfig(
    eventVerifier: NdkEventVerifier(),
    cache: MemCacheManager(),
  ),
);
```

!!!
If you code with AI then your AI must read https://github.com/relaystr/ndk/blob/master/AI_GUIDE.md
!!!

#### Prerequisites for native platforms

On native platforms `NdkEventVerifier` uses the Rust verifier, which requires the Rust toolchain. **On web, no Rust toolchain is needed** — it falls back to Web Crypto.

Install Rust:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

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

### Query events

```dart
final response = ndk.requests.query(
  filters: [
    Filter(
      authors: ['hexPubkey'],
      kinds: [Nip01Event.kTextNodeKind],
      limit: 10,
    ),
  ],
);

await for (final event in response.stream) {
  print(event);
}
```

[!ref create user accounts/login](/usecases/accounts.md)

### Widgets & login persistence

`ndk_flutter` gives you ready-to-use Nostr widgets and helpers so you don't have to wire accounts/signers yourself:

- `NdkFlutter.restoreAccountsState()` / `saveAccountsState()` — persist and restore logged accounts to `flutter_secure_storage`
- Widgets: `NLogin`, `NUserProfile`, `NName`, `NPicture`, `NBanner`, `NSwitchAccount`, ...

The widgets rely on Flutter's internationalization. Add the delegate to your `MaterialApp`:

```dart
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_flutter;

MaterialApp(
  localizationsDelegates: [
    ndk_flutter.AppLocalizations.delegate,
  ],
);
```

Then wrap `ndk` and restore saved accounts (typically before `runApp`), and save again whenever the auth state changes:

```dart
final ndkFlutter = NdkFlutter(ndk: ndk);

await ndkFlutter.restoreAccountsState();

// ...later, whenever login/logout/switch happens:
await ndkFlutter.saveAccountsState();
```

```dart
// available widgets
NLogin(ndkFlutter: ndkFlutter);
NUserProfile(ndkFlutter: ndkFlutter);
NName(ndkFlutter: ndkFlutter);
NPicture(ndkFlutter: ndkFlutter);
NBanner(ndkFlutter: ndkFlutter);
NSwitchAccount(ndkFlutter: ndkFlutter);
```

By default these widgets target the logged-in user; pass a `pubkey` to render any other user.

[!ref widgets](https://pub.dev/packages/ndk_flutter)

---

## Pure Dart (non-Flutter)

For Dart CLIs, servers, or any project without a Flutter dependency, use only the core `ndk` package.

### Install

```bash
dart pub add ndk
```

### Usage

```dart
import 'package:ndk/ndk.dart';

final ndk = Ndk(
  NdkConfig(
    eventVerifier: RustEventVerifier(),
    cache: MemCacheManager(),
  ),
);

final response = ndk.requests.query(
  filters: [
    Filter(
      authors: ['hexPubkey'],
      kinds: [Nip01Event.kTextNodeKind],
      limit: 10,
    ),
  ],
);

await for (final event in response.stream) {
  print(event);
}
```

!!!
`RustEventVerifier()` requires the Rust toolchain (see the prerequisites above). For a pure-Dart setup with no native dependencies, use `Bip340EventVerifier()` instead — it is slower but needs no Rust.
!!!
