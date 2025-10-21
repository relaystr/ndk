# ndk_rust_verifier

Nostr event verifier written in rust compatible with dart_ndk.

Main package: [🔗 Dart Nostr Development Kit (NDK)](https://pub.dev/packages/ndk)

# Setup Web

1. Copy `/pkg/` form `/web/pkg/` into your `project_root/web` folder. => `project_root/web/pkg/`
2. Run with `flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp`

## How to build

### normal build

```
flutter_rust_bridge_codegen generate
```

upgrade

```
cargo install flutter_rust_bridge_codegen && flutter_rust_bridge_codegen generate
```

### web build

```
flutter_rust_bridge_codegen build-web
```

RUN: `flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp`
