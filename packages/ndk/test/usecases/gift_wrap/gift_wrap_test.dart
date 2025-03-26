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

      final giftWrap = await giftWrapService.wrapSeal(
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
  });
}
