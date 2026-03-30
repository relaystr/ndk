@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/data_layer/repositories/signers/nip07_event_signer.dart';
import 'package:test/test.dart';

@JS()
external void eval(String code);

@JS('setupNostrExtensionAsync')
external JSPromise<JSAny?> _setupNostrExtensionAsync();

Future<void> setupNostrExtension() async {
  await _setupNostrExtensionAsync().toDart;
}

void injectSetupCode() {
  eval(r'''
    window.setupNostrExtensionAsync = async function() {
      const nostrTools = await import('https://esm.sh/nostr-tools@2.23.0');
      const { nip04, nip44, getPublicKey, finalizeEvent } = nostrTools;

      const privateKeyHex = '0a47414ecfcdda1fe8374ec28629883cdd95287e353b3fd1a536c03d953f6cc2';

      function hexToBytes(hex) {
        const bytes = new Uint8Array(hex.length / 2);
        for (let i = 0; i < hex.length; i += 2) {
          bytes[i / 2] = parseInt(hex.substr(i, 2), 16);
        }
        return bytes;
      }

      const privateKeyBytes = hexToBytes(privateKeyHex);
      const publicKeyHex = getPublicKey(privateKeyBytes);

      window.nostr = {
        _privkey: privateKeyBytes,
        _privkeyHex: privateKeyHex,
        _pubkey: publicKeyHex,
        _hang: false,

        setHang: function(hang) {
          this._hang = hang;
        },

        getPublicKey: function() {
          if (this._hang) {
            return new Promise(() => {});
          }
          return Promise.resolve(this._pubkey);
        },

        signEvent: async function(event) {
          const eventToSign = {
            kind: event.kind,
            created_at: event.created_at,
            tags: event.tags,
            content: event.content,
            pubkey: event.pubkey,
          };
          return finalizeEvent(eventToSign, this._privkey);
        },

        nip04: {
          encrypt: async function(recipientPubKey, plaintext) {
            return await nip04.encrypt(window.nostr._privkeyHex, recipientPubKey, plaintext);
          },

          decrypt: async function(senderPubKey, ciphertext) {
            return await nip04.decrypt(window.nostr._privkeyHex, senderPubKey, ciphertext);
          }
        },

        nip44: {
          encrypt: async function(recipientPubKey, plaintext) {
            const conversationKey = nip44.v2.utils.getConversationKey(window.nostr._privkey, recipientPubKey);
            return nip44.v2.encrypt(plaintext, conversationKey);
          },

          decrypt: async function(senderPubKey, ciphertext) {
            const conversationKey = nip44.v2.utils.getConversationKey(window.nostr._privkey, senderPubKey);
            return nip44.v2.decrypt(ciphertext, conversationKey);
          }
        }
      };
    };
  ''');
}

void main() {
  injectSetupCode();

  group('Nip07EventSigner', () {
    late Nip07EventSigner nip07Signer;
    late Bip340EventSigner bip340EventSigner;

    setUp(() {
      nip07Signer = Nip07EventSigner();
      bip340EventSigner = Bip340EventSigner(
        privateKey:
            'e4bd52924bce6a9c58d2decc7fe91b376d6a6513fc615aabc9e071f2b436b127',
        publicKey:
            '953f12b4f6966a289fde9adfc511e00a66cfa4cb9d69551dee51f3f387e8e277',
      );
    });

    tearDown(() {
      eval('window.nostr = null;');
    });

    test('canSign returns false when nostr is null', () {
      expect(nip07Signer.canSign(), isFalse);
    });

    test('canSign returns true when nostr extension is available', () async {
      await setupNostrExtension();
      expect(nip07Signer.canSign(), isTrue);
    });

    test('getPublicKeyAsync returns public key', () async {
      await setupNostrExtension();

      final pubkey = await nip07Signer.getPublicKeyAsync();
      expect(pubkey, isNotNull);
      expect(pubkey.length, equals(64));
    });

    test('getPublicKey throws exception for sync call', () async {
      await setupNostrExtension();

      expect(
        () => nip07Signer.getPublicKey(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Use getPublicKeyAsync with Nip07EventSigner'),
          ),
        ),
      );
    });

    test('sign adds id and signature to event', () async {
      await setupNostrExtension();

      final pubkey = await nip07Signer.getPublicKeyAsync();
      final event = Nip01Event(
        pubKey: pubkey,
        kind: 1,
        tags: [],
        content: 'test content',
        createdAt: 1234567890,
      );

      final signedEvent = await nip07Signer.sign(event);
      expect(await Bip340EventVerifier().verify(signedEvent), isTrue);
    });

    test('encrypt NIP-04', () async {
      await setupNostrExtension();

      const message = 'Hello World';
      final nip07PubKey = await nip07Signer.getPublicKeyAsync();
      final encrypted = await nip07Signer.encrypt(
        message,
        bip340EventSigner.publicKey,
      );
      final decrypted = await bip340EventSigner.decrypt(
        encrypted!,
        nip07PubKey,
      );

      expect(decrypted, equals(message));
    });

    test('decrypt NIP-04 with invalid data throws error', () async {
      await setupNostrExtension();

      const encrypted = 'invalid_data';

      await expectLater(
        nip07Signer.decrypt(encrypted, bip340EventSigner.publicKey),
        throwsA(anything),
      );
    });

    test('round-trip encrypt/decrypt NIP-04', () async {
      await setupNostrExtension();

      const message = 'Hello round trip';
      final nip07PubKey = await nip07Signer.getPublicKeyAsync();
      final encrypted = await nip07Signer.encrypt(message, nip07PubKey);
      final decrypted = await nip07Signer.decrypt(encrypted!, nip07PubKey);

      expect(decrypted, equals(message));
    });

    test('encrypt NIP-44', () async {
      await setupNostrExtension();

      const message = 'Secret Message';
      final nip07PubKey = await nip07Signer.getPublicKeyAsync();
      final encrypted = await nip07Signer.encryptNip44(
        plaintext: message,
        recipientPubKey: bip340EventSigner.publicKey,
      );
      final decrypted = await bip340EventSigner.decryptNip44(
        ciphertext: encrypted!,
        senderPubKey: nip07PubKey,
      );

      expect(decrypted, equals(message));
    });

    test('decrypt NIP-44 with invalid data throws error', () async {
      await setupNostrExtension();

      const encrypted = 'invalid_nip44_data';

      await expectLater(
        nip07Signer.decryptNip44(
          ciphertext: encrypted,
          senderPubKey: bip340EventSigner.publicKey,
        ),
        throwsA(anything),
      );
    });

    test('round-trip encrypt/decrypt NIP-44', () async {
      await setupNostrExtension();

      const message = 'Hello NIP-44 round trip';
      final nip07PubKey = await nip07Signer.getPublicKeyAsync();
      final encrypted = await nip07Signer.encryptNip44(
        plaintext: message,
        recipientPubKey: nip07PubKey,
      );
      final decrypted = await nip07Signer.decryptNip44(
        ciphertext: encrypted!,
        senderPubKey: nip07PubKey,
      );

      expect(decrypted, equals(message));
    });

    test('throws exception when nostr is null for encrypt', () {
      expect(
        () => nip07Signer.encrypt('msg', bip340EventSigner.publicKey),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('throws exception when nostr is null for decrypt', () {
      expect(
        () => nip07Signer.decrypt('msg', bip340EventSigner.publicKey),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('throws exception when nostr is null for encryptNip44', () {
      expect(
        () => nip07Signer.encryptNip44(
          plaintext: 'plain',
          recipientPubKey: bip340EventSigner.publicKey,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('throws exception when nostr is null for decryptNip44', () {
      expect(
        () => nip07Signer.decryptNip44(
          ciphertext: 'cipher',
          senderPubKey: bip340EventSigner.publicKey,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('throws exception when nostr is null for sign', () {
      final event = Nip01Event(
        pubKey: bip340EventSigner.publicKey,
        kind: 1,
        tags: [],
        content: 'test content',
        createdAt: 1234567890,
      );

      expect(
        () => nip07Signer.sign(event),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('decrypt NIP-04', () async {
      await setupNostrExtension();

      const message = 'Hello from BIP-340';
      final nip07PubKey = await nip07Signer.getPublicKeyAsync();
      final encrypted = await bip340EventSigner.encrypt(message, nip07PubKey);
      final decrypted = await nip07Signer.decrypt(
        encrypted!,
        bip340EventSigner.publicKey,
      );

      expect(decrypted, equals(message));
    });

    test('decrypt NIP-44', () async {
      await setupNostrExtension();

      const message = 'NIP-44 message from BIP-340';
      final nip07PubKey = await nip07Signer.getPublicKeyAsync();
      final encrypted = await bip340EventSigner.encryptNip44(
        plaintext: message,
        recipientPubKey: nip07PubKey,
      );
      final decrypted = await nip07Signer.decryptNip44(
        ciphertext: encrypted!,
        senderPubKey: bip340EventSigner.publicKey,
      );

      expect(decrypted, equals(message));
    });

    test('cancelRequest returns false for non-existent request', () async {
      await setupNostrExtension();

      final result = nip07Signer.cancelRequest('non_existent_id');
      expect(result, isFalse);
    });

    test('pendingRequests is empty initially', () async {
      await setupNostrExtension();

      expect(nip07Signer.pendingRequests, isEmpty);
    });

    test(
      'pendingRequests contains request while operation is in progress',
      () async {
        await setupNostrExtension();
        eval('window.nostr.setHang(true);');
        addTearDown(() => eval('window.nostr.setHang(false);'));

        final future = nip07Signer.getPublicKeyAsync();

        await Future.delayed(Duration(milliseconds: 10));

        expect(nip07Signer.pendingRequests, hasLength(1));
        expect(
          nip07Signer.pendingRequests.first.method,
          equals(SignerMethod.getPublicKey),
        );

        final requestId = nip07Signer.pendingRequests.first.id;
        nip07Signer.cancelRequest(requestId);

        try {
          await future;
        } catch (_) {}

        expect(nip07Signer.pendingRequests, isEmpty);
      },
    );

    test('cancelRequest returns true and removes pending request', () async {
      await setupNostrExtension();
      eval('window.nostr.setHang(true);');
      addTearDown(() => eval('window.nostr.setHang(false);'));

      final future = nip07Signer.getPublicKeyAsync();

      await Future.delayed(Duration(milliseconds: 10));

      expect(nip07Signer.pendingRequests, hasLength(1));
      final requestId = nip07Signer.pendingRequests.first.id;

      final result = nip07Signer.cancelRequest(requestId);
      expect(result, isTrue);
      expect(nip07Signer.pendingRequests, isEmpty);

      Object? thrownError;
      try {
        await future;
      } catch (error) {
        thrownError = error;
      }
      expect(thrownError, isA<SignerRequestCancelledException>());
    });

    test('pendingRequestsStream emits updates', () async {
      await setupNostrExtension();
      eval('window.nostr.setHang(true);');
      addTearDown(() => eval('window.nostr.setHang(false);'));

      final emissions = <List<PendingSignerRequest>>[];
      final subscription = nip07Signer.pendingRequestsStream.listen(
        emissions.add,
      );
      addTearDown(() => subscription.cancel());

      final future = nip07Signer.getPublicKeyAsync();

      await Future.delayed(Duration(milliseconds: 10));

      expect(emissions.any((list) => list.length == 1), isTrue);

      final requestId = nip07Signer.pendingRequests.first.id;
      nip07Signer.cancelRequest(requestId);

      try {
        await future;
      } catch (_) {}

      await Future.delayed(Duration(milliseconds: 10));

      expect(emissions.last, isEmpty);
    });
  });
}
