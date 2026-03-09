import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';

void main() {
  late Ndk ndk;
  late GiftWrap giftWrapService;

  // Test keys
  final key1 = Bip340.generatePrivateKey();
  final key2 = Bip340.generatePrivateKey();
  final key3 = Bip340.generatePrivateKey(); // For custom signer tests

  setUp(() {
    ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [],
      ),
    );

    // Login with test key
    ndk.accounts
        .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

    // Create the service
    giftWrapService = GiftWrap(accounts: ndk.accounts);
  });

  group('GiftWrapService', () {
    test('Full gift wrap and unwrap cycle should preserve the original event',
        () async {
      // Create an original rumor event
      final originalRumor = await giftWrapService.createRumor(
        content: 'Test message for gift wrap',
        kind: 1,
        tags: [],
      );

      // Wrap the rumor in a gift wrap
      final giftWrap = await giftWrapService.toGiftWrap(
        rumor: originalRumor,
        recipientPubkey: key2.publicKey,
      );

      // Verify the gift wrap has the correct structure
      expect(giftWrap.kind, equals(GiftWrap.kGiftWrapEventkind));
      expect(
          giftWrap.tags.any((tag) => tag[0] == 'p' && tag[1] == key2.publicKey),
          isTrue);

      // login as the recipient to unwrap
      ndk.accounts
          .loginPrivateKey(pubkey: key2.publicKey, privkey: key2.privateKey!);

      // Unwrap the gift wrap
      final unwrappedRumor = await giftWrapService.fromGiftWrap(
        giftWrap: giftWrap,
      );

      // Verify the unwrapped rumor matches the original
      expect(unwrappedRumor.content, equals(originalRumor.content));
      expect(unwrappedRumor.kind, equals(originalRumor.kind));
      expect(unwrappedRumor.pubKey, equals(originalRumor.pubKey));

      // Compare tags
      expect(unwrappedRumor.tags.length, equals(originalRumor.tags.length));
      for (int i = 0; i < originalRumor.tags.length; i++) {
        expect(unwrappedRumor.tags[i], equals(originalRumor.tags[i]));
      }
    });

    test('Can create a gift wrap with additional tags', () async {
      // Create a rumor
      final rumor = await giftWrapService.createRumor(
        content: 'Test message with additional tags',
        kind: 1,
        tags: [
          ['p', key2.publicKey]
        ],
      );

      // Create a seal
      final seal = await giftWrapService.sealRumor(
        rumor: rumor,
        recipientPubkey: key2.publicKey,
      );

      // Wrap the seal with additional tags
      final additionalTags = [
        ['pow', '25'],
        ['client', 'test_client'],
      ];

      final giftWrap = await GiftWrap.wrapEvent(
        recipientPublicKey: key2.publicKey,
        sealEvent: seal,
        additionalTags: additionalTags,
      );

      // Verify additional tags were included
      expect(
          giftWrap.tags.any((tag) => tag[0] == 'p' && tag[1] == key2.publicKey),
          isTrue);
      expect(giftWrap.tags.any((tag) => tag[0] == 'pow' && tag[1] == '25'),
          isTrue);
      expect(
          giftWrap.tags
              .any((tag) => tag[0] == 'client' && tag[1] == 'test_client'),
          isTrue);
    });

    test(
        'Can use custom signer instead of logged-in account for wrap and unwrap',
        () async {
      // Create a custom signer with key3 (different from logged-in key1)
      final customSigner = Bip340EventSigner(
        privateKey: key3.privateKey,
        publicKey: key3.publicKey,
      );

      // Create a rumor with custom pubkey matching the custom signer
      final originalRumor = await giftWrapService.createRumor(
        customPubkey: key3.publicKey,
        content: 'Test message with custom signer',
        kind: 1,
        tags: [],
      );

      // Wrap the rumor using the custom signer (not the logged-in account)
      final giftWrap = await giftWrapService.toGiftWrap(
        rumor: originalRumor,
        recipientPubkey: key2.publicKey,
        customSigner: customSigner,
      );

      // Create a signer for the recipient to unwrap
      final recipientSigner = Bip340EventSigner(
        privateKey: key2.privateKey,
        publicKey: key2.publicKey,
      );

      // Unwrap using the custom signer (without switching logged-in account)
      final unwrappedRumor = await giftWrapService.fromGiftWrap(
        giftWrap: giftWrap,
        customSigner: recipientSigner,
      );

      // Verify the unwrapped rumor matches the original
      expect(unwrappedRumor.content, equals(originalRumor.content));
      expect(unwrappedRumor.kind, equals(originalRumor.kind));
      expect(unwrappedRumor.pubKey, equals(key3.publicKey));
    });

    test('Custom signer seal uses correct pubkey', () async {
      // Create a custom signer
      final customSigner = Bip340EventSigner(
        privateKey: key3.privateKey,
        publicKey: key3.publicKey,
      );

      // Create a rumor
      final rumor = await giftWrapService.createRumor(
        customPubkey: key3.publicKey,
        content: 'Test seal pubkey',
        kind: 1,
        tags: [],
      );

      // Seal using the custom signer
      final seal = await giftWrapService.sealRumor(
        rumor: rumor,
        recipientPubkey: key2.publicKey,
        customSigner: customSigner,
      );

      // Verify the seal uses the custom signer's pubkey
      expect(seal.pubKey, equals(key3.publicKey));
    });
  });
}
