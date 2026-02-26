import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() async {
  test("braodcast should update source", () async {
    final relay = MockRelay(name: "relay");

    await relay.startServer();

    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay.url],
    ));

    final keypair = Bip340.generatePrivateKey();
    final signer = Bip340EventSigner(
      privateKey: keypair.privateKey,
      publicKey: keypair.publicKey,
    );
    ndk.accounts.loginExternalSigner(signer: signer);

    final event = Nip01Event(
      pubKey: keypair.publicKey,
      kind: 1,
      tags: [],
      content: "content",
    );

    await ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;

    final localEvent = await ndk.config.cache.loadEvent(event.id);

    expect(localEvent, isNotNull);
    expect(localEvent!.sources, isNotEmpty);

    await ndk.destroy();
    await relay.stopServer();
  });
}
