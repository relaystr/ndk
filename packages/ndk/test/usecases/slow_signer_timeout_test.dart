import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';
import '../mocks/mock_slow_signer.dart';

void main() {
  test('broadcast with slow signer should not timeout during signing',
      () async {
    final key = Bip340.generatePrivateKey();
    final relay = MockRelay(name: "relay", explicitPort: 5097);
    await relay.startServer();

    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay.url],
    ));

    ndk.accounts.loginExternalSigner(
      signer: MockSlowSigner(
        innerSigner: Bip340EventSigner(
          privateKey: key.privateKey!,
          publicKey: key.publicKey,
        ),
        delay: const Duration(seconds: 2),
      ),
    );

    final event = Nip01Event(
      pubKey: key.publicKey,
      kind: Nip01Event.kTextNodeKind,
      tags: [],
      content: "test",
    );

    // timeout (1s) < signing (2s) → should fail without fix
    final result = await ndk.broadcast
        .broadcast(
          nostrEvent: event,
          specificRelays: [relay.url],
          timeout: const Duration(seconds: 1),
        )
        .broadcastDoneFuture;

    expect(result.any((r) => r.broadcastSuccessful), isTrue);

    await ndk.destroy();
    await relay.stopServer();
  });

  test('request with AUTH should not timeout during signing', () async {
    final key = Bip340.generatePrivateKey();
    final relay = MockRelay(
      name: "relay",
      explicitPort: 5098,
      requireAuthForRequests: true,
    );

    final testEvent = await Bip340EventSigner(
      privateKey: key.privateKey!,
      publicKey: key.publicKey,
    ).sign(Nip01Event(
      pubKey: key.publicKey,
      kind: Nip01Event.kTextNodeKind,
      tags: [],
      content: "test event",
    ));

    await relay.startServer(textNotes: {key: testEvent});

    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relay.url],
    ));

    ndk.accounts.loginExternalSigner(
      signer: MockSlowSigner(
        innerSigner: Bip340EventSigner(
          privateKey: key.privateKey!,
          publicKey: key.publicKey,
        ),
        delay: const Duration(seconds: 2),
      ),
    );

    // timeout (1s) < signing (2s) → should fail without fix
    final result = await ndk.requests
        .query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
          ),
          explicitRelays: [relay.url],
          timeout: const Duration(seconds: 1),
        )
        .future;

    expect(result, isNotEmpty);

    await ndk.destroy();
    await relay.stopServer();
  });
}
