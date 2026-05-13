/// Quantum-secure event verifier with platform-specific implementations.
///
/// On native platforms (Android, iOS, Linux, macOS, Windows), this uses FFI
/// to call Rust code for CRYSTALS-Dilithium verification.
///
/// On web platforms, this exports a stub that throws [UnsupportedError].
library;

export 'qs_rust_event_verifier_stub.dart'
    if (dart.library.ffi) 'qs_rust_event_verifier_native.dart';
