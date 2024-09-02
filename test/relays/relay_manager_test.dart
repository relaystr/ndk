// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import 'package:ndk/ndk.dart';

import '../mocks/mock_relay.dart';

void main() async {
  group('Relay Manager', () {
    final WebSocketNostrTransportFactory _webSocketNostrTransportFactory =
        WebSocketNostrTransportFactory();

    test('Connect to relay', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5044);
      await relay1.startServer();

      RelayManager manager = RelayManager(
        bootstrapRelays: [relay1.url],
        nostrTransportFactory: _webSocketNostrTransportFactory,
      );
      await manager
          .connectRelay(relay1.url)
          .then((value) {})
          .onError((error, stackTrace) async {
        await relay1.stopServer();
      });
      await relay1.stopServer();
    });

    test('Try to connect to dead relay', () async {
      RelayManager manager = RelayManager(
        nostrTransportFactory: _webSocketNostrTransportFactory,
      );

      MockRelay relay1 = MockRelay(name: "relay 1");
      try {
        await manager.connectRelay(relay1.url);
        fail("should throw exception");
      } catch (e) {
        // success
      }
    });
  });
}
