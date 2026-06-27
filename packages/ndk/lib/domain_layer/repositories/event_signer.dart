import '../entities/nip_01_event.dart';
import '../entities/pending_signer_request.dart';

/// Factory for creating [EventSigner] instances.
///
/// If [LocalEventSignerFactory.create] is called without a `publicKey`,
/// implementations must derive it from the `privateKey`.
abstract class LocalEventSignerFactory {
  /// Creates an EventSigner instance.
  ///
  /// If [publicKey] is null, implementations MUST derive it from [privateKey].
  /// At least one of [privateKey] or [publicKey] must be provided!
  EventSigner create({
    String? privateKey,
    String? publicKey,
  });

  /// Derives a public key from a private key.
  /// Implementations MUST provide the derivation logic.
  String derivePublicKey(String privateKey);

  /// Generates a new keypair.
  /// Returns a record with (privateKey, publicKey).
  (String privateKey, String publicKey) generateKeyPair();

  /// Generates a new EventSigner with a fresh keypair.
  EventSigner createWithNewKeyPair() {
    final (privateKey, publicKey) = generateKeyPair();
    return create(privateKey: privateKey, publicKey: publicKey);
  }
}

abstract class EventSigner {
  /// Signs the given event and returns the signed event
  Future<Nip01Event> sign(Nip01Event event);

  String getPublicKey();

  @Deprecated('Use nip44 decrypt instead. Deprecated by nostr spec. (nip04)')
  Future<String?> decrypt(String msg, String destPubKey, {String? id});

  @Deprecated('Use nip44 encrypt instead. Deprecated by nostr spec. (nip04)')
  Future<String?> encrypt(String msg, String destPubKey, {String? id});

  bool canSign();

  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  });

  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  });

  /// Stream of pending requests waiting for user approval.
  /// Emits whenever the list changes (request added, completed, or cancelled).
  ///
  /// For local signers (like Bip340EventSigner), this will always emit an empty list.
  /// For remote signers (NIP-46, NIP-07, NIP-55), this will emit the current
  /// pending requests that are waiting for user approval.
  Stream<List<PendingSignerRequest>> get pendingRequestsStream;

  /// Current list of pending requests (synchronous snapshot).
  ///
  /// Returns an empty list for local signers.
  List<PendingSignerRequest> get pendingRequests;

  /// Cancel a pending request by its ID.
  ///
  /// Returns true if the request was found and cancelled.
  /// The caller waiting on that request will receive a [SignerRequestCancelledException].
  ///
  /// Note: This is a "soft cancel" - the remote signer (bunker, browser extension, etc.)
  /// may still have the request pending. If the user approves on the remote side
  /// after cancellation, the result will be ignored.
  bool cancelRequest(String requestId);

  /// Dispose of resources used by the signer.
  ///
  /// Call this when the signer is no longer needed to avoid memory leaks.
  Future<void> dispose();
}
