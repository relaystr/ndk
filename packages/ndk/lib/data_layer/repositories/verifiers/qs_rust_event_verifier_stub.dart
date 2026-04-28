import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_verifier.dart';

/// Stub implementation of [QsRustEventVerifier] for platforms that don't support FFI (e.g., web).
///
/// All operations throw [UnsupportedError] since Rust FFI is not available on web platforms.
class QsRustEventVerifier implements EventVerifier {
  final int level;

  QsRustEventVerifier({this.level = 2});

  @override
  Future<bool> verify(Nip01Event event) {
    throw UnsupportedError(
      'QsRustEventVerifier is not available on this platform. '
      'FFI is not supported on web.',
    );
  }
}
