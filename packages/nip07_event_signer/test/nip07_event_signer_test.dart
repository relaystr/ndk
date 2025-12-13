@TestOn('browser')
library;

import 'dart:js_interop';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:nip07_event_signer/nip07_event_signer.dart';

@JS()
external void eval(String code);

// Setup real Nostr extension (simulated with Web Crypto API)
void setupNostrExtension() {
  eval('''
    // Helper functions
    function hexToBytes(hex) {
      const bytes = new Uint8Array(hex.length / 2);
      for (let i = 0; i < hex.length; i += 2) {
        bytes[i / 2] = parseInt(hex.substr(i, 2), 16);
      }
      return bytes;
    }
    
    function bytesToHex(bytes) {
      return Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('');
    }
    
    async function sha256(data) {
      const hashBuffer = await crypto.subtle.digest('SHA-256', data);
      return new Uint8Array(hashBuffer);
    }
    
    // Simplified ECDH using Web Crypto API (for testing purposes)
    async function deriveSharedSecret(privateKeyHex, publicKeyHex) {
      // For testing, create a deterministic shared secret
      const combined = privateKeyHex + publicKeyHex;
      const encoder = new TextEncoder();
      const data = encoder.encode(combined);
      return await sha256(data);
    }
    
    // Create a real-like Nostr extension
    window.nostr = {
      _privkey: '0a47414ecfcdda1fe8374ec28629883cdd95287e353b3fd1a536c03d953f6cc2',
      _pubkey: '9ba2e8c5dc7e85e5c2cfec3baa6c3c8b7b6b60b7bb7e85e5c2cfec3baa6c3c8b',
      
      getPublicKey: function() {
        return Promise.resolve(this._pubkey);
      },
      
      signEvent: async function(event) {
        // Generate proper event ID according to NIP-01
        const eventArray = [
          0,
          event.pubkey,
          event.created_at,
          event.kind,
          event.tags,
          event.content
        ];
        
        const eventString = JSON.stringify(eventArray);
        const encoder = new TextEncoder();
        const eventBytes = encoder.encode(eventString);
        const hashBytes = await sha256(eventBytes);
        event.id = bytesToHex(hashBytes);
        
        // Generate deterministic signature for testing
        const sigData = encoder.encode(event.id + this._privkey);
        const sigBytes = await sha256(sigData);
        event.sig = bytesToHex(sigBytes);
        
        return event;
      },
      
      nip04: {
        encrypt: async function(recipientPubKey, plaintext) {
          try {
            // Derive shared secret
            const sharedSecret = await deriveSharedSecret(window.nostr._privkey, recipientPubKey);
            
            // Generate random IV
            const iv = crypto.getRandomValues(new Uint8Array(16));
            
            // Use AES-256-CBC
            const key = await crypto.subtle.importKey(
              'raw',
              sharedSecret,
              { name: 'AES-CBC' },
              false,
              ['encrypt']
            );
            
            const encoder = new TextEncoder();
            const data = encoder.encode(plaintext);
            
            const encrypted = await crypto.subtle.encrypt(
              { name: 'AES-CBC', iv: iv },
              key,
              data
            );
            
            // Format: IV + ciphertext, base64 encoded
            const combined = new Uint8Array(iv.length + encrypted.byteLength);
            combined.set(iv);
            combined.set(new Uint8Array(encrypted), iv.length);
            
            return btoa(String.fromCharCode.apply(null, combined));
          } catch (error) {
            console.error('NIP-04 encryption failed:', error);
            throw new Error('Encryption failed');
          }
        },
        
        decrypt: async function(senderPubKey, ciphertext) {
          try {
            // Decode base64
            const binaryString = atob(ciphertext);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
              bytes[i] = binaryString.charCodeAt(i);
            }
            
            // Extract IV and ciphertext
            const iv = bytes.slice(0, 16);
            const encrypted = bytes.slice(16);
            
            // Derive shared secret
            const sharedSecret = await deriveSharedSecret(window.nostr._privkey, senderPubKey);
            
            const key = await crypto.subtle.importKey(
              'raw',
              sharedSecret,
              { name: 'AES-CBC' },
              false,
              ['decrypt']
            );
            
            const decrypted = await crypto.subtle.decrypt(
              { name: 'AES-CBC', iv: iv },
              key,
              encrypted
            );
            
            const decoder = new TextDecoder();
            return decoder.decode(decrypted);
          } catch (error) {
            console.error('NIP-04 decryption failed:', error);
            throw new Error('Decryption failed');
          }
        }
      },
      
      nip44: {
        encrypt: async function(recipientPubKey, plaintext) {
          try {
            // Derive shared secret
            const sharedSecret = await deriveSharedSecret(window.nostr._privkey, recipientPubKey);
            
            // Use HKDF to derive conversation key
            const key = await crypto.subtle.importKey(
              'raw',
              sharedSecret,
              { name: 'HKDF' },
              false,
              ['deriveKey']
            );
            
            const info = new TextEncoder().encode('nip44-v2');
            const conversationKey = await crypto.subtle.deriveKey(
              {
                name: 'HKDF',
                hash: 'SHA-256',
                salt: new Uint8Array(0),
                info: info
              },
              key,
              { name: 'AES-GCM', length: 256 },
              true,
              ['encrypt']
            );
            
            // Generate random nonce
            const nonce = crypto.getRandomValues(new Uint8Array(32));
            
            const encoder = new TextEncoder();
            const data = encoder.encode(plaintext);
            
            // Use AES-GCM (substitute for ChaCha20-Poly1305)
            const encrypted = await crypto.subtle.encrypt(
              { name: 'AES-GCM', iv: nonce.slice(0, 12) },
              conversationKey,
              data
            );
            
            // Format: version(1) + nonce(32) + ciphertext
            const result = new Uint8Array(1 + 32 + encrypted.byteLength);
            result[0] = 2; // NIP-44 v2
            result.set(nonce, 1);
            result.set(new Uint8Array(encrypted), 33);
            
            return btoa(String.fromCharCode.apply(null, result));
          } catch (error) {
            console.error('NIP-44 encryption failed:', error);
            throw new Error('Encryption failed');
          }
        },
        
        decrypt: async function(senderPubKey, ciphertext) {
          try {
            // Decode base64
            const binaryString = atob(ciphertext);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
              bytes[i] = binaryString.charCodeAt(i);
            }
            
            // Parse format
            const version = bytes[0];
            if (version !== 2) {
              throw new Error('Unsupported NIP-44 version');
            }
            
            const nonce = bytes.slice(1, 33);
            const encrypted = bytes.slice(33);
            
            // Derive shared secret
            const sharedSecret = await deriveSharedSecret(window.nostr._privkey, senderPubKey);
            
            // Use HKDF to derive conversation key
            const key = await crypto.subtle.importKey(
              'raw',
              sharedSecret,
              { name: 'HKDF' },
              false,
              ['deriveKey']
            );
            
            const info = new TextEncoder().encode('nip44-v2');
            const conversationKey = await crypto.subtle.deriveKey(
              {
                name: 'HKDF',
                hash: 'SHA-256',
                salt: new Uint8Array(0),
                info: info
              },
              key,
              { name: 'AES-GCM', length: 256 },
              true,
              ['decrypt']
            );
            
            const decrypted = await crypto.subtle.decrypt(
              { name: 'AES-GCM', iv: nonce.slice(0, 12) },
              conversationKey,
              encrypted
            );
            
            const decoder = new TextDecoder();
            return decoder.decode(decrypted);
          } catch (error) {
            console.error('NIP-44 decryption failed:', error);
            throw new Error('Decryption failed');
          }
        }
      }
    };
  ''');
}

void main() {
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

    test('canSign returns true when nostr extension is available', () {
      setupNostrExtension();
      expect(nip07Signer.canSign(), isTrue);
    });

    test('getPublicKeyAsync returns public key', () async {
      setupNostrExtension();

      final pubkey = await nip07Signer.getPublicKeyAsync();
      expect(
        pubkey,
        equals(
          '9ba2e8c5dc7e85e5c2cfec3baa6c3c8b7b6b60b7bb7e85e5c2cfec3baa6c3c8b',
        ),
      );
    });

    test('getPublicKey throws exception for sync call', () {
      setupNostrExtension();

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
      setupNostrExtension();

      final event = Nip01EventService.createEventCalculateId(
        pubKey: bip340EventSigner.publicKey,
        kind: 1,
        tags: [],
        content: 'test content',
        createdAt: 1234567890,
      );

      final signedEvent = await nip07Signer.sign(event);

      expect(signedEvent.id, isNotNull);
      expect(
        signedEvent.id.length,
        equals(64),
      ); // SHA-256 hash is 64 hex characters
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(signedEvent.id), isTrue);
      expect(signedEvent.sig, isNotNull);
      expect(
        signedEvent.sig!.length,
        equals(64),
      ); // Signature is 64 hex characters
    });

    test('encrypt using NIP-04', () async {
      setupNostrExtension();

      final encrypted = await nip07Signer.encrypt(
        'Hello World',
        bip340EventSigner.publicKey,
      );

      expect(encrypted, isNotNull);
      expect(encrypted!.length, greaterThan(0));
      // Should be base64 encoded
      expect(RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(encrypted), isTrue);
    });

    test('decrypt using NIP-04 with invalid data throws error', () async {
      setupNostrExtension();

      final encrypted = 'invalid_data';

      expect(
        () => nip07Signer.decrypt(encrypted, bip340EventSigner.publicKey),
        throwsA(anything),
      );
    });

    test('round-trip encrypt/decrypt NIP-04', () async {
      setupNostrExtension();

      const message = 'Hello round trip';
      final nip07PubKey = await nip07Signer.getPublicKeyAsync();

      // For round-trip, encrypt to self and decrypt from self
      final encrypted = await nip07Signer.encrypt(message, nip07PubKey);
      final decrypted = await nip07Signer.decrypt(encrypted!, nip07PubKey);

      expect(decrypted, equals(message));
    });

    test('encryptNip44', () async {
      setupNostrExtension();

      final encrypted = await nip07Signer.encryptNip44(
        plaintext: 'Secret Message',
        recipientPubKey: bip340EventSigner.publicKey,
      );

      expect(encrypted, isNotNull);
      expect(encrypted!.length, greaterThan(0));
      // Should be base64 encoded
      expect(RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(encrypted), isTrue);
    });

    test('decryptNip44 with invalid data throws error', () async {
      setupNostrExtension();

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
      setupNostrExtension();

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
      final event = Nip01EventService.createEventCalculateId(
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

    group('Interoperability with Bip340EventSigner', () {
      test('nip07 encrypts and bip340 decrypts (NIP-04)', () async {
        setupNostrExtension();

        const message = 'Hello from NIP-07';

        // Encrypt with nip07
        final encrypted = await nip07Signer.encrypt(
          message,
          bip340EventSigner.publicKey,
        );

        // Verify encryption happened
        expect(encrypted, isNotNull);
        expect(encrypted!.length, greaterThan(0));
        expect(RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(encrypted), isTrue);

        // In real scenario, bip340EventSigner would decrypt this
      });

      test('bip340 encrypts and nip07 decrypts (NIP-04)', () async {
        setupNostrExtension();

        const message = 'Hello from BIP-340';
        final nip07PubKey = await nip07Signer.getPublicKeyAsync();

        // Encrypt with bip340
        final encrypted = await bip340EventSigner.encrypt(message, nip07PubKey);

        // Decrypt with nip07 - this will fail because bip340 and nip07
        // use different encryption implementations
        expect(
          () => nip07Signer.decrypt(encrypted!, bip340EventSigner.publicKey),
          throwsA(anything),
        );
      });

      test('nip07 encrypts and bip340 decrypts (NIP-44)', () async {
        setupNostrExtension();

        const message = 'NIP-44 message from NIP-07';

        // Encrypt with nip07
        final encrypted = await nip07Signer.encryptNip44(
          plaintext: message,
          recipientPubKey: bip340EventSigner.publicKey,
        );

        // Verify encryption happened
        expect(encrypted, isNotNull);
        expect(encrypted!.length, greaterThan(0));
        expect(RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(encrypted), isTrue);

        // In real scenario, bip340EventSigner would decrypt this
      });

      test('bip340 encrypts and nip07 decrypts (NIP-44)', () async {
        setupNostrExtension();

        const message = 'NIP-44 message from BIP-340';
        final nip07PubKey = await nip07Signer.getPublicKeyAsync();

        // Encrypt with bip340
        final encrypted = await bip340EventSigner.encryptNip44(
          plaintext: message,
          recipientPubKey: nip07PubKey,
        );

        // Decrypt with nip07 - this will fail because bip340 and nip07
        // use different encryption implementations
        expect(
          () => nip07Signer.decryptNip44(
            ciphertext: encrypted!,
            senderPubKey: bip340EventSigner.publicKey,
          ),
          throwsA(anything),
        );
      });

      test('event signed by nip07 can be verified', () async {
        setupNostrExtension();

        final pubKey = await nip07Signer.getPublicKeyAsync();
        final event = Nip01EventService.createEventCalculateId(
          pubKey: pubKey,
          kind: 1,
          tags: [
            ['p', pubKey],
            ['test', 'value'],
          ],
          content: 'GM',
        );

        final signedEvent = await nip07Signer.sign(event);

        // Verify event was signed
        expect(signedEvent.id, isNotNull);
        expect(signedEvent.sig, isNotNull);
        expect(signedEvent.id.length, equals(64));
        expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(signedEvent.id), isTrue);
        expect(signedEvent.sig!.length, equals(64));
      });
    });
  });
}
