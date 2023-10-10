import 'package:dart_ndk/nips/nip01/bip340.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';

void main() {
  group('Bip340', () {
    test('sign and verify', () {
      final keyPair = Bip340.generatePrivateKey();
      const message = 'Hello, World!';
      // message to HEX
      final messageHex = HEX.encode(message.codeUnits);
      final signature = Bip340.sign(messageHex, keyPair.privateKey!);
      expect(Bip340.verify(messageHex, signature, keyPair.publicKey), isTrue);
    });

    test('getPublicKey', () {
      final keyPair = Bip340.generatePrivateKey();
      expect(
          Bip340.getPublicKey(keyPair.privateKey!), equals(keyPair.publicKey));
    });
  });
}
