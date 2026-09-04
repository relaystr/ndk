import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:ndk/src/cli/wallets/wallets_cli_command.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';

void main() {
  test('wallet commands do not restore unrelated remote signer accounts', () {
    expect(WalletsCliCommand().restoreAccountsOnStartup, isFalse);
  });

  test('pending delivery retries can be disabled for short-lived clients',
      () async {
    final cache = MemCacheManager();
    await cache.saveRelayDeliveryTarget(
      const RelayDeliveryTarget(
        eventId: 'pending-event',
        relayUrl: 'not-a-relay',
        reason: RelayDeliveryReason.explicit,
      ),
    );

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        bootstrapRelays: const [],
        pendingDeliveryRetriesEnabled: false,
      ),
    );
    var connectivityUpdates = 0;
    final subscription = ndk.relays.relayConnectivityChanges.listen(
      (_) => connectivityUpdates++,
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(connectivityUpdates, 0);

    await subscription.cancel();
    await ndk.destroy();
  });
}
