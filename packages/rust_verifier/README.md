# ndk_rust_verifier

Nostr event verifier written in rust compatible with dart_ndk.

Main package: [🔗 Dart Nostr Development Kit (NDK)](https://pub.dev/packages/ndk)

# Setup Web

1. Copy `/pkg/` from [`/web/pkg/`](https://github.com/relaystr/ndk/tree/master/packages/rust_verifier/web) into your `project_root/web` folder. => `project_root/web/pkg/`

2. Run with `flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp`

```text
project_root/
└── web/
    └── pkg/
        ├── rust_lib_ndk_bg.wasm
        └── rust_lib_ndk.js
```

!!!
The `RustEventVerifier()` object must only be created once!
Use a singleton pattern to ensure only one instance is created
!!!

## Performance on Web

The verifier runs in `wasm` to enable threading your server must send the following headers:

```shell
Cross-Origin-Embedder-Policy: credentialless or require-corp
```

and

```shell
Cross-Origin-Opener-Policy: same-origin
```

you can read more about it in the [flutter docs](https://docs.flutter.dev/platform-integration/web/wasm#serve-the-built-output-with-an-http-server), [flutter rust bridge](https://cjycode.com/flutter_rust_bridge/manual/miscellaneous/web-cross-origin).

When enabled the verification is done in a background thread/worker.

### Alternative: COI Service Worker

If you don't have control over your server headers (e.g., GitHub Pages, static hosting), you can use [coi-serviceworker](https://github.com/gzuidhof/coi-serviceworker) to enable cross-origin isolation client-side.

1. Download `coi-serviceworker.js` from the repository
2. Place it in your `web/` folder
3. Add this script tag to your `web/index.html` before other scripts:

```html
<script src="coi-serviceworker.js"></script>
```

This service worker will automatically add the required COOP/COEP headers to enable SharedArrayBuffer and multi-threading in the browser.

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

if that fails, try

```shell
flutter_rust_bridge_codegen build-web -c rust_builder/rust/

wasm-pack build --release --target no-modules --out-dir ../../web/pkg
```

https://github.com/fzyzcjy/flutter_rust_bridge/issues/2914#issuecomment-3478076794

```shell
flutter_rust_bridge_codegen build-web -c rust_builder/rust/ --wasm-pack-rustflags "-Ctarget-feature=+atomics -Clink-args=--shared-memory -Clink-args=--max-memory=1073741824 -Clink-args=--import-memory -Clink-args=--export=__wasm_init_tls -Clink-args=--export=__tls_size -Clink-args=--export=__tls_align -Clink-args=--export=__tls_base"
```

RUN: `flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp`
