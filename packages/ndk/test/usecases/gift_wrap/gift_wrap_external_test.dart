import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

const myPrivKey =
    "9f408244a0439d6224d38a46ff5e8ab6c7ccbd5e9f8d45dbc6d9b8bc706fdebd";
const myPubkey =
    "402a35e2dc5f346a25bd3b0d930e30fe977dcac892fe3fc36f758edfbeff38d8";

const relays = [
  "wss://purplepag.es",
  "wss://relay.primal.net",
  "wss://relay.damus.io",
  "wss://nos.lol",
  "wss://bwcervpt.mooo.com",
];

void main() async {
  test(
    "gift wrap test external (REAL!)",
    () async {
      final completer = Completer<void>();
      final ndk = Ndk(
        NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            bootstrapRelays: relays),
      );

      ndk.accounts.loginPrivateKey(
        privkey: myPrivKey,
        pubkey: myPubkey,
      );

      final subscription = ndk.requests.subscription(
        filters: [
          Filter(kinds: [1059], pTags: [myPubkey], limit: 1),
        ],
      );

      subscription.stream.listen((giftWrap) async {
        try {
          final messageEvent =
              await ndk.giftWrap.fromGiftWrap(giftWrap: giftWrap);
          print(messageEvent.content);

          expect(messageEvent.content.length, greaterThan(1));

          completer.complete();
        } catch (e) {
          completer.completeError(e);
        }
      });
      await completer.future;
    },

    ///? debug only
    skip: true,
  );
}
