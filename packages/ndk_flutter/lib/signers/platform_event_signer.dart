/// Platform-aware event signer that uses the best implementation
/// for the current platform.
///
/// On web: uses [WebEventSigner] (fast JS crypto via @noble/curves)
/// On native (mobile/desktop): uses [Bip340EventSigner] (pure Dart)
///
/// The conditional export below works like this:
/// - Web compiler sees `dart.library.js_interop` → loads `platform_event_signer_web.dart`
/// - Native compiler does not → falls back to `platform_event_signer_native.dart`
library;

export 'src/platform_event_signer_native.dart'
    if (dart.library.js_interop) 'src/platform_event_signer_web.dart';
