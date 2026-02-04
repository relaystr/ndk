import 'package:ndk/ndk.dart';

/// Stub implementation for non-web platforms.
/// WebEventVerifier is only available on web platforms.
class WebEventVerifier implements EventVerifier {
  WebEventVerifier() {
    throw UnsupportedError(
      'WebEventVerifier is only available on web platforms. '
      'Use Bip340EventVerifier or RustEventVerifier for native platforms.',
    );
  }

  @override
  Future<bool> verify(Nip01Event event) {
    throw UnsupportedError(
      'WebEventVerifier is only available on web platforms.',
    );
  }
}
