import 'package:ndk/ndk.dart';

class Nip07EventSigner implements EventSigner {
  @override
  bool canSign() {
    return false;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  String getPublicKey() {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  Future<String> getPublicKeyAsync() {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<void> sign(Nip01Event event) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }
}
