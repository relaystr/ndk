import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/filter.dart';
import 'package:dart_ndk/nips/Nip65.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_relay.dart';

void main() {
  test('Connect to relay', () async {
    MockRelay mockRelay = MockRelay();
    await mockRelay.startServer();
    RelayManager relays = RelayManager();
    await relays
        .connectRelay(mockRelay.url)
        .then((value) {})
        .onError((error, stackTrace) async {
      await mockRelay.stopServer();
    });
    await mockRelay.stopServer();
  });

  test('Try to connect to dead relay', () {
    MockRelay mockRelay1 = MockRelay();
    RelayManager relays = RelayManager();
    expect(
      () async => await relays.connectRelay(mockRelay1.url),
      throwsA(
        (e) => e is Exception,
      ),
    );
  });

  test('Get feeds relays for some pubKeys', () async {
    MockRelay mockRelay1 = MockRelay();
    MockRelay mockRelay2 = MockRelay();
    MockRelay mockRelay3 = MockRelay();

    String PUB1 = "pub1";
    String PUB2 = "pub2";
    String PUB3 = "pub3";

    Map<String, Set<String>> NIP65s = {
      PUB1: {mockRelay1.url, mockRelay2.url, mockRelay3.url},
      PUB2: {mockRelay2.url},
      PUB3: {mockRelay3.url},
    };

    await Future.wait([
      mockRelay1.startServer(nip65s: NIP65s),
      mockRelay2.startServer(nip65s: NIP65s),
      mockRelay3.startServer(nip65s: NIP65s)
    ]);

    RelayManager relays = RelayManager();

    await Future.wait([
      relays.connectRelay(mockRelay1.url),
      relays.connectRelay(mockRelay2.url),
      relays.connectRelay(mockRelay3.url)
    ]);

    String id = Random().nextInt(4294967296).toString();
    await relays
        .request(
            mockRelay1.url, id, Filter(kinds: [Nip65.kind], authors: [PUB1]))
        .then((value) {
      print("RESULT OF nip65 request: $value");
    });

    await Future.wait([
      mockRelay1.stopServer(),
      mockRelay2.stopServer(),
      mockRelay3.stopServer()
    ]);
  });
}
