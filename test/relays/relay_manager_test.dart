// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';

import '../mocks/mock_relay.dart';

void main() async {
  group('Relay Manager', () {
    test('Connect to relay', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5044);
      await relay1.startServer();
      RelayManager manager = RelayManager(bootstrapRelays: [relay1.url]);
      await manager
          .connectRelay(relay1.url)
          .then((value) {})
          .onError((error, stackTrace) async {
        await relay1.stopServer();
      });
      await relay1.stopServer();
    });

    test('Try to connect to dead relay', () async {
      RelayManager manager = RelayManager();

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
