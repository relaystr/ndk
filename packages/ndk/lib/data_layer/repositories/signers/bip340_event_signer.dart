import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../../shared/nips/nip04/nip04.dart';
import '../../../shared/nips/nip01/bip340.dart';
import '../../../domain_layer/repositories/event_signer.dart';
import '../../../shared/nips/nip44/nip44.dart';

/// Pure Dart Event Signer
class Bip340EventSigner implements EventSigner {
  /// hex private key
  String? privateKey;

  /// hex public key
  String publicKey;

  /// Get a new event signer with the given keys
  Bip340EventSigner({
    required this.privateKey,
    required this.publicKey,
  });

  @override
  Future<void> sign(Nip01Event event) async {
    if (Helpers.isNotBlank(privateKey)) {
      event.sig = Bip340.sign(event.id, privateKey!);
    }
  }

  @override
  String getPublicKey() {
    return publicKey;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    return Nip04.decrypt(privateKey!, destPubKey, msg);
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    return Nip04.encrypt(privateKey!, destPubKey, msg);
  }

  @override
  bool canSign() {
    return Helpers.isNotBlank(privateKey);
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) {
    return Nip44.encryptMessage(
      plaintext,
      privateKey!,
      recipientPubKey,
    );
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) {
    return Nip44.decryptMessage(
      ciphertext,
      privateKey!,
      senderPubKey,
    );
  }
}
