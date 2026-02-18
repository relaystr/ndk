/// Fast web-based Nostr event verifier using native Web Crypto APIs.
///
/// This package provides a web-only implementation of EventVerifier that
/// uses nostr-tools via JS interop for fast signature verification.
library;

export 'src/web_event_verifier_stub.dart'
    if (dart.library.html) 'src/web_event_verifier_web.dart';
