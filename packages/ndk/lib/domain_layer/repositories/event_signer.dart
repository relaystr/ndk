import '../entities/nip_01_event.dart';

abstract class EventSigner {
  Future<void> sign(Nip01Event event);

  String getPublicKey();

  Future<String?> decrypt(String msg, String destPubKey, {String? id});

  Future<String?> encrypt(String msg, String destPubKey, {String? id});

  bool canSign();

  Future<String?> encryptNip44({
    required String plaintext,
    required String userPubkey,
    required String recipientPubKey,
  });

  Future<String?> decryptNip44({
    required String ciphertext,
    required String userPubkey,
    required String senderPubKey,
  });
}
