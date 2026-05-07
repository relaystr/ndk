import 'package:ndk/ndk.dart';

import 'platform_event_verifier_stub.dart'
    if (dart.library.io) 'platform_event_verifier_native.dart'
    if (dart.library.js_interop) 'platform_event_verifier_web.dart';

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
///     eventVerifier: PlatformEventVerifier(),
///     cache: MemCacheManager(),
///   ),
/// );
/// ```
class PlatformEventVerifier implements EventVerifier {
  final EventVerifier _delegate;

  PlatformEventVerifier() : _delegate = createPlatformEventVerifier();

  @override
  Future<bool> verify(Nip01Event event) => _delegate.verify(event);
}
