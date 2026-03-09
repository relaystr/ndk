import 'nip_01_event.dart';

/// Methods that can be called on a signer
enum SignerMethod {
  signEvent('sign_event'),
  getPublicKey('get_public_key'),
  nip04Encrypt('nip04_encrypt'),
  nip04Decrypt('nip04_decrypt'),
  nip44Encrypt('nip44_encrypt'),
  nip44Decrypt('nip44_decrypt'),
  ping('ping'),
  connect('connect');

  /// The NIP-46 protocol string for this method
  final String protocolString;
  const SignerMethod(this.protocolString);
}

/// Represents a pending request waiting for user approval on a signer.
///
/// This is used by signers that require human approval (NIP-46 bunkers,
/// NIP-07 browser extensions, Amber, etc.) to expose their pending
/// operations to the UI.
class PendingSignerRequest {
  /// Unique identifier for this request
  final String id;

  /// The method being called
  final SignerMethod method;

  /// When this request was created
  final DateTime createdAt;

  /// The public key of the signer (the account making the request)
  final String signerPubkey;

  /// The event being signed (only for [SignerMethod.signEvent])
  final Nip01Event? event;

  /// The plaintext being encrypted (only for encrypt methods)
  final String? plaintext;

  /// The ciphertext being decrypted (only for decrypt methods)
  final String? ciphertext;

  /// The counterparty public key (for encrypt/decrypt operations)
  final String? counterpartyPubkey;

  PendingSignerRequest({
    required this.id,
    required this.method,
    required this.createdAt,
    required this.signerPubkey,
    this.event,
    this.plaintext,
    this.ciphertext,
    this.counterpartyPubkey,
  });

  /// Returns plaintext or ciphertext depending on the method.
  /// For encrypt methods, returns plaintext. For decrypt methods, returns ciphertext.
  String? get content => plaintext ?? ciphertext;

  @override
  String toString() =>
      'PendingSignerRequest(id: $id, method: $method, createdAt: $createdAt)';
}
