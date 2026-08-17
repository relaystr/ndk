import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';
import '../mocks/mock_slow_signer.dart';

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
    'a subscription whose authentication died with its socket comes back',
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
      // the AUTH the request waits on is still being signed when the socket dies
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

      await _waitUntil(
        () => relay.subscriptionsAuthenticatedAs(key.publicKey).contains(subId),
        timeout: const Duration(seconds: 30),
        reason: 'the subscription was given up on instead of being replayed',
      );

      await ndk.requests.closeSubscription(subId);
      await ndk.destroy();
      await relay.stopServer();
    },
  );

  test(
    'a bound connection comes back and replays only its own subscriptions',
    timeout: const Timeout(Duration(seconds: 60)),
    () async {
      final key = Bip340.generatePrivateKey();
      final relay = MockRelay(
        name: "relay requiring auth",
        requireAuthForRequests: true,
        signEvents: false,
      );
      await relay.startServer();

      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay.url],
        ),
      );
      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );

      final response = ndk.requests.subscription(
        filter: Filter(kinds: [Nip01Event.kTextNodeKind]),
      );
      final subId = response.requestId;

      await _waitUntil(
        () => relay.subscriptionsAuthenticatedAs(key.publicKey).contains(subId),
        reason: 'the subscription never reached an authenticated connection',
      );

      await relay.closeClientSockets();

      await _waitUntil(
        () => relay.subscriptionsAuthenticatedAs(key.publicKey).contains(subId),
        reason: 'the bound connection never came back with its subscription',
      );

      expect(
        relay.subscriptionsRequestedOutside(key.publicKey),
        isNot(contains(subId)),
        reason: "a bound subscription must not be replayed on another connection",
      );

      await ndk.requests.closeSubscription(subId);
      await ndk.destroy();
      await relay.stopServer();
    },
  );
}
