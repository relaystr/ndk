import 'package:ndk/ndk.dart';

/// Stub implementation used when neither `dart:io` nor web interop is available.
EventVerifier createPlatformEventVerifier() {
  throw UnsupportedError(
    'PlatformEventVerifier is not available on this platform.',
  );
}
