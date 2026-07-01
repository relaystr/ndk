// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport_factory.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import 'package:ndk/domain_layer/entities/ndk_request.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';
import 'package:ndk/entities.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

void main() async {
  group('Relay Manager', () {
    final WebSocketClientNostrTransportFactory webSocketNostrTransportFactory =
        WebSocketClientNostrTransportFactory();

    test('Connect to relay', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5044);
      await relay1.startServer();

      RelayManager manager = RelayManager(
        globalState: GlobalState(),
        bootstrapRelays: [relay1.url],
        nostrTransportFactory: webSocketNostrTransportFactory,
      );
      await manager
          .connectRelay(
              dirtyUrl: relay1.url, connectionSource: ConnectionSource.seed)
          .then((value) {})
          .onError((error, stackTrace) async {
        await relay1.stopServer();
      });
      await relay1.stopServer();
    });

    test('wasLastConnectTryLongerThanSeconds', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5044);
      await relay1.startServer();

      RelayManager manager = RelayManager(
        globalState: GlobalState(),
        bootstrapRelays: [relay1.url],
        nostrTransportFactory: webSocketNostrTransportFactory,
      );
      await manager
          .connectRelay(
              dirtyUrl: relay1.url, connectionSource: ConnectionSource.seed)
          .then((value) {})
          .onError((error, stackTrace) async {
        await relay1.stopServer();
      });

      expect(
          manager.globalState.relays[relay1.url]!.relay
              .wasLastConnectTryLongerThanSeconds(120),
          false);
      await relay1.stopServer();
    });

    test('reconnects after relay-side socket close', () async {
      // The plain WebSocketNostrTransport has no internal auto-reconnect, so
      // recovering from a relay-side close relies entirely on the
      // reconnect-on-close path in _startListeningToSocket's onDone handler.
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5046);
      await relay1.startServer();

      RelayManager manager = RelayManager(
        globalState: GlobalState(),
        bootstrapRelays: [relay1.url],
        nostrTransportFactory: WebSocketNostrTransportFactory(),
      );
      await manager.connectRelay(
          dirtyUrl: relay1.url, connectionSource: ConnectionSource.seed);
      expect(manager.isRelayConnected(relay1.url), true);

      // The server registers the client asynchronously; closing before that
      // would close zero sockets and leave the client connected.
      final registrationDeadline = DateTime.now().add(Duration(seconds: 5));
      while (DateTime.now().isBefore(registrationDeadline) &&
          relay1.connectedClientCount == 0) {
        await Future.delayed(Duration(milliseconds: 10));
      }
      expect(relay1.connectedClientCount, 1);

      final relayConnectivity = manager.globalState.relays[relay1.url]!;
      expect(relayConnectivity.stats.connections, 1);

      // Backdate the last connect attempt so the reconnect is not suppressed
      // by the FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS throttle.
      relayConnectivity.relay.lastConnectTry = 0;

      // Relay-side disconnect: the server stays up, only the socket dies.
      await relay1.closeClientSockets();

      // A second successful connection can only come from the
      // reconnect-on-close path; the counter is monotonic, so this cannot
      // race with how fast the reconnect happens.
      final reconnectDeadline = DateTime.now().add(Duration(seconds: 5));
      while (DateTime.now().isBefore(reconnectDeadline) &&
          relayConnectivity.stats.connections < 2) {
        await Future.delayed(Duration(milliseconds: 50));
      }
      expect(relayConnectivity.stats.connections, greaterThanOrEqualTo(2),
          reason:
              'RelayManager should reconnect after the relay closed the socket.');
      expect(manager.isRelayConnected(relay1.url), true);

      // Keep the teardown from racing another reconnect attempt against the
      // stopped server.
      manager.allowReconnectRelays = false;
      await manager.globalState.relays[relay1.url]?.close();
      await relay1.stopServer();
    });

    test('Try to connect to dead relay', () async {
      RelayManager manager = RelayManager(
        nostrTransportFactory: webSocketNostrTransportFactory,
        bootstrapRelays: [],
        globalState: GlobalState(),
      );

      MockRelay relay1 = MockRelay(name: "relay 1");
      try {
        await manager.connectRelay(
            dirtyUrl: relay1.url, connectionSource: ConnectionSource.seed);
        fail("should throw exception");
      } catch (e) {
        // success
      }
    });
    test('Try to connect to wss://brb.io', skip: true, () async {
      RelayManager manager = RelayManager(
        nostrTransportFactory: webSocketNostrTransportFactory,
        bootstrapRelays: [],
        globalState: GlobalState(),
      );

      try {
        await manager.connectRelay(
            dirtyUrl: "wss://brb.io", connectionSource: ConnectionSource.seed);
        fail("should throw exception");
      } catch (e) {
        // success
      }
    });

    test(
        'CLOSED message bug - should not remove entire request from inFlightRequests',
        () async {
      // This test exposes a bug where receiving a CLOSED message from one relay
      // removes the entire request from globalState.inFlightRequests, causing
      // events from other relays to be lost since there's no request entry to handle them.

      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5050);
      MockRelay relay2 = MockRelay(name: "relay 2", explicitPort: 5051);

      await relay1.startServer();
      await relay2.startServer();

      RelayManager manager = RelayManager(
        globalState: GlobalState(),
        bootstrapRelays: [],
        nostrTransportFactory: webSocketNostrTransportFactory,
      );

      // Connect to both relays
      await manager.connectRelay(
          dirtyUrl: relay1.url, connectionSource: ConnectionSource.seed);
      await manager.connectRelay(
          dirtyUrl: relay2.url, connectionSource: ConnectionSource.seed);

      // Create test filters for the request
      final testFilters = [
        Filter(kinds: [1], limit: 10)
      ];
      final requestId = "test_request_123";

      // Create a request state in globalState.inFlightRequests
      final request = NdkRequest.query(
        requestId,
        name: "test_request",
        filters: testFilters,
        closeOnEOSE: false, // This is a subscription, not a one-time request
        timeoutDuration: Duration(seconds: 30),
      );

      manager.globalState.inFlightRequests[requestId] = RequestState(request);

      // Register the request with both relays
      manager.registerRelayRequest(
        reqId: requestId,
        relayUrl: relay1.url,
        filters: testFilters,
      );
      manager.registerRelayRequest(
        reqId: requestId,
        relayUrl: relay2.url,
        filters: testFilters,
      );

      // Verify both relay requests are registered
      expect(manager.globalState.inFlightRequests[requestId], isNotNull);
      expect(
          manager.globalState.inFlightRequests[requestId]!.requests[relay1.url],
          isNotNull);
      expect(
          manager.globalState.inFlightRequests[requestId]!.requests[relay2.url],
          isNotNull);

      // Create a test event that relay2 will send
      final testEvent = Nip01Event(
        kind: 1,
        pubKey: "test_pubkey",
        content: "Test content from relay2",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      final List<Nip01Event> eventsReceived = [];

      // Listen to the request stream to collect events
      final streamSubscription = manager
          .globalState.inFlightRequests[requestId]!.networkController.stream
          .listen((event) {
        eventsReceived.add(event);
      });

      // Give a moment for stream setup
      await Future.delayed(Duration(milliseconds: 50));

      // Step 1: relay1 sends a CLOSED message
      // This will trigger the bug - the entire request gets removed from inFlightRequests
      relay1.sendClosed(requestId, message: "rate limited");

      // Give a moment for the CLOSED message to be processed
      await Future.delayed(Duration(milliseconds: 100));

      // CORRECT BEHAVIOR: The request should still exist in inFlightRequests
      // because relay2 hasn't finished yet. Only relay1's entry should be removed
      // from the requests map, not the entire request.
      expect(manager.globalState.inFlightRequests[requestId], isNotNull,
          reason:
              "Request should still exist in inFlightRequests after CLOSED from relay1, since relay2 hasn't finished");

      // The request should still have relay2's entry, but relay1's should be removed or marked as closed
      expect(
          manager.globalState.inFlightRequests[requestId]!.requests[relay2.url],
          isNotNull,
          reason: "Relay2's request entry should still exist");

      // Step 2: relay2 tries to send an event
      // This should work because the request entry should still exist
      relay2.sendEvent(event: testEvent, subId: requestId);

      // Give time for event processing
      await Future.delayed(Duration(milliseconds: 100));

      // CORRECT BEHAVIOR: Events from relay2 should be received
      expect(eventsReceived.length, equals(1),
          reason:
              "Event from relay2 should be received even after relay1 sent CLOSED message");

      expect(eventsReceived.first.content, equals("Test content from relay2"),
          reason: "The received event should be the one sent by relay2");

      // Clean up
      await streamSubscription.cancel();
      await relay1.stopServer();
      await relay2.stopServer();
    });
  });
}
