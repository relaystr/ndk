@TestOn('browser')
library;

import 'dart:js_interop';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:nip07_event_signer/nip07_event_signer.dart';

@JS()
external void eval(String code);

@JS('setupNostrExtensionAsync')
external JSPromise<JSAny?> _setupNostrExtensionAsync();

Future<void> setupNostrExtension() async {
  await _setupNostrExtensionAsync().toDart;
}

// Inject the setup code that loads nostr-tools and creates proper NIP-04/NIP-44 implementation
void injectSetupCode() {
  eval(r'''
    window.setupNostrExtensionAsync = async function() {
      // Import nostr-tools from esm.sh
      const nostrTools = await import('https://esm.sh/nostr-tools@2.23.0');
      const { nip04, nip44, getPublicKey, finalizeEvent } = nostrTools;

      // Test private key (32 bytes hex)
      const privateKeyHex = '0a47414ecfcdda1fe8374ec28629883cdd95287e353b3fd1a536c03d953f6cc2';

      // Convert hex to Uint8Array for nostr-tools
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

        getPublicKey: function() {
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
          const signedEvent = finalizeEvent(eventToSign, this._privkey);
          return signedEvent;
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
  // Inject setup code once at the beginning
  injectSetupCode();

  group('Nip07EventSigner', () {
    late Nip07EventSigner nip07Signer;
    late Bip340EventSigner bip340EventSigner;

    setUp(() {
      nip07Signer = Nip07EventSigner();
      bip340EventSigner = Bip340EventSigner(
        privateKey:
            "e4bd52924bce6a9c58d2decc7fe91b376d6a6513fc615aabc9e071f2b436b127",
        publicKey:
            "953f12b4f6966a289fde9adfc511e00a66cfa4cb9d69551dee51f3f387e8e277",
      );
    });

    tearDown(() {
      // Clean up window.nostr after each test
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
            (e) => e.toString(),
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

      final encrypted = 'invalid_data';

      expect(
        () => nip07Signer.decrypt(encrypted, bip340EventSigner.publicKey),
        throwsA(anything),
      );
    });

    test('round-trip encrypt/decrypt NIP-04', () async {
      await setupNostrExtension();

      const message = 'Hello round trip';
      final nip07PubKey = await nip07Signer.getPublicKeyAsync();

      // For round-trip, encrypt to self and decrypt from self
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

      final encrypted = 'invalid_nip44_data';

      expect(
        () => nip07Signer.decryptNip44(
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

      // For round-trip, encrypt to self and decrypt from self
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

    test('throws exception when nostr is null for encrypt', () async {
      // Don't setup mock extension, so nostr will be null
      expect(
        () => nip07Signer.encrypt('msg', bip340EventSigner.publicKey),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('throws exception when nostr is null for decrypt', () async {
      expect(
        () => nip07Signer.decrypt('msg', bip340EventSigner.publicKey),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('throws exception when nostr is null for encryptNip44', () async {
      expect(
        () => nip07Signer.encryptNip44(
          plaintext: 'plain',
          recipientPubKey: bip340EventSigner.publicKey,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('throws exception when nostr is null for decryptNip44', () async {
      expect(
        () => nip07Signer.decryptNip44(
          ciphertext: 'cipher',
          senderPubKey: bip340EventSigner.publicKey,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('NIP-07 extension not available'),
          ),
        ),
      );
    });

    test('throws exception when nostr is null for sign', () async {
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
            (e) => e.toString(),
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
  });
}
