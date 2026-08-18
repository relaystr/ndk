import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';
import '../mocks/mock_event_verifier.dart';

/// Waits until [condition] holds, polling so the test does not depend on
/// reconnect backoff timings.
Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
  String reason = 'condition never became true',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  fail(reason);
}

void main() {
  test(
    'a query whose socket died before EOSE is replayed on the new one',
    timeout: const Timeout(Duration(seconds: 90)),
    () async {
      final author = Bip340.generatePrivateKey();
      final note = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: author.publicKey,
        content: "survived the reconnect",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      final relay = MockRelay(name: "slow relay");
      // holds every REQ long enough for the socket to die before the answer
      await relay.startServer(
        textNotes: {author: note},
        delayResponse: const Duration(seconds: 5),
      );

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay.url],
        ),
      );

      final response = ndk.requests.query(
        filter: Filter(authors: [author.publicKey]),
        timeout: const Duration(seconds: 40),
      );

      await _waitUntil(
        () => relay.connectedClientCount == 1,
        reason: 'the query never reached the relay',
      );
      await Future<void>.delayed(const Duration(seconds: 1));

      await relay.closeClientSockets();

      final events = await response.future;

      expect(
        events.map((e) => e.content),
        contains("survived the reconnect"),
        reason:
            'a query that lost its socket before EOSE must go back up on the '
            'replacement connection instead of timing out empty',
      );

      await ndk.destroy();
      await relay.stopServer();
    },
  );
}
