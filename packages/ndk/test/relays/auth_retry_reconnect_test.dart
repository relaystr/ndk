import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

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
    'a query retrying its authentication is not closed by another relay',
    timeout: const Timeout(Duration(seconds: 120)),
    () async {
      final key = Bip340.generatePrivateKey();
      final note = Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key.publicKey,
        content: "served after the reconnect",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      final authRelay = MockRelay(
        name: "relay requiring auth",
        requireAuthForRequests: true,
        signEvents: false,
        challengePerConnection: true,
        // the authentication the query waits on is still unanswered when the
        // relay goes away, so it fails while the connection has no socket
        silenceFirstAuths: 1,
      );
      final slowRelay = MockRelay(name: "slow relay");
      await authRelay.startServer(textNotes: {key: note});
      // answers late enough for its EOSE to land while the other relay is gone
      await slowRelay.startServer(delayResponse: const Duration(seconds: 5));

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [authRelay.url, slowRelay.url],
        ),
      );
      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );

      final response = ndk.requests.query(
        filter: Filter(authors: [key.publicKey]),
        timeout: const Duration(seconds: 60),
      );

      await _waitUntil(
        () => authRelay.receivedAuths == 1,
        reason: 'the query never authenticated',
      );

      await authRelay.stopServer();
      // the EOSE of the other relay lands here, on a request whose last relay
      // is retrying its authentication on a socket that is not back yet
      await Future<void>.delayed(const Duration(seconds: 6));
      await authRelay.startServer(textNotes: {key: note});

      final events = await response.future;

      expect(
        events.map((e) => e.content),
        contains("served after the reconnect"),
        reason:
            'a request retrying its authentication must outlive the relays '
            'that finished, and be replayed once its connection is back',
      );

      await ndk.destroy();
      await authRelay.stopServer();
      await slowRelay.stopServer();
    },
  );
}
