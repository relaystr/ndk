import 'web_event_signer_web.dart';

/// Web implementation of PlatformEventSigner.
/// Uses [WebEventSigner] for fast crypto via JS interop.
typedef PlatformEventSigner = WebEventSigner;
