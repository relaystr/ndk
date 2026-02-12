# ndk_rust_verifier

Nostr event verifier written in rust compatible with dart_ndk.

Main package: [🔗 Dart Nostr Development Kit (NDK)](https://pub.dev/packages/ndk)

## web no longer supported!

## How to build the rust_verifier from source [library development]

### normal build

```shell
flutter_rust_bridge_codegen generate
```

upgrade

```shell
cargo install flutter_rust_bridge_codegen && flutter_rust_bridge_codegen generate
```

### web build

```shell
flutter_rust_bridge_codegen build-web
```

RUN: `flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp`
