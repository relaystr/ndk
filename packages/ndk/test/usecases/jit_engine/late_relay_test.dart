import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  test('a relay connecting after the request ended does not revive it',
      () async {
    final key1 = Bip340.generatePrivateKey();
    final note = Nip01Event(
      kind: Nip01Event.kTextNodeKind,
      pubKey: key1.publicKey,
      content: "note from key1",
      tags: [],
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final fast = MockRelay(name: "fast relay");
    final slow = MockRelay(name: "slow relay");

    final nip65 = Nip65.fromMap(key1.publicKey, {
      fast.url: ReadWriteMarker.readWrite,
      slow.url: ReadWriteMarker.readWrite,
    });

    await fast.startServer(nip65s: {key1: nip65}, textNotes: {key1: note});
    await slow.startServer(
      nip65s: {key1: nip65},
      textNotes: {key1: note},
      // the pubkey strategy connects to this one without holding the request
      // open, so it is long over by the time the connection is up
      delayConnection: Duration(seconds: 2),
    );

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        bootstrapRelays: [fast.url],
      ),
    );

    await ndk.userRelayLists.getSingleUserRelayList(key1.publicKey);

    final response = ndk.requests.query(
      filter: Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
      ),
    );
    expect(await response.future, isNotEmpty);

    await Future.delayed(Duration(seconds: 3));

    expect(
      ndk.relays.globalState.inFlightRequests.keys,
      isNot(contains(response.requestId)),
      reason: 'a request that already ended must not come back in flight',
    );
    expect(
      slow.connectionsThatRequested(response.requestId),
      0,
      reason: 'a REQ sent after the request ended is one nobody would CLOSE',
    );

    await ndk.destroy();
    await fast.stopServer();
    await slow.stopServer();
  });
}
