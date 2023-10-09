import 'package:dart_ndk/bip340.dart';
import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/filter.dart';
import 'package:dart_ndk/nips/nip65.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';

import 'mock_relay.dart';

void main() {
  group('Bip340', () {
    test('sign and verify', () {
      final keyPair = Bip340.generatePrivateKey();
      const message = 'Hello, World!';
      // message to HEX
      final messageHex = HEX.encode(message.codeUnits);
      final signature = Bip340.sign(messageHex, keyPair.privateKey!);
      expect(Bip340.verify(messageHex, signature, keyPair.publicKey), isTrue);
    });

    test('getPublicKey', () {
      final keyPair = Bip340.generatePrivateKey();
      expect(
          Bip340.getPublicKey(keyPair.privateKey!), equals(keyPair.publicKey));
    });
  });

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
      // await mockRelay1.startServer();
      RelayManager manager = RelayManager();
      try {
        await manager.connectRelay(mockRelay1.url);
        fail("should throw exception");
      } catch (e) {}
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
        key3: Nip65({mockRelay3.url: ReadWriteMarker.write}),
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
        print(
            "RESULT OF nip65 request for ${event.pubKey}: ${nip65.relays.keys} (source:${event.sources})");
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
