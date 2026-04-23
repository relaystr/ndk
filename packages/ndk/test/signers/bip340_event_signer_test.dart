import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _RecordingNip44Cryptography implements Nip44Cryptography {
  String? lastEncryptPlaintext;
  String? lastEncryptPrivateKey;
  String? lastEncryptPublicKey;
  String? lastDecryptCiphertext;
  String? lastDecryptPrivateKey;
  String? lastDecryptPublicKey;

  @override
  Future<String> encrypt({
    required String plaintext,
    required String privateKey,
    required String publicKey,
  }) async {
    lastEncryptPlaintext = plaintext;
    lastEncryptPrivateKey = privateKey;
    lastEncryptPublicKey = publicKey;
    return 'enc:$plaintext:$publicKey';
  }

  @override
  Future<String> decrypt({
    required String ciphertext,
    required String privateKey,
    required String publicKey,
  }) async {
    lastDecryptCiphertext = ciphertext;
    lastDecryptPrivateKey = privateKey;
    lastDecryptPublicKey = publicKey;
    return 'dec:$ciphertext:$publicKey';
  }
}

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

      test('delegates NIP-44 operations to configured cryptography', () async {
        final crypto = _RecordingNip44Cryptography();
        final customSigner = Bip340EventSigner(
          privateKey: keyPair.privateKey,
          publicKey: keyPair.publicKey,
          nip44Cryptography: crypto,
        );

        final encrypted = await customSigner.encryptNip44(
          plaintext: 'hello',
          recipientPubKey: 'recipient-pubkey',
        );
        final decrypted = await customSigner.decryptNip44(
          ciphertext: 'ciphertext',
          senderPubKey: 'sender-pubkey',
        );

        expect(encrypted, 'enc:hello:recipient-pubkey');
        expect(decrypted, 'dec:ciphertext:sender-pubkey');
        expect(crypto.lastEncryptPlaintext, 'hello');
        expect(crypto.lastEncryptPrivateKey, keyPair.privateKey);
        expect(crypto.lastEncryptPublicKey, 'recipient-pubkey');
        expect(crypto.lastDecryptCiphertext, 'ciphertext');
        expect(crypto.lastDecryptPrivateKey, keyPair.privateKey);
        expect(crypto.lastDecryptPublicKey, 'sender-pubkey');

        await customSigner.dispose();
      });
    });
  });
}
