import 'package:ndk/data_layer/repositories/signers/nip46_event_signer.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

void main() {
  group('Nip46EventSigner', skip: true, () {
    late Nip46EventSigner signer;
    late BunkerConnection connection;
    late Ndk ndk;

    setUp(() {
      ndk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: Bip340EventVerifier(),
          bootstrapRelays: [],
          logLevel: Logger.logLevels.trace,
        ),
      );

      connection = BunkerConnection(
        privateKey:
        "7a8317f947fff0526749e9fe53f79def8eb0afd378c01058f37140cc8732fecc",
        remotePubkey:
        "a1fe3664f7a2b24db97e5b63869e8011c947f9abd8c03f98befafd27c38467d2",
        relays: [
          // TODO use mock relay once nip46 support is added there
          // "wss://relay.damus.io",
          // "wss://relay.nostr.band",
          // "wss://relay.nsec.app",
        ],
      );

      signer = Nip46EventSigner(connection: connection, requests: ndk.requests, broadcast: ndk.broadcast);
    });

    tearDown(() {
      signer.dispose();
    });

    test('canSign should return true', () {
      expect(signer.canSign(), isTrue);
    });

    test('sign should request remote signing and update event', () async {
      final event = Nip01Event(
        pubKey: connection.remotePubkey,
        kind: 1,
        tags: [],
        content: 'Hello, world!',
      );

      await signer.sign(event);

      expect(event.id, isNotNull);
      expect(event.sig, isNotNull);
    });

    test('getPublicKey should throw when not cached', () {
      expect(() => signer.getPublicKey(), throwsException);
    });

    test('getPublicKeyAsync should fetch and cache public key', () async {
      final publicKey = await signer.getPublicKeyAsync();

      expect(publicKey, isNotNull);
      expect(publicKey, isNotEmpty);

      // After async call, sync method should work
      expect(signer.getPublicKey(), equals(publicKey));
    });

    test('decrypt should request remote decryption', () async {
      // Create a local event signer to encrypt a test message
      final keyPair = Bip340.generatePrivateKey();
      final localSigner = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );

      const testMessage = 'Hello, this is a test message!';

      // Encrypt the message using NIP-04
      final encryptedMessage = await localSigner.encrypt(
        testMessage,
        connection.remotePubkey,
      );

      expect(encryptedMessage, isNotNull);

      // Now test decrypting with the NIP-46 signer
      final decryptedText = await signer.decrypt(
        encryptedMessage!,
        keyPair.publicKey,
      );

      expect(decryptedText, isNotNull);
      expect(decryptedText, equals(testMessage));
    });

    test(
      'encrypt should request remote encryption and be verifiable',
          () async {
        const testMessage = 'Hello, this is a test message to encrypt!';

        // Create a local event signer to verify decryption
        final keyPair = Bip340.generatePrivateKey();
        final localSigner = Bip340EventSigner(
          privateKey: keyPair.privateKey,
          publicKey: keyPair.publicKey,
        );

        // Test encrypting with the NIP-46 signer
        final encryptedMessage = await signer.encrypt(
          testMessage,
          keyPair.publicKey,
        );

        expect(encryptedMessage, isNotNull);
        expect(encryptedMessage, isNotEmpty);
        expect(encryptedMessage, isNot(equals(testMessage)));

        // Verify by decrypting with local signer
        final decryptedMessage = await localSigner.decrypt(
          encryptedMessage!,
          await signer.getPublicKeyAsync(),
        );

        expect(decryptedMessage, equals(testMessage));
      },
    );

    test('decryptNip44 should request remote NIP-44 decryption', () async {
      // Create a local event signer to encrypt a test message with NIP-44
      final keyPair = Bip340.generatePrivateKey();
      final localSigner = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );

      const testMessage = 'Hello, this is a NIP-44 test message!';

      // Encrypt the message using NIP-44
      final encryptedMessage = await localSigner.encryptNip44(
        plaintext: testMessage,
        recipientPubKey: connection.remotePubkey,
      );

      expect(encryptedMessage, isNotNull);

      // Now test decrypting with the NIP-46 signer
      final decryptedText = await signer.decryptNip44(
        ciphertext: encryptedMessage!,
        senderPubKey: keyPair.publicKey,
      );

      expect(decryptedText, isNotNull);
      expect(decryptedText, equals(testMessage));
    });

    test(
      'encryptNip44 should request remote NIP-44 encryption and be verifiable',
          () async {
        const testMessage = 'Hello, this is a NIP-44 encryption test!';

        // Create a local event signer to verify decryption
        final keyPair = Bip340.generatePrivateKey();
        final localSigner = Bip340EventSigner(
          privateKey: keyPair.privateKey,
          publicKey: keyPair.publicKey,
        );

        // Test encrypting with the NIP-46 signer
        final encryptedMessage = await signer.encryptNip44(
          plaintext: testMessage,
          recipientPubKey: keyPair.publicKey,
        );

        expect(encryptedMessage, isNotNull);
        expect(encryptedMessage, isNotEmpty);
        expect(encryptedMessage, isNot(equals(testMessage)));

        // Verify by decrypting with local signer
        final decryptedMessage = await localSigner.decryptNip44(
          ciphertext: encryptedMessage!,
          senderPubKey: await signer.getPublicKeyAsync(),
        );

        expect(decryptedMessage, equals(testMessage));
      },
    );

    test('ping should return pong', () async {
      final response = await signer.ping();
      expect(response, equals('pong'));
    });
  });
}
