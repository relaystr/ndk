import '../../../domain_layer/repositories/nip44_cryptography.dart';
import '../../../shared/nips/nip44/nip44.dart';

class DefaultNip44Cryptography implements Nip44Cryptography {
  const DefaultNip44Cryptography();

  @override
  Future<String> encrypt({
    required String plaintext,
    required String privateKey,
    required String publicKey,
  }) {
    return Nip44.encryptMessage(plaintext, privateKey, publicKey);
  }

  @override
  Future<String> decrypt({
    required String ciphertext,
    required String privateKey,
    required String publicKey,
  }) {
    return Nip44.decryptMessage(ciphertext, privateKey, publicKey);
  }
}
