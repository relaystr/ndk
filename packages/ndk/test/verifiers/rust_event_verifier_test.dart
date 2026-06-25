import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

void main() {
  group('RustEventVerifier', () {
    late RustEventVerifier verifier;
    late KeyPair keyPair;

    String _mutateHex(String value) {
      final first = value[0].toLowerCase();
      final replacement = first == 'a' ? 'b' : 'a';
      return '$replacement${value.substring(1)}';
    }

    setUp(() {
      verifier = RustEventVerifier();
      keyPair = Bip340.generatePrivateKey();
    });

    test('verifies valid event', () async {
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create an event (id is calculated automatically in constructor)
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: createdAt,
        kind: 1,
        tags: [],
        content: 'hello world',
        sig: Bip340.sign(
          Nip01Utils.calculateEventIdSync(
            pubKey: keyPair.publicKey,
            createdAt: createdAt,
            kind: 1,
            tags: [],
            content: 'hello world',
          ),
          keyPair.privateKey!,
        ),
      );

      final result = await verifier.verify(event);
      expect(result, isTrue);
    });

    test('rejects event with invalid signature', () async {
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final validSig = Bip340.sign(
        Nip01Utils.calculateEventIdSync(
          pubKey: keyPair.publicKey,
          createdAt: createdAt,
          kind: 1,
          tags: [],
          content: 'hello world',
        ),
        keyPair.privateKey!,
      );

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: createdAt,
        kind: 1,
        tags: [],
        content: 'hello world',
        sig: _mutateHex(validSig),
      );

      final result = await verifier.verify(event);
      expect(result, isFalse);
    });

    test('rejects event with wrong id', () async {
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final correctId = Nip01Utils.calculateEventIdSync(
        pubKey: keyPair.publicKey,
        createdAt: createdAt,
        kind: 1,
        tags: [],
        content: 'hello world',
      );

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: createdAt,
        kind: 1,
        tags: [],
        content: 'hello world',
        sig: Bip340.sign(correctId, keyPair.privateKey!),
        // Set wrong id after signing
        id: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );

      final result = await verifier.verify(event);
      expect(result, isFalse);
    });

    test('verifies event with tags', () async {
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final tags = [
        ['e', 'abc123def456789012345678901234567890123456789012345678901234'],
        ['p', keyPair.publicKey],
      ];
      final content = 'hello with tags';

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: createdAt,
        kind: 1,
        tags: tags,
        content: content,
        sig: Bip340.sign(
          Nip01Utils.calculateEventIdSync(
            pubKey: keyPair.publicKey,
            createdAt: createdAt,
            kind: 1,
            tags: tags,
            content: content,
          ),
          keyPair.privateKey!,
        ),
      );

      final result = await verifier.verify(event);
      expect(result, isTrue);
    });

    test('verifies event with empty content', () async {
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final content = '';

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: createdAt,
        kind: 1,
        tags: [],
        content: content,
        sig: Bip340.sign(
          Nip01Utils.calculateEventIdSync(
            pubKey: keyPair.publicKey,
            createdAt: createdAt,
            kind: 1,
            tags: [],
            content: content,
          ),
          keyPair.privateKey!,
        ),
      );

      final result = await verifier.verify(event);
      expect(result, isTrue);
    });

    test('verifies event with unicode content', () async {
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final content = '你好世界 🌍 Привет мир';

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        createdAt: createdAt,
        kind: 1,
        tags: [],
        content: content,
        sig: Bip340.sign(
          Nip01Utils.calculateEventIdSync(
            pubKey: keyPair.publicKey,
            createdAt: createdAt,
            kind: 1,
            tags: [],
            content: content,
          ),
          keyPair.privateKey!,
        ),
      );

      final result = await verifier.verify(event);
      expect(result, isTrue);
    });
  });
}
