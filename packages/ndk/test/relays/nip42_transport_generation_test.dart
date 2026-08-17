import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';
import '../mocks/mock_slow_signer.dart';

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 25),
  String reason = 'condition never became true',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail(reason);
}

void main() {
  test(
    'an authentication started on a dead socket does not stall its replacement',
    timeout: const Timeout(Duration(seconds: 90)),
    () async {
      final key = Bip340.generatePrivateKey();
      final relay = MockRelay(
        name: "relay requiring auth",
        requireAuthForRequests: true,
        signEvents: false,
        challengePerConnection: true,
      );
      await relay.startServer();

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay.url],
        ),
      );
      // the AUTH of the first socket is still being signed when it dies
      ndk.accounts.loginExternalSigner(
        signer: MockSlowSigner(
          innerSigner: Bip340EventSigner(
            privateKey: key.privateKey!,
            publicKey: key.publicKey,
          ),
          delay: const Duration(seconds: 3),
        ),
      );

      final response = ndk.requests.subscription(
        filter: Filter(kinds: [Nip01Event.kTextNodeKind]),
      );
      final subId = response.requestId;

      await _waitUntil(
        () => relay.connectionsThatRequested(subId) == 2,
        reason: 'the request never reached the bound connection',
      );

      await relay.closeClientSockets();

      // the replacement socket must answer its own challenge. Sharing the
      // attempt of the dead one replays a challenge this socket never sent,
      // and the relay refuses it
      await _waitUntil(
        () => relay.connectionsAuthenticatedAs(key.publicKey) == 1,
        reason: 'the replacement socket never authenticated',
      );

      await ndk.requests.closeSubscription(subId);
      await ndk.destroy();
      await relay.stopServer();
    },
  );
}
