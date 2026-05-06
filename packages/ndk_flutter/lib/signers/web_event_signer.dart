/// Fast web-based Nostr event signer using native Web Crypto APIs.
///
/// This package provides a web-only implementation of EventSigner that
/// uses @noble/curves via JS interop for fast BIP-340 Schnorr signature signing.
library;

export 'src/web_event_signer_stub.dart'
    if (dart.library.js_interop) 'src/web_event_signer_web.dart';
