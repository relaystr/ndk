import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/nips/nip01/bip340.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_relay.dart';

void main() {

  group('Relay Manager', () {
    test('Connect to relay', () async {
      MockRelay mockRelay = MockRelay();
      await mockRelay.startServer();
      RelayManager manager = RelayManager();
      await manager
          .connectRelay(mockRelay.url)
          .then((value) {})
          .onError((error, stackTrace) async {
        await mockRelay.stopServer();
      });
      await mockRelay.stopServer();
    });

    test('Try to connect to dead relay', () async {
      MockRelay mockRelay1 = MockRelay();
      RelayManager manager = RelayManager();
      try {
        await manager.connectRelay(mockRelay1.url);
        fail("should throw exception");
      } catch (e) {
        // success
      }
      ;
    });

    test('Get Nip65 for some pubkeys', () async {
      MockRelay mockRelay1 = MockRelay();
      MockRelay mockRelay2 = MockRelay();
      MockRelay mockRelay3 = MockRelay();

      KeyPair key1 = Bip340.generatePrivateKey();
      KeyPair key2 = Bip340.generatePrivateKey();
      KeyPair key3 = Bip340.generatePrivateKey();

      Map<KeyPair, Nip65> nip65s = {
        key1: Nip65(
          {
            mockRelay1.url: ReadWriteMarker.readWrite,
            mockRelay2.url: ReadWriteMarker.readWrite
          },
        ),
        key2: Nip65({mockRelay2.url: ReadWriteMarker.readWrite}),
        key3: Nip65({mockRelay3.url: ReadWriteMarker.writeOnly}),
      };

      await Future.wait([
        mockRelay1.startServer(nip65s: nip65s),
        mockRelay2.startServer(),
        mockRelay3.startServer()
      ]);
      // ===============================================

      RelayManager manager = RelayManager();
      await manager.init(
          bootstrapRelays: [mockRelay1.url, mockRelay2.url, mockRelay3.url]);

      List<KeyPair> keys = [key1, key2, key3];

      await manager.query(
          Filter(
              kinds: [Nip65.kind],
              authors: keys.map((e) => e.publicKey).toList()), (event) {
        Nip65 nip65 = Nip65.fromEvent(event);
        // print(
        //     "RESULT OF nip65 request for ${event.pubKey}: ${nip65.relays.keys} (source:${event.sources})");
        KeyPair key =
            nip65s.keys.where((k) => k.publicKey == event.pubKey).first;
        expect(nip65.relays.keys, nip65s[key]!.relays.keys);
        expect(nip65.relays.values, nip65s[key]!.relays.values);
      });

      // ===============================================
      await Future.wait([
        mockRelay1.stopServer(),
        mockRelay2.stopServer(),
        mockRelay3.stopServer()
      ]);
    });
  });
}
