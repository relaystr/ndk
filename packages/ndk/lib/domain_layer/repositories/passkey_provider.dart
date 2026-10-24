import 'dart:typed_data';

/// A credential returned after required user verification. PRF may be unsupported.
class PasskeyCredential {
  final Uint8List credentialId;

  /// Transferred to the caller, which clears this mutable buffer after use.
  final Uint8List? prfOutput;

  final Uint8List? userHandle;
  final bool? prfEnabled;

  PasskeyCredential({
    required this.credentialId,
    this.prfOutput,
    this.userHandle,
    this.prfEnabled,
  });
}

/// Platform WebAuthn operations scoped to the supplied relying party.
///
/// Implementations must require user verification and register discoverable
/// resident credentials. They must evaluate `prfInput` through WebAuthn PRF,
/// use trusted platform/browser ceremonies, and propagate cancellation without
/// retrying or creating a credential. This is local key derivation, not a
/// server-side authentication proof. Authentication without an ID uses account discovery.
abstract class PasskeyProvider {
  Future<PasskeyCredential> register({
    required String rpId,
    required String rpName,
    required String userName,
    required Uint8List challenge,
    required Uint8List userId,
    required Uint8List prfInput,
    List<Uint8List> excludeCredentialIds = const [],
  });

  Future<PasskeyCredential> authenticate({
    required String rpId,
    required Uint8List challenge,
    required Uint8List? prfInput,
    Uint8List? credentialId,
  });
}
