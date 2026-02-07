import '../entities/nip_01_event.dart';

abstract class EventSigner {
  /// Signs the given event and returns the signed event
  ///
  /// [timeout] is optional and only used by remote signers (e.g., Nip46EventSigner).
  /// Local signers will ignore this parameter.
  Future<Nip01Event> sign(Nip01Event event, {Duration? timeout});

  String getPublicKey();

  @Deprecated('Use nip44 decrypt instead. Deprecated by nostr spec. (nip04)')
  Future<String?> decrypt(String msg, String destPubKey,
      {String? id, Duration? timeout});

  @Deprecated('Use nip44 encrypt instead. Deprecated by nostr spec. (nip04)')
  Future<String?> encrypt(String msg, String destPubKey,
      {String? id, Duration? timeout});

  bool canSign();

  /// Encrypts plaintext using NIP-44
  ///
  /// [timeout] is optional and only used by remote signers (e.g., Nip46EventSigner).
  /// Local signers will ignore this parameter.
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
    Duration? timeout,
  });

  /// Decrypts ciphertext using NIP-44
  ///
  /// [timeout] is optional and only used by remote signers (e.g., Nip46EventSigner).
  /// Local signers will ignore this parameter.
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
    Duration? timeout,
  });
}
