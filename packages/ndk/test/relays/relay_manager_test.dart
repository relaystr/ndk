// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport_factory.dart';
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
    test('Try to connect to wss://brb.io', () async {
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
  });
}
