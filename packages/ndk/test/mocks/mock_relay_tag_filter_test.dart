import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import 'mock_event_verifier.dart';
import 'mock_relay.dart';

void main() {
  test('REQ with #r=a only returns events tagged r=a', () async {
    final relay = MockRelay(
      name: 'tag-filter-test-relay',
      explicitPort: 4080,
    );
    await relay.startServer();
    addTearDown(relay.stopServer);

    final keyPair = Bip340.generatePrivateKey();
    final writer = Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        eventVerifier: MockEventVerifier(),
        bootstrapRelays: [relay.url],
      ),
    );
    addTearDown(writer.destroy);

    final matchingEvent = Nip01Utils.signWithPrivateKey(
      event: Nip01Event(
        pubKey: keyPair.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: [
          ['r', 'a'],
        ],
        content: 'matching event',
      ),
      privateKey: keyPair.privateKey!,
    );
    final nonMatchingEvent = Nip01Utils.signWithPrivateKey(
      event: Nip01Event(
        pubKey: keyPair.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: [
          ['r', 'b'],
        ],
        content: 'non-matching event',
      ),
      privateKey: keyPair.privateKey!,
    );

    await writer.broadcast.broadcast(
      nostrEvent: matchingEvent,
      specificRelays: [relay.url],
    ).broadcastDoneFuture;
    await writer.broadcast.broadcast(
      nostrEvent: nonMatchingEvent,
      specificRelays: [relay.url],
    ).broadcastDoneFuture;

    final reader = Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        eventVerifier: MockEventVerifier(),
        bootstrapRelays: [relay.url],
      ),
    );
    addTearDown(reader.destroy);

    final query = reader.requests.query(
      filter: Filter(
        kinds: [Nip01Event.kTextNodeKind],
        tags: {
          '#r': ['a'],
        },
      ),
    );

    final receivedEvents = await query.future;

    expect(
      receivedEvents.map((event) => event.id),
      equals([matchingEvent.id]),
      reason: 'The relay must not return an event whose r tag is not "a".',
    );
  });
}
