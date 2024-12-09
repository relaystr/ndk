// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/usecases/relay_manager_light.dart';
import 'package:ndk/entities.dart';
import 'package:test/test.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';

import '../mocks/mock_relay.dart';

void main() async {
  group('Relay Manager', () {
    final WebSocketNostrTransportFactory webSocketNostrTransportFactory =
        WebSocketNostrTransportFactory();

    test('Connect to relay', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5044);
      await relay1.startServer();

      RelayManagerLight manager = RelayManagerLight(
        globalState: GlobalState(),
        bootstrapRelays: [relay1.url],
        nostrTransportFactory: webSocketNostrTransportFactory,
      );
      await manager
          .connectRelay(
              dirtyUrl: relay1.url, connectionSource: ConnectionSource.SEED)
          .then((value) {})
          .onError((error, stackTrace) async {
        await relay1.stopServer();
      });
      await relay1.stopServer();
    });

    test('Try to connect to dead relay', () async {
      RelayManagerLight manager = RelayManagerLight(
        nostrTransportFactory: webSocketNostrTransportFactory,
        globalState: GlobalState(),
      );

      MockRelay relay1 = MockRelay(name: "relay 1");
      try {
        await manager.connectRelay(
            dirtyUrl: relay1.url, connectionSource: ConnectionSource.SEED);
        fail("should throw exception");
      } catch (e) {
        // success
      }
    });
  });
}
