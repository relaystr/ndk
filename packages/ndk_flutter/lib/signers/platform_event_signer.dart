/// Platform-aware event signer that uses the best implementation
/// for the current platform.
///
/// On web: uses [WebEventSigner] (fast JS crypto via @noble/curves)
/// On native: uses [Bip340EventSigner] (pure Dart)
library;

export 'src/platform_event_signer_stub.dart'
    if (dart.library.js_interop) 'src/platform_event_signer_web.dart';
