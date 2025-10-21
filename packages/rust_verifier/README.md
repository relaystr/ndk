# ndk_rust_verifier

Nostr event verifier written in rust compatible with dart_ndk.

Main package: [🔗 Dart Nostr Development Kit (NDK)](https://pub.dev/packages/ndk)

# Setup Web

1. Copy `/pkg/` from [`/web/pkg/`](https://github.com/relaystr/ndk/tree/master/packages/rust_verifier/web) into your `project_root/web` folder. => `project_root/web/pkg/`

2. Run with `flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp`

## Performance on Web

The verifier runs in `wasm` to enable threading your server must send the following headers:

```
Cross-Origin-Embedder-Policy    credentialless
or
require-corp
```

and

```
Cross-Origin-Opener-Policy  same-origin
```

you can read more about it in the [flutter docs](https://docs.flutter.dev/platform-integration/web/wasm#serve-the-built-output-with-an-http-server), [flutter rust bridge](https://cjycode.com/flutter_rust_bridge/manual/miscellaneous/web-cross-origin).

When enabled the verification is done in a background thread/worker.

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
