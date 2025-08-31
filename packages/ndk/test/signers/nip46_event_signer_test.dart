import 'package:ndk/data_layer/repositories/signers/nip46_event_signer.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

void main() {
  group('Nip46EventSigner with MockRelay', () {
    late Nip46EventSigner signer;
    late BunkerConnection connection;
    late Ndk ndk;
    late MockRelay mockRelay;

    setUp(() async {
      // Start the mock relay with NIP-46 support
      mockRelay = MockRelay(
        name: 'nip46-test-relay',
        signEvents: true,
        explicitPort: 4046, // Use a specific port for NIP-46 tests
      );
      await mockRelay.startServer();

      ndk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: Bip340EventVerifier(),
          bootstrapRelays: [mockRelay.url], // Use the mock relay URL
          logLevel: Logger.logLevels.trace,
        ),
      );

      connection = BunkerConnection(
        privateKey:
            "7a8317f947fff0526749e9fe53f79def8eb0afd378c01058f37140cc8732fecc",
        remotePubkey: MockRelay
            .remoteSignerPublicKey, // Use the mock relay's remote signer public key
        relays: [mockRelay.url], // Use the mock relay
      );

      signer = Nip46EventSigner(
          connection: connection,
          requests: ndk.requests,
          broadcast: ndk.broadcast);
    });

    tearDown(() async {
      signer.dispose();
      await mockRelay.stopServer();
    });

    test('canSign should return true', () {
      expect(signer.canSign(), isTrue);
    });

    test('sign should request remote signing and update event', () async {
      final event = Nip01Event(
        pubKey: MockRelay
            .remoteSignerPublicKey, // Use the mock relay's signer public key
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

    test('login with bunker URL should connect successfully', () async {
      // Create bunker URL with mock relay's remote signer
      final bunkerUrl = 'bunker://${MockRelay.remoteSignerPublicKey}'
          '?relay=${mockRelay.url}'
          '&secret=test-secret-123';

      // Use bunkers to connect with the URL
      final bunkers = Bunkers(
        requests: ndk.requests,
        broadcast: ndk.broadcast,
      );

      final bunkerConnection = await bunkers.connectWithBunkerUrl(
        bunkerUrl,
        authCallback: (authUrl) {
          // In a real app, this would open the auth URL
          // Auth URL received: authUrl
        },
      );

      expect(bunkerConnection, isNotNull);
      expect(bunkerConnection!.remotePubkey,
          equals(MockRelay.remoteSignerPublicKey));
      expect(bunkerConnection.relays, contains(mockRelay.url));

      // Create a signer with the connection and test signing
      final bunkerSigner = Nip46EventSigner(
        connection: bunkerConnection,
        requests: ndk.requests,
        broadcast: ndk.broadcast,
      );

      final testEvent = Nip01Event(
        pubKey: MockRelay.remoteSignerPublicKey,
        kind: 1,
        tags: [],
        content: 'Test event via bunker URL',
      );

      await bunkerSigner.sign(testEvent);

      expect(testEvent.id, isNotNull);
      expect(testEvent.sig, isNotNull);

      bunkerSigner.dispose();
    });

    test('loginWithBunkerUrl should set up account correctly', () async {
      // Create bunker URL with mock relay's remote signer
      final bunkerUrl = 'bunker://${MockRelay.remoteSignerPublicKey}'
          '?relay=${mockRelay.url}'
          '&secret=bunker-url-test-secret';

      // Create bunkers and accounts instances
      final bunkers = Bunkers(
        requests: ndk.requests,
        broadcast: ndk.broadcast,
      );

      final accounts = Accounts();

      // Login with the bunker URL
      final connection = await accounts.loginWithBunkerUrl(
        bunkerUrl: bunkerUrl,
        bunkers: bunkers,
        authCallback: (authUrl) {
          // In a real app, this would open the auth URL
        },
      );

      // Verify connection was established
      expect(connection, isNotNull);
      expect(connection!.remotePubkey, equals(MockRelay.remoteSignerPublicKey));
      expect(connection.relays, contains(mockRelay.url));

      // Verify the account was set up correctly
      expect(accounts.isLoggedIn, isTrue);
      expect(accounts.getPublicKey(), equals(MockRelay.remoteSignerPublicKey));

      // Test signing an event through the accounts system
      final testEvent = Nip01Event(
        pubKey: accounts.getPublicKey()!,
        kind: 1,
        tags: [],
        content: 'Test event via loginWithBunkerUrl',
      );

      await accounts.sign(testEvent);

      expect(testEvent.id, isNotNull);
      expect(testEvent.sig, isNotNull);

      // Cleanup
      accounts.logout();
      expect(accounts.isLoggedIn, isFalse);
    });

    test('loginWithBunkerConnection should set up account correctly', () async {
      // Create a bunker connection directly
      final bunkerConnection = BunkerConnection(
        privateKey:
            "7a8317f947fff0526749e9fe53f79def8eb0afd378c01058f37140cc8732fecc",
        remotePubkey: MockRelay.remoteSignerPublicKey,
        relays: [mockRelay.url],
      );

      // Create bunkers and accounts instances
      final bunkers = Bunkers(
        requests: ndk.requests,
        broadcast: ndk.broadcast,
      );

      final accounts = Accounts();

      // Login with the bunker connection
      await accounts.loginWithBunkerConnection(
        connection: bunkerConnection,
        bunkers: bunkers,
        authCallback: (authUrl) {
          // In a real app, this would open the auth URL
        },
      );

      // Verify the account was set up correctly
      expect(accounts.isLoggedIn, isTrue);
      expect(accounts.getPublicKey(), equals(MockRelay.remoteSignerPublicKey));

      // Test signing an event through the accounts system
      final testEvent = Nip01Event(
        pubKey: accounts.getPublicKey()!,
        kind: 1,
        tags: [],
        content: 'Test event via loginWithBunkerConnection',
      );

      await accounts.sign(testEvent);

      expect(testEvent.id, isNotNull);
      expect(testEvent.sig, isNotNull);

      // Cleanup
      accounts.logout();
      expect(accounts.isLoggedIn, isFalse);
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
        MockRelay
            .remoteSignerPublicKey, // Use the mock relay's signer public key
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
        recipientPubKey: MockRelay
            .remoteSignerPublicKey, // Use the mock relay's signer public key
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
