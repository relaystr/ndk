import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';
import '../mocks/mock_slow_signer.dart';

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
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail(reason);
}

void main() {
  test(
    'a request closed while its authentication is pending is not sent again',
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
      // slow enough that the close below lands while the AUTH is still pending
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

      // the anonymous attempt and the retry on the bound connection both got
      // refused, so the bound one is now waiting on the AUTH we slowed down
      await _waitUntil(
        () => relay.connectionsThatRequested(subId) == 2,
        reason: 'the request never reached the bound connection',
      );

      await ndk.requests.closeSubscription(subId);

      await Future<void>.delayed(const Duration(seconds: 6));

      expect(
        relay.subscriptionsAuthenticatedAs(key.publicKey),
        isNot(contains(subId)),
        reason: "a closed request must not be sent once AUTH completes",
      );
      expect(relay.connectionsThatRequested(subId), 2);
      expect(relay.activeSubscriptionCount, 0);

      await ndk.destroy();
      await relay.stopServer();
    },
  );
}
