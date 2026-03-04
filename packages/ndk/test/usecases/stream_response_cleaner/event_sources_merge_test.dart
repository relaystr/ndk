import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  test("requests should update sources", () async {
    final bannedWord = "cow";

    final relay1 = MockRelay(name: "relay 1");
    final relay2 = MockRelay(name: "relay 2");
    final relay3 = MockRelay(name: "relay 2", bannedWord: bannedWord);

    await relay1.startServer();
    await relay2.startServer();
    await relay3.startServer();

    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay1.url, relay2.url, relay3.url],
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
      content: bannedWord,
    );
    await ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;

    await ndk.config.cache.clearAll();

    final query = ndk.requests.query(filter: Filter(ids: [event.id]));
    final events = await query.future;

    expect(events.first.sources.length, equals(2));

    await ndk.destroy();
    await relay1.stopServer();
    await relay2.stopServer();
    await relay3.stopServer();
  });
}
