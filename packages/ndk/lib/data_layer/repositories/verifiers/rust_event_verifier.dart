/// Rust-based event verifier with platform-specific implementations.
///
/// On native platforms (Android, iOS, Linux, macOS, Windows), this uses FFI
/// to call Rust code for high-performance event verification.
///
/// On web platforms, this exports a stub that throws [UnsupportedError].
/// Use [Bip340EventVerifier] instead for web platforms.
library;

export 'rust_event_verifier_stub.dart'
    if (dart.library.ffi) 'rust_event_verifier_native.dart';
