@TestOn('browser')

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk_flutter/signers/web_event_signer.dart';
import 'package:ndk_flutter/verifiers/web_event_verifier.dart';

void main() {
  group('WebEventSigner', () {
    late WebEventSigner signer;
    late KeyPair keyPair;

    setUp(() {
      keyPair = Bip340.generatePrivateKey();
      signer = WebEventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
    });

    tearDown(() async {
      await signer.dispose();
    });

    test('getPublicKey returns the public key', () {
      expect(signer.getPublicKey(), equals(keyPair.publicKey));
    });

    test('canSign returns true when private key is present', () {
      expect(signer.canSign(), isTrue);
    });

    test('canSign returns false when no private key', () {
      final readOnlySigner = WebEventSigner(
        privateKey: null,
        publicKey: keyPair.publicKey,
      );
      expect(readOnlySigner.canSign(), isFalse);
    });

    test('sign returns valid signature', () async {
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: 'Test content',
      );

      final signedEvent = await signer.sign(event);
      expect(signedEvent.sig, isNotNull);
      expect(signedEvent.sig, isNotEmpty);

      // Verify with pure Dart verifier
      final dartVerifier = Bip340EventVerifier();
      final isValidDart = await dartVerifier.verify(signedEvent);
      expect(isValidDart, isTrue);

      // Verify with web verifier
      final webVerifier = WebEventVerifier();
      final isValidWeb = await webVerifier.verify(signedEvent);
      expect(isValidWeb, isTrue);
    });

    test('sign throws when no private key', () async {
      final readOnlySigner = WebEventSigner(
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

    group('NIP-04 interop with Bip340EventSigner', () {
      late KeyPair otherKeyPair;

      setUp(() {
        otherKeyPair = Bip340.generatePrivateKey();
      });

      test('encrypt with WebEventSigner, decrypt with Bip340EventSigner', () async {
        final dartSigner = Bip340EventSigner(
          privateKey: otherKeyPair.privateKey,
          publicKey: otherKeyPair.publicKey,
        );

        const message = 'Hello, NIP-04 from web!';
        final encrypted = await signer.encrypt(message, otherKeyPair.publicKey);
        expect(encrypted, isNotNull);
        expect(encrypted, isNot(equals(message)));

        final decrypted = await dartSigner.decrypt(encrypted!, keyPair.publicKey);
        expect(decrypted, equals(message));

        await dartSigner.dispose();
      });

      test('encrypt with Bip340EventSigner, decrypt with WebEventSigner', () async {
        final dartSigner = Bip340EventSigner(
          privateKey: otherKeyPair.privateKey,
          publicKey: otherKeyPair.publicKey,
        );

        const message = 'Hello from Dart NIP-04!';
        final encrypted = await dartSigner.encrypt(message, keyPair.publicKey);
        expect(encrypted, isNotNull);

        final decrypted = await signer.decrypt(encrypted!, otherKeyPair.publicKey);
        expect(decrypted, equals(message));

        await dartSigner.dispose();
      });
    });

    group('NIP-44 interop with Bip340EventSigner', () {
      late KeyPair otherKeyPair;

      setUp(() {
        otherKeyPair = Bip340.generatePrivateKey();
      });

      test('encrypt with WebEventSigner, decrypt with Bip340EventSigner', () async {
        final dartSigner = Bip340EventSigner(
          privateKey: otherKeyPair.privateKey,
          publicKey: otherKeyPair.publicKey,
        );

        const message = 'Hello, NIP-44 from web!';
        final encrypted = await signer.encryptNip44(
          plaintext: message,
          recipientPubKey: otherKeyPair.publicKey,
        );
        expect(encrypted, isNotNull);
        expect(encrypted, isNot(equals(message)));

        final decrypted = await dartSigner.decryptNip44(
          ciphertext: encrypted!,
          senderPubKey: keyPair.publicKey,
        );
        expect(decrypted, equals(message));

        await dartSigner.dispose();
      });

      test('encrypt with Bip340EventSigner, decrypt with WebEventSigner', () async {
        final dartSigner = Bip340EventSigner(
          privateKey: otherKeyPair.privateKey,
          publicKey: otherKeyPair.publicKey,
        );

        const message = 'Hello from Dart NIP-44!';
        final encrypted = await dartSigner.encryptNip44(
          plaintext: message,
          recipientPubKey: keyPair.publicKey,
        );
        expect(encrypted, isNotNull);

        final decrypted = await signer.decryptNip44(
          ciphertext: encrypted!,
          senderPubKey: otherKeyPair.publicKey,
        );
        expect(decrypted, equals(message));

        await dartSigner.dispose();
      });
    });

    group('pending requests (local signer)', () {
      test('pendingRequests returns empty list', () {
        expect(signer.pendingRequests, isEmpty);
      });

      test('pendingRequestsStream emits empty list', () async {
        final requests = await signer.pendingRequestsStream.first;
        expect(requests, isEmpty);
      });

      test('cancelRequest returns false', () {
        expect(signer.cancelRequest('any-id'), isFalse);
      });

      test('dispose closes stream without error', () async {
        await signer.dispose();
        // Recreate for tearDown
        signer = WebEventSigner(
          privateKey: keyPair.privateKey,
          publicKey: keyPair.publicKey,
        );
      });
    });
  });

  group('WebEventVerifier', () {
    test('verifies a valid event', () async {
      final keyPair = Bip340.generatePrivateKey();
      final dartSigner = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: 'Test content',
      );
      final signedEvent = await dartSigner.sign(event);

      final webVerifier = WebEventVerifier();
      final isValid = await webVerifier.verify(signedEvent);
      expect(isValid, isTrue);

      await dartSigner.dispose();
    });

    test('returns false for invalid signature', () async {
      final keyPair = Bip340.generatePrivateKey();
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: 'Test content',
        sig: '0' * 128,
      );

      final webVerifier = WebEventVerifier();
      final isValid = await webVerifier.verify(event);
      expect(isValid, isFalse);
    });

    test('returns false for null signature', () async {
      final keyPair = Bip340.generatePrivateKey();
      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: 'Test content',
      );

      final webVerifier = WebEventVerifier();
      final isValid = await webVerifier.verify(event);
      expect(isValid, isFalse);
    });
  });
}
