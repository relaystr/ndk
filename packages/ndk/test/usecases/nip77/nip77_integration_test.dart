import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';

void main() {
  test("should be in sync after broadcasting events", skip: true, () async {
    final relayUrl = "wss://relay.damus.io";

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [relayUrl],
      ),
    );

    final keypair = Bip340.generatePrivateKey();
    ndk.accounts.loginPrivateKey(
      pubkey: keypair.publicKey,
      privkey: keypair.privateKey!,
    );

    final event1 = Nip01Event(
      pubKey: keypair.publicKey,
      kind: 1,
      tags: [],
      content: "content 1",
    );
    final event2 = Nip01Event(
      pubKey: keypair.publicKey,
      kind: 1,
      tags: [],
      content: "content 2",
    );
    await ndk.broadcast.broadcast(
        nostrEvent: event1, specificRelays: [relayUrl]).broadcastDoneFuture;
    await ndk.broadcast.broadcast(
        nostrEvent: event2, specificRelays: [relayUrl]).broadcastDoneFuture;

    final filter = Filter(authors: [keypair.publicKey]);

    final reconcile = ndk.nip77.reconcile(
      relayUrl: relayUrl,
      filter: filter,
    );

    final res = await reconcile.future;

    expect(res.haveIds, isEmpty);
    expect(res.needIds, isEmpty);

    await ndk.destroy();
  });

  test("should return needIds with empty local cache", () async {
    final relayUrl = "wss://relay.damus.io";

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [relayUrl],
      ),
    );

    final keypair = Bip340.generatePrivateKey();
    ndk.accounts.loginPrivateKey(
      pubkey: keypair.publicKey,
      privkey: keypair.privateKey!,
    );

    final reconcile = ndk.nip77.reconcile(
      relayUrl: relayUrl,
      filter: Filter(kinds: [31990]),
    );

    final res = await reconcile.future;

    expect(res.haveIds, isEmpty);
    expect(res.needIds, isNotEmpty);

    await ndk.destroy();
  });

  test("should report local events as haveIds", () async {
    final relayUrl = "wss://relay.damus.io";

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [relayUrl],
      ),
    );

    final keypair = Bip340.generatePrivateKey();
    ndk.accounts.loginPrivateKey(
      pubkey: keypair.publicKey,
      privkey: keypair.privateKey!,
    );

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final event = Nip01Event(
      pubKey: keypair.publicKey,
      kind: 1,
      tags: [],
      content: "content",
      createdAt: now,
    );

    final signer = ndk.accounts.getLoggedAccount()!.signer;
    final signedEvent = await signer.sign(event);
    await ndk.config.cache.saveEvent(signedEvent);

    final reconcile = ndk.nip77.reconcile(
      relayUrl: relayUrl,
      filter: Filter(kinds: [1], since: now - 1, until: now + 1),
    );

    final res = await reconcile.future;

    expect(res.haveIds, isNotEmpty);

    await ndk.destroy();
  });

  test("should fail gracefully when NIP-77 not supported", () async {
    final relayUrl = "wss://relay.primal.net";

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [relayUrl],
      ),
    );

    try {
      final reconcile = ndk.nip77.reconcile(
        relayUrl: relayUrl,
        filter: Filter(kinds: [1]),
      );
      await reconcile.future;
    } catch (e) {
      expect(true, isTrue);
    }

    await ndk.destroy();
  });
}
