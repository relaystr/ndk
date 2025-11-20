import '../entities/nip_01_event.dart';

abstract class EventSigner {
  Future<void> sign(Nip01Event event);

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
}
