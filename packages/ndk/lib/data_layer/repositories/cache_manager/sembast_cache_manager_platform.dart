/// Exports the correct Sembast platform implementation based on the target platform.
///
/// This file uses conditional exports to load the appropriate implementation:
/// - On native platforms (Android, iOS, macOS, Linux, Windows): uses sembast_io
/// - On web platforms: uses sembast_web
/// - Fallback: throws UnsupportedError
///
/// The web implementation uses dart.library.js_interop for WASM compatibility.
library;

export 'sembast_cache_manager_stub.dart'
    if (dart.library.io) 'sembast_cache_manager_io.dart'
    if (dart.library.js_interop) 'sembast_cache_manager_web.dart';
