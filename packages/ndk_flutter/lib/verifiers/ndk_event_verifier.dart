import 'package:ndk/ndk.dart';

import 'ndk_event_verifier_stub.dart'
    if (dart.library.io) 'ndk_event_verifier_native.dart'
    if (dart.library.js_interop) 'ndk_event_verifier_web.dart';

/// A platform-aware event verifier that automatically selects the best
/// implementation for the current platform.
///
/// - On **web**: uses [WebEventVerifier], which leverages native Web Crypto APIs
///   for fast signature verification.
/// - On **native platforms** (Android, iOS, desktop): uses [RustEventVerifier].
///
/// This removes the need for conditional imports or platform checks in
/// application code.
///
/// ```dart
/// final ndk = Ndk(
///   NdkConfig(
///     eventVerifier: NdkEventVerifier(),
///     cache: MemCacheManager(),
///   ),
/// );
/// ```
class NdkEventVerifier implements EventVerifier {
  final EventVerifier _delegate;

  NdkEventVerifier() : _delegate = createNdkEventVerifier();

  @override
  Future<bool> verify(Nip01Event event) => _delegate.verify(event);
}
