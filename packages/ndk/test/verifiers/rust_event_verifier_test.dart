import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

void main() {
  group('RustEventVerifier', () {
    late RustEventVerifier verifier;
    late KeyPair keyPair;

    setUp(() {
      verifier = RustEventVerifier();
      keyPair = Bip340.generatePrivateKey();
    });

    test('verifies valid event', () async {
      // Create an event (id is calculated automatically in constructor)
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 1,
        tags: [],
        content: 'hello world',
      );
      // Sign the event
      event.sig = Bip340.sign(event.id, keyPair.privateKey!);

      final result = await verifier.verify(event);
      expect(result, isTrue);
    });

    test('rejects event with invalid signature', () async {
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 1,
        tags: [],
        content: 'hello world',
      );
      // Invalid signature - just change first char
      final validSig = Bip340.sign(event.id, keyPair.privateKey!);
      event.sig = 'a${validSig.substring(1)}';

      final result = await verifier.verify(event);
      expect(result, isFalse);
    });

    test('rejects event with wrong id', () async {
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 1,
        tags: [],
        content: 'hello world',
      );
      final correctId = event.id;
      event.sig = Bip340.sign(correctId, keyPair.privateKey!);
      // Set wrong id after signing
      event.id =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      final result = await verifier.verify(event);
      expect(result, isFalse);
    });

    test('verifies event with tags', () async {
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 1,
        tags: [
          ['e', 'abc123def456789012345678901234567890123456789012345678901234'],
          ['p', keyPair.publicKey],
        ],
        content: 'hello with tags',
      );
      event.sig = Bip340.sign(event.id, keyPair.privateKey!);

      final result = await verifier.verify(event);
      expect(result, isTrue);
    });

    test('verifies event with empty content', () async {
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 1,
        tags: [],
        content: '',
      );
      event.sig = Bip340.sign(event.id, keyPair.privateKey!);

      final result = await verifier.verify(event);
      expect(result, isTrue);
    });

    test('verifies event with unicode content', () async {
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 1,
        tags: [],
        content: '你好世界 🌍 Привет мир',
      );
      event.sig = Bip340.sign(event.id, keyPair.privateKey!);

      final result = await verifier.verify(event);
      expect(result, isTrue);
    });
  });
}
