import 'package:flutter/foundation.dart';
import 'package:ndk/ndk.dart';

import 'web_event_verifier.dart';

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

  PlatformEventVerifier() : _delegate = _createVerifier();

  static EventVerifier _createVerifier() {
    if (kIsWeb) return WebEventVerifier();
    return RustEventVerifier();
  }

  @override
  Future<bool> verify(Nip01Event event) => _delegate.verify(event);
}
