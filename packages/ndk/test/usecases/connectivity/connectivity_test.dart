import 'dart:async';

import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  group('connectivity test', () {
    late MockRelay relay0;
    late MockRelay relay1;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5197);
      relay1 = MockRelay(name: "relay 1", explicitPort: 5198);

      await relay0.startServer();
      await relay1.startServer();

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        bootstrapRelays: [relay0.url],
        // logLevel: Logger.logLevels.trace,
        ignoreRelays: [],
      );

      ndk = Ndk(config);

      await ndk.relays.seedRelaysConnected;
    });

    tearDown(() async {
      await ndk.destroy();
      await relay0.stopServer();
      await relay1.stopServer();
    });

    test('state updates are received', () async {
      final completer = Completer<Map<String, RelayConnectivity>>();

      final subscription =
          ndk.connectivity.relayConnectivityChanges.listen((event) {
        // When we detect a change where one relay is disconnected, complete the completer
        if (event[relay0.url]?.isConnected == true &&
            event[relay1.url]?.isConnected == true) {
          completer.complete(event);
        }
      });

      // Ensure connected
      await Future.delayed(Duration(milliseconds: 500));

      ndk.requests.query(filters: [
        Filter(kinds: [1])
      ], explicitRelays: [
        relay1.url
      ]);

      // Wait for the disconnection event with a timeout
      final result = await completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException('Relay connection event not received'),
      );

      expect(result[relay0.url]?.isConnected, true);
      expect(result[relay1.url]?.isConnected, true);

      subscription.cancel();
    });

    test('try reconnect', () async {
      ndk.requests.query(filters: [
        Filter(kinds: [1])
      ], explicitRelays: [
        relay1.url
      ]);

      // Ensure connected
      await Future.delayed(Duration(milliseconds: 500));
      expect(
          ndk.connectivity.relayConnectivityChanges,
          emitsInAnyOrder([
            predicate<Map<String, RelayConnectivity>>((event) {
              expect(event[relay0.url]?.isConnected, true);
              expect(event[relay1.url]?.isConnected, true);
              return true;
            }),
          ]));

      // Disconnect relay 0
      await ndk.relays.globalState.relays[relay0.url]?.close();

      expect(
          ndk.connectivity.relayConnectivityChanges,
          emitsInAnyOrder([
            predicate<Map<String, RelayConnectivity>>((event) {
              expect(event[relay0.url]?.isConnected, false);
              expect(event[relay1.url]?.isConnected, true);
              return true;
            }),
          ]));

      // Reconnect relay 0
      await ndk.connectivity.tryReconnect();
      expect(
          ndk.connectivity.relayConnectivityChanges,
          emitsInAnyOrder([
            predicate<Map<String, RelayConnectivity>>((event) {
              expect(event[relay0.url]?.isConnected, true);
              expect(event[relay1.url]?.isConnected, true);
              return true;
            }),
          ]));
    });
  });
}
