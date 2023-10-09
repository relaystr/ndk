import 'package:bip340/bip340.dart' as bip340;
import 'helpers.dart';

class Bip340 {

  /// [message] is a hex string
  /// [privateKey] is a  32-bytes hex encoded string
  /// returns a hex string
  static String sign(String message, String privateKey) {
    final aux = Helpers.getSecureRandomHex(32);
    return bip340.sign(privateKey, message, aux);
  }

  /// [message] is a hex string
  /// [signature] is a hex string
  /// [publicKey] is a 32-bytes hex-encoded string
  /// true if the signature is valid otherwise false
  static bool verify(String message, String signature, String? publicKey) {
    return bip340.verify(publicKey, message, signature);
  }

  /// [privateKey] is a 32-bytes hex-encoded string
  /// returns the public key in form of 32-bytes hex-encoded string
  static String getPublicKey(String privateKey) {
    return bip340.getPublicKey(privateKey);
  }

  /// generates a new private key with a secure random generator
  static KeyPair generatePrivateKey() {
    final privKey = Helpers.getSecureRandomHex(32);
    final pubKey = getPublicKey(privKey);

    final privKeyHr = Helpers.encodeBech32(privKey, 'nsec');
    final pubKeyHr = Helpers.encodeBech32(pubKey, 'npub');

    return KeyPair(privKey, pubKey, privKeyHr, pubKeyHr);
  }
}

class KeyPair {
  /// [privateKey] is a 32-bytes hex-encoded string
  String? privateKey;

  /// [publicKey] is a 32-bytes hex-encoded string
  final String publicKey;

  /// [privateKeyHr] is a human readable private key e.g. nsec
  String? privateKeyHr;

  /// [publicKeyHr] is a human readable public key e.g. npub
  String? publicKeyHr;

  KeyPair(this.privateKey, this.publicKey, this.privateKeyHr, this.publicKeyHr);

  KeyPair.justPublicKey(this.publicKey);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyPair &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey;

  @override
  int get hashCode => publicKey.hashCode;
}
