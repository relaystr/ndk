import 'package:ndk/ndk.dart';

class Nip07EventSigner implements EventSigner {
  String? cachedPublicKey;

  Nip07EventSigner({this.cachedPublicKey});

  @override
  bool canSign() {
    return false;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey,
      {String? id, Duration? timeout}) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
    Duration? timeout,
  }) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey,
      {String? id, Duration? timeout}) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
    Duration? timeout,
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
  Future<Nip01Event> sign(Nip01Event event, {Duration? timeout}) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }
}
