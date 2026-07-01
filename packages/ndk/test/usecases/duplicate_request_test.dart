import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() {
  test(
    'duplicate request should not wait for timeout when original completes',
    () async {
      final key = Bip340.generatePrivateKey();

      // Create a mock relay that responds quickly
      final relay = MockRelay(
        name: "relay duplicate test",
        explicitPort: 5105,
      );

      await relay.startServer();

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [relay.url],
        // Short query timeout - if bug exists, duplicate will wait this long
        defaultQueryTimeout: const Duration(seconds: 5),
      ));

      final current = ndk.relays.getRelayConnectivity(relay.url);
      if (current?.isConnected != true) {
        await ndk.connectivity.relayConnectivityChanges
            .firstWhere((relays) => relays[relay.url]?.isConnected == true)
            .timeout(const Duration(seconds: 10));
      }

      final stopwatch = Stopwatch()..start();
      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key.publicKey],
      );

      // Create two identical requests at the same time (same filter)
      // One will be treated as a duplicate
      final futures = await Future.wait([
        ndk.requests.query(filter: filter, explicitRelays: [relay.url]).future,
        ndk.requests.query(filter: filter, explicitRelays: [relay.url]).future,
      ]);

      stopwatch.stop();

      // Both requests should complete quickly (when relay responds with EOSE)
      // NOT wait for the 5s query timeout
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Both requests should complete quickly when relay responds. '
            'Elapsed: ${stopwatch.elapsedMilliseconds}ms. '
            'If this fails, the duplicate request timeout fix is needed.',
      );

      expect(futures[0], isEmpty);
      expect(futures[1], isEmpty);

      await ndk.destroy();
      await relay.stopServer();
    },
  );
}
