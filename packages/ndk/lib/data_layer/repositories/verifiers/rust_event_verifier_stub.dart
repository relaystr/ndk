import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_verifier.dart';

/// Stub implementation of [RustEventVerifier] for platforms that don't support FFI (e.g., web).
///
/// This class throws [UnsupportedError] for all operations since Rust FFI
/// is not available on web platforms.
class RustEventVerifier implements EventVerifier {
  /// Creates a new instance of [RustEventVerifier].
  ///
  /// Note: On web platforms, this verifier is not functional and will throw
  /// [UnsupportedError] when [verify] is called.
  RustEventVerifier();

  @override
  Future<bool> verify(Nip01Event event) async {
    throw UnsupportedError(
      'RustEventVerifier is not available on this platform. '
      'Use Bip340EventVerifier instead for web platforms.',
    );
  }
}
