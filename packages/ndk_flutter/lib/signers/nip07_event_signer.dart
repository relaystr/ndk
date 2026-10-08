/// NIP-07 browser-extension signer for Nostr.
library;

export 'src/nip07_event_signer_stub.dart'
    if (dart.library.js_interop) 'src/nip07_event_signer_web.dart';
