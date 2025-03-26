import 'dart:developer';

import 'package:ndk/ndk.dart';

import '../test/mocks/mock_event_verifier.dart';

giftWrapExample() async {
  /// example ndk
  final ndk = Ndk(
    NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [],
    ),
  );

  /// Wrap event:

  // Create an original rumor event
  final originalRumor = await ndk.giftWrap.createRumor(
    content: 'Test message for gift wrap',
    kind: 1,
    tags: [],
  );

  // Wrap the rumor in a gift wrap
  final giftWrap = await ndk.giftWrap.toGiftWrap(
    rumor: originalRumor,
    recipientPubkey: "<reciever public key>",
  );

  log(giftWrap.toString());

  /// Unwrap event:

  final recvEvent = await ndk.giftWrap.fromGiftWrap(giftWrap: giftWrap);

  log(recvEvent.toString());
}
