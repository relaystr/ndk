import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  for (final engine in NdkEngine.values) {
    sameEventBroadcastTests(engine);
  }
}

/// A relay answers every EVENT it receives, so a broadcast started while the
/// same event is still in flight must not take the earlier call's OK.
void sameEventBroadcastTests(NdkEngine engine) {
  group('concurrent broadcasts of the same event [${engine.name}]', () {
    final key = Bip340.generatePrivateKey();

    Future<MockRelay> startRelay({bool requireAuthForEvents = false}) async {
      final relay = MockRelay(
        name: 'same event relay',
        requireAuthForEvents: requireAuthForEvents,
      );
      addTearDown(relay.stopServer);
      await relay.startServer();
      return relay;
    }

    Ndk ndkFor(List<MockRelay> relays) {
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: relays.map((relay) => relay.url).toList(),
          engine: engine,
          pendingDeliveryRetriesEnabled: false,
        ),
      );
      addTearDown(ndk.destroy);
      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );
      return ndk;
    }

    Nip01Event note(String content) => Nip01Event(
      pubKey: key.publicKey,
      kind: Nip01Event.kTextNodeKind,
      tags: const [],
      content: content,
    );

    Nip01Event signedNote(String content) => Nip01Utils.signWithPrivateKey(
      event: note(content),
      privateKey: key.privateKey!,
    );

    void expectAcceptedOnlyBy(
      List<RelayBroadcastResponse> responses,
      MockRelay relay,
    ) {
      expect(responses.map((response) => response.relayUrl).toList(), [
        relay.url,
      ]);
      expect(responses.single.broadcastSuccessful, isTrue);
    }

    test('both receive the relay OK for an already signed event', () async {
      final relay = await startRelay();
      final ndk = ndkFor([relay]);
      final event = signedNote('signed');

      final first = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relay.url],
      );
      final second = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relay.url],
      );

      expectAcceptedOnlyBy(await first.broadcastDoneFuture, relay);
      expectAcceptedOnlyBy(await second.broadcastDoneFuture, relay);
    });

    test('both receive the relay OK for an event ndk signs', () async {
      final relay = await startRelay();
      final ndk = ndkFor([relay]);
      final event = note('unsigned');

      final first = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relay.url],
      );
      final second = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relay.url],
      );

      expectAcceptedOnlyBy(await first.broadcastDoneFuture, relay);
      expectAcceptedOnlyBy(await second.broadcastDoneFuture, relay);
    });

    test('each reports only the relays it was sent to', () async {
      final relayA = await startRelay();
      final relayB = await startRelay();
      final ndk = ndkFor([relayA, relayB]);
      final event = signedNote('split');

      final toA = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relayA.url],
      );
      final toB = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relayB.url],
      );

      expectAcceptedOnlyBy(await toA.broadcastDoneFuture, relayA);
      expectAcceptedOnlyBy(await toB.broadcastDoneFuture, relayB);
    });

    test(
      'both receive the relay OK after it asks for authentication',
      () async {
        final relay = await startRelay(requireAuthForEvents: true);
        final ndk = ndkFor([relay]);
        final auth = AuthPolicy.allow(ndk.accounts.getLoggedAccount()!);
        final event = signedNote('auth');

        final first = ndk.broadcast.broadcast(
          nostrEvent: event,
          specificRelays: [relay.url],
          auth: auth,
        );
        final second = ndk.broadcast.broadcast(
          nostrEvent: event,
          specificRelays: [relay.url],
          auth: auth,
        );

        expectAcceptedOnlyBy(await first.broadcastDoneFuture, relay);
        expectAcceptedOnlyBy(await second.broadcastDoneFuture, relay);
      },
    );
  });
}
