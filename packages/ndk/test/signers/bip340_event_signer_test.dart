import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

void main() {
  group('Bip340EventSigner', () {
    late Bip340EventSigner signer;
    late KeyPair keyPair;

    setUp(() {
      keyPair = Bip340.generatePrivateKey();
      signer = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
    });

    tearDown(() async {
      await signer.dispose();
    });

    group('pending requests (local signer)', () {
      test('pendingRequests returns empty list', () {
        expect(signer.pendingRequests, isEmpty);
      });

      test('pendingRequestsStream emits empty list', () async {
        final requests = await signer.pendingRequestsStream.first;
        expect(requests, isEmpty);
      });

      test('cancelRequest returns false (no pending requests)', () {
        final result = signer.cancelRequest('any-request-id');
        expect(result, isFalse);
      });

      test('dispose closes stream without error', () async {
        await signer.dispose();
        // Re-create signer for tearDown
        signer = Bip340EventSigner(
          privateKey: keyPair.privateKey,
          publicKey: keyPair.publicKey,
        );
      });
    });

    group('signing', () {
      test('sign returns valid signature', () async {
        final event = Nip01Event(
          pubKey: keyPair.publicKey,
          kind: 1,
          tags: [],
          content: 'Test content',
        );

        final signedEvent = await signer.sign(event);
        final verifier = Bip340EventVerifier();
        final isValid = await verifier.verify(signedEvent);

        expect(isValid, isTrue);
      });

      test('sign throws when no private key', () async {
        final readOnlySigner = Bip340EventSigner(
          privateKey: null,
          publicKey: keyPair.publicKey,
        );

        final event = Nip01Event(
          pubKey: keyPair.publicKey,
          kind: 1,
          tags: [],
          content: 'Test content',
        );

        expect(() => readOnlySigner.sign(event), throwsException);

        await readOnlySigner.dispose();
      });
    });

    group('canSign', () {
      test('returns true when private key is present', () {
        expect(signer.canSign(), isTrue);
      });

      test('returns false when no private key', () {
        final readOnlySigner = Bip340EventSigner(
          privateKey: null,
          publicKey: keyPair.publicKey,
        );

        expect(readOnlySigner.canSign(), isFalse);
      });
    });

    group('getPublicKey', () {
      test('returns the public key', () {
        expect(signer.getPublicKey(), equals(keyPair.publicKey));
      });
    });

    group('encryption/decryption', () {
      test('encrypt and decrypt NIP-04 roundtrip', () async {
        final otherKeyPair = Bip340.generatePrivateKey();
        final otherSigner = Bip340EventSigner(
          privateKey: otherKeyPair.privateKey,
          publicKey: otherKeyPair.publicKey,
        );

        const message = 'Hello, world!';

        final encrypted = await signer.encrypt(message, otherKeyPair.publicKey);
        expect(encrypted, isNotNull);
        expect(encrypted, isNot(equals(message)));

        final decrypted =
            await otherSigner.decrypt(encrypted!, keyPair.publicKey);
        expect(decrypted, equals(message));

        await otherSigner.dispose();
      });

      test('encrypt and decrypt NIP-44 roundtrip', () async {
        final otherKeyPair = Bip340.generatePrivateKey();
        final otherSigner = Bip340EventSigner(
          privateKey: otherKeyPair.privateKey,
          publicKey: otherKeyPair.publicKey,
        );

        const message = 'Hello, NIP-44 world!';

        final encrypted = await signer.encryptNip44(
          plaintext: message,
          recipientPubKey: otherKeyPair.publicKey,
        );
        expect(encrypted, isNotNull);
        expect(encrypted, isNot(equals(message)));

        final decrypted = await otherSigner.decryptNip44(
          ciphertext: encrypted!,
          senderPubKey: keyPair.publicKey,
        );
        expect(decrypted, equals(message));

        await otherSigner.dispose();
      });
    });
  });

  group('Bip340EventSignerFactory', () {
    late Bip340EventSignerFactory factory;

    setUp(() {
      factory = const Bip340EventSignerFactory();
    });

    group('derivePublicKey', () {
      test('derives correct public key from private key', () {
        final keyPair = Bip340.generatePrivateKey();
        final derivedPubKey = factory.derivePublicKey(keyPair.privateKey!);

        expect(derivedPubKey, equals(keyPair.publicKey));
      });

      test('derived public key is consistent', () {
        final keyPair = Bip340.generatePrivateKey();
        final derivedPubKey1 = factory.derivePublicKey(keyPair.privateKey!);
        final derivedPubKey2 = factory.derivePublicKey(keyPair.privateKey!);

        expect(derivedPubKey1, equals(derivedPubKey2));
      });
    });

    group('generateKeyPair', () {
      test('generates valid keypair', () {
        final (privateKey, publicKey) = factory.generateKeyPair();

        expect(privateKey, isNotEmpty);
        expect(publicKey, isNotEmpty);
      });

      test('generated public key matches derived public key', () {
        final (privateKey, publicKey) = factory.generateKeyPair();
        final derivedPubKey = factory.derivePublicKey(privateKey);

        expect(publicKey, equals(derivedPubKey));
      });

      test('generates unique keypairs', () {
        final (privKey1, pubKey1) = factory.generateKeyPair();
        final (privKey2, pubKey2) = factory.generateKeyPair();

        expect(privKey1, isNot(equals(privKey2)));
        expect(pubKey1, isNot(equals(pubKey2)));
      });
    });

    group('create', () {
      test('creates signer with both keys provided', () async {
        final keyPair = Bip340.generatePrivateKey();
        final signer = factory.create(
          privateKey: keyPair.privateKey,
          publicKey: keyPair.publicKey,
        );

        expect(signer.getPublicKey(), equals(keyPair.publicKey));
        expect(signer.canSign(), isTrue);

        await signer.dispose();
      });

      test('creates signer with only private key (derives public key)',
          () async {
        final keyPair = Bip340.generatePrivateKey();
        final signer = factory.create(
          privateKey: keyPair.privateKey,
        );

        expect(signer.getPublicKey(), equals(keyPair.publicKey));
        expect(signer.canSign(), isTrue);

        await signer.dispose();
      });

      test('creates read-only signer with only public key', () async {
        final keyPair = Bip340.generatePrivateKey();
        final signer = factory.create(
          publicKey: keyPair.publicKey,
        );

        expect(signer.getPublicKey(), equals(keyPair.publicKey));
        expect(signer.canSign(), isFalse);

        await signer.dispose();
      });

      test('throws exception when neither key is provided', () {
        expect(
          () => factory.create(),
          throwsException,
        );
      });

      test('derived public key can sign valid events', () async {
        final keyPair = Bip340.generatePrivateKey();
        final signer = factory.create(
          privateKey: keyPair.privateKey,
          // publicKey NOT provided - should be derived
        );

        final event = Nip01Event(
          pubKey: signer.getPublicKey(),
          kind: 1,
          tags: [],
          content: 'Test with derived public key',
        );

        final signedEvent = await signer.sign(event);
        final verifier = Bip340EventVerifier();
        final isValid = await verifier.verify(signedEvent);

        expect(isValid, isTrue);

        await signer.dispose();
      });

      test('uses provided public key even if derivation would differ',
          () async {
        final keyPair1 = Bip340.generatePrivateKey();
        final keyPair2 = Bip340.generatePrivateKey();

        // Intentionally mismatched keys
        final signer = factory.create(
          privateKey: keyPair1.privateKey,
          publicKey: keyPair2.publicKey, // Different public key
        );

        // Should use the provided public key, not derived
        expect(signer.getPublicKey(), equals(keyPair2.publicKey));
        expect(signer.getPublicKey(), isNot(equals(keyPair1.publicKey)));

        await signer.dispose();
      });
    });

    group('createWithNewKeyPair', () {
      test('creates signer with fresh keypair', () async {
        final signer = factory.createWithNewKeyPair();

        expect(signer.getPublicKey(), isNotEmpty);
        expect(signer.canSign(), isTrue);

        await signer.dispose();
      });

      test('creates unique signers each time', () async {
        final signer1 = factory.createWithNewKeyPair();
        final signer2 = factory.createWithNewKeyPair();

        expect(signer1.getPublicKey(), isNot(equals(signer2.getPublicKey())));

        await signer1.dispose();
        await signer2.dispose();
      });

      test('created signer can sign valid events', () async {
        final signer = factory.createWithNewKeyPair();

        final event = Nip01Event(
          pubKey: signer.getPublicKey(),
          kind: 1,
          tags: [],
          content: 'Test with new keypair',
        );

        final signedEvent = await signer.sign(event);
        final verifier = Bip340EventVerifier();
        final isValid = await verifier.verify(signedEvent);

        expect(isValid, isTrue);

        await signer.dispose();
      });
    });

    group('factory is const', () {
      test('same instance when created with const', () {
        const factory1 = Bip340EventSignerFactory();
        const factory2 = Bip340EventSignerFactory();

        expect(identical(factory1, factory2), isTrue);
      });
    });
  });
}
