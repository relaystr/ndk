/// Auto-platform Nostr event signer that uses the best implementation
/// for the current platform.
///
/// On web: uses [WebEventSigner] (fast JS crypto via @noble/curves)
/// On native (mobile/desktop): uses [Bip340EventSigner] (pure Dart)
///
/// Pair with [NdkEventSignerFactory] in [NdkConfig.eventSignerFactory] to
/// wire it into NDK's account/signer creation flow.
///
/// The conditional export below works like this:
/// - Web compiler sees `dart.library.js_interop` → loads `ndk_event_signer_web.dart`
/// - Native compiler does not → falls back to `ndk_event_signer_native.dart`
library;

export 'src/ndk_event_signer_native.dart'
    if (dart.library.js_interop) 'src/ndk_event_signer_web.dart';
