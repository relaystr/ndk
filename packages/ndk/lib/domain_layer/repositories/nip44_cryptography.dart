abstract class Nip44Cryptography {
  Future<String> encrypt({
    required String plaintext,
    required String privateKey,
    required String publicKey,
  });

  Future<String> decrypt({
    required String ciphertext,
    required String privateKey,
    required String publicKey,
  });
}
