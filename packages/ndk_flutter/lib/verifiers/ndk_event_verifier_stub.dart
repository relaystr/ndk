import 'package:ndk/ndk.dart';

/// Stub implementation used when neither `dart:io` nor web interop is available.
EventVerifier createNdkEventVerifier() {
  throw UnsupportedError('NdkEventVerifier is not available on this platform.');
}
