import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() {
  group('AUTH timeout handling', () {
    test(
      'request should complete quickly when AUTH times out (not wait for query timeout)',
      timeout: const Timeout(Duration(seconds: 10)),
      () async {
        final key = Bip340.generatePrivateKey();

        // Relay that requires auth, sends challenge, but NEVER responds to AUTH
        final relay = MockRelay(
          name: "relay auth timeout",
          explicitPort: 5102,
          requireAuthForRequests: true,
          ignoreAuthResponse: true, // Simulate AUTH timeout
        );

        await relay.startServer();

        // Configure NDK with:
        // - Short auth callback timeout (1s)
        // - Longer query timeout (5s)
        // If the bug exists, the query will wait 5s (query timeout)
        // With the fix, it should complete in ~1s (auth callback timeout)
        final ndk = Ndk(NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay.url],
          authCallbackTimeout: const Duration(seconds: 1),
          defaultQueryTimeout: const Duration(seconds: 5),
        ));

        // Login so that AUTH will be attempted
        ndk.accounts.loginPrivateKey(
          pubkey: key.publicKey,
          privkey: key.privateKey!,
        );

        final stopwatch = Stopwatch()..start();

        final result = await ndk.requests
            .query(
              filter: Filter(
                kinds: [Nip01Event.kTextNodeKind],
                authors: [key.publicKey],
              ),
              explicitRelays: [relay.url],
            )
            .future;

        stopwatch.stop();

        // The query should complete quickly after auth timeout (< 2s)
        // NOT wait for the full query timeout (5s)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2000),
          reason:
              'Query should complete shortly after AUTH timeout (500ms), not wait for query timeout (5s). '
              'Elapsed: ${stopwatch.elapsedMilliseconds}ms',
        );

        expect(result, isEmpty);

        await ndk.destroy();
        await relay.stopServer();
      },
    );

    test(
      'request with multiple relays should complete when all AUTH attempts timeout',
      timeout: const Timeout(Duration(seconds: 10)),
      () async {
        final key = Bip340.generatePrivateKey();

        // Two relays that both require auth but never respond to AUTH
        final relay1 = MockRelay(
          name: "relay1 auth timeout",
          explicitPort: 5103,
          requireAuthForRequests: true,
          sendAuthChallenge: true,
          ignoreAuthResponse: true,
        );

        final relay2 = MockRelay(
          name: "relay2 auth timeout",
          explicitPort: 5104,
          requireAuthForRequests: true,
          sendAuthChallenge: true,
          ignoreAuthResponse: true,
        );

        await relay1.startServer();
        await relay2.startServer();

        final ndk = Ndk(NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [relay1.url, relay2.url],
          authCallbackTimeout: const Duration(seconds: 1),
          defaultQueryTimeout: const Duration(seconds: 5),
        ));

        ndk.accounts.loginPrivateKey(
          pubkey: key.publicKey,
          privkey: key.privateKey!,
        );

        final stopwatch = Stopwatch()..start();

        final result = await ndk.requests
            .query(
              filter: Filter(
                kinds: [Nip01Event.kTextNodeKind],
                authors: [key.publicKey],
              ),
            )
            .future;

        stopwatch.stop();

        // Should complete after both AUTH timeouts, not after query timeout
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2000),
          reason:
              'Query should complete shortly after AUTH timeouts (500ms), not wait for query timeout (5s). '
              'Elapsed: ${stopwatch.elapsedMilliseconds}ms',
        );

        expect(result, isEmpty);

        await ndk.destroy();
        await relay1.stopServer();
        await relay2.stopServer();
      },
    );
  });
}
