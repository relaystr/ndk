/// Quantum-secure event signer with platform-specific implementations.
///
/// On native platforms (Android, iOS, Linux, macOS, Windows), this uses FFI
/// to call Rust code for CRYSTALS-Dilithium signing.
///
/// On web platforms, this exports a stub that throws [UnsupportedError].
library;

export 'qs_rust_event_signer_stub.dart'
    if (dart.library.ffi) 'qs_rust_event_signer_native.dart';
