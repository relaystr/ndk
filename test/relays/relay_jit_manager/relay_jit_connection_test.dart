import 'dart:developer';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/mem_cache_manager.dart';
import 'package:dart_ndk/nips/nip01/bip340.dart';
import 'package:dart_ndk/nips/nip01/bip340_event_verifier.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/event_verifier.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_manager.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  KeyPair key1 = Bip340.generatePrivateKey();
  KeyPair key2 = Bip340.generatePrivateKey();
  KeyPair key3 = Bip340.generatePrivateKey();
  KeyPair key4 = Bip340.generatePrivateKey();

  Map<KeyPair, String> keyNames = {
    key1: "key1",
    key2: "key2",
    key3: "key3",
    key4: "key4",
  };

  Nip01Event textNote(KeyPair key2) {
    return Nip01Event(
        kind: Nip01Event.TEXT_NODE_KIND,
        pubKey: key2.publicKey,
        content: "some note from key ${keyNames[key2]}",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};
  Map<KeyPair, Nip01Event> key2TextNotes = {key2: textNote(key2)};
  Map<KeyPair, Nip01Event> key3TextNotes = {key3: textNote(key3)};
  Map<KeyPair, Nip01Event> key4TextNotes = {key4: textNote(key4)};

  group('connection tests', () {
    MockRelay relay1 = MockRelay(name: "relay 1");
    MockRelay relay2 = MockRelay(name: "relay 2");
    test('Connect to relay', () async {
      await relay1.startServer();

      RelayJit relayJit = RelayJit(relay1.url);
      var result =
          await relayJit.connect(connectionSource: ConnectionSource.UNKNOWN);

      expect(result, true);

      //await Future.delayed(Duration(seconds: 5));
      await relay1.stopServer();
    });

    test('Try to connect to dead relay', () async {
      RelayJit relayJit = RelayJit(relay2.url);
      var result =
          await relayJit.connect(connectionSource: ConnectionSource.UNKNOWN);

      expect(result, false);
    });
  });

  group("Calculate best relays (internal MOCKs)", () {
    MockRelay relay1 = MockRelay(name: "relay 1");
    MockRelay relay2 = MockRelay(name: "relay 2");
    MockRelay relay3 = MockRelay(name: "relay 3");
    MockRelay relay4 = MockRelay(name: "relay 4");

    Map<String, String> relayNames = {
      relay1.url: relay1.name,
      relay2.url: relay2.name,
      relay3.url: relay3.name,
      relay4.url: relay4.name,
    };
    Nip65 nip65ForKey1 = Nip65.fromMap(key1.publicKey, {
      relay1.url: ReadWriteMarker.readWrite,
      relay2.url: ReadWriteMarker.readWrite,
      relay3.url: ReadWriteMarker.readWrite,
      relay4.url: ReadWriteMarker.readWrite,
    });
    Nip65 nip65ForKey2 = Nip65.fromMap(key2.publicKey, {
      relay1.url: ReadWriteMarker.readWrite,
      relay2.url: ReadWriteMarker.readWrite,
    });
    Nip65 nip65ForKey3 =
        Nip65.fromMap(key3.publicKey, {relay1.url: ReadWriteMarker.readWrite});
    Nip65 nip65ForKey4 =
        Nip65.fromMap(key4.publicKey, {relay4.url: ReadWriteMarker.readWrite});

    Map<KeyPair, Nip65> nip65s = {
      key1: nip65ForKey1,
      key2: nip65ForKey2,
      key3: nip65ForKey3,
      key4: nip65ForKey4,
    };

    startServers() async {
      // r1 -> k1, k2, k3
      // r2 -> k1, k2
      // r3 -> k1
      // r4 -> k1,k4
      await Future.wait([
        relay1.startServer(
            nip65s: nip65s,
            textNotes: {}
              ..addAll(key1TextNotes)
              ..addAll(key2TextNotes)
              ..addAll(key3TextNotes)),
        relay2.startServer(
            nip65s: nip65s,
            textNotes: {}
              ..addAll(key1TextNotes)
              ..addAll(key2TextNotes)),
        relay3.startServer(
            nip65s: nip65s, textNotes: {}..addAll(key1TextNotes)),
        relay4.startServer(textNotes: key4TextNotes..addAll(key1TextNotes))
      ]);
    }

    stopServers() async {
      await Future.wait([
        relay1.stopServer(),
        relay2.stopServer(),
        relay3.stopServer(),
        relay4.stopServer(),
      ]);
    }

    test('query events from key that writes only on one relay', () async {
      await startServers();

      CacheManager cacheManager = MemCacheManager();
      //todo: relay manager seed relays rdy check
      RelayJitManager manager = RelayJitManager(
        seedRelays: [relay1.url, relay2.url, relay3.url, relay4.url],
        cacheManager: cacheManager,
      );

      EventVerifier eventVerifier = MockEventVerifier();
      NostrRequestJit request = NostrRequestJit.query("debug-get-events",
          eventVerifier: eventVerifier,
          filters: [
            Filter(
                kinds: [Nip01Event.TEXT_NODE_KIND], authors: [key4.publicKey]),
          ]);
      manager.handleRequest(request);

      request.responseStream.listen((event) {
        log(event.toString());
      });

      //await for (final event in query.take(4)) {
      //  expect(event.sources, [relay4.url]);
      //  expect(event, key4TextNotes[key4]);
      //  // print(event);
      //}

      await Future.delayed(const Duration(seconds: 5));

      await stopServers();
    });
  });
}
