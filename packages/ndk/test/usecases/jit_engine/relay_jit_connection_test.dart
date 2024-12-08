import 'dart:developer';

import 'package:ndk/domain_layer/entities/connection_source.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/presentation_layer/init.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/usecases/relay_jit_manager/relay_jit.dart';
import 'package:test/test.dart';
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

  MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 5001);
  MockRelay relay2 = MockRelay(name: "relay 2", explicitPort: 5002);

  MockRelay relay21 = MockRelay(name: "relay 21", explicitPort: 5021);
  MockRelay relay22 = MockRelay(name: "relay 22", explicitPort: 5022);
  MockRelay relay23 = MockRelay(name: "relay 23", explicitPort: 5023);
  MockRelay relay24 = MockRelay(name: "relay 24", explicitPort: 5024);

  group('connection tests', () {
    onMessage(Nip01Event event, RequestState requestState) async {
      log("onMessage(${event.content}, ${requestState.id})");
    }

    test('Connect to relay', () async {
      await relay1.startServer();

      RelayJit relayJit = RelayJit(url: relay1.url, onMessage: onMessage);
      var result =
          await relayJit.connect(connectionSource: ConnectionSource.UNKNOWN);

      expect(result, true);

      //await Future.delayed(Duration(seconds: 5));
      await relay1.stopServer();
    });

    test('Try to connect to dead relay', () async {
      RelayJit relayJit = RelayJit(url: relay2.url, onMessage: onMessage);
      var result =
          await relayJit.connect(connectionSource: ConnectionSource.UNKNOWN);

      expect(result, false);
    });
  });

  group("Calculate best relays (internal MOCKs)", () {
    Map<String, String> relayNames = {
      relay21.url: relay21.name,
      relay22.url: relay22.name,
      relay23.url: relay23.name,
      relay24.url: relay24.name,
    };
    Nip65 nip65ForKey1 = Nip65.fromMap(key1.publicKey, {
      relay21.url: ReadWriteMarker.readWrite,
      relay22.url: ReadWriteMarker.readWrite,
      relay23.url: ReadWriteMarker.readWrite,
      relay24.url: ReadWriteMarker.readWrite,
    });
    Nip65 nip65ForKey2 = Nip65.fromMap(key2.publicKey, {
      relay21.url: ReadWriteMarker.readWrite,
      relay22.url: ReadWriteMarker.readWrite,
    });
    Nip65 nip65ForKey3 =
        Nip65.fromMap(key3.publicKey, {relay21.url: ReadWriteMarker.readWrite});
    Nip65 nip65ForKey4 =
        Nip65.fromMap(key4.publicKey, {relay24.url: ReadWriteMarker.readWrite});

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
        relay21.startServer(
            nip65s: nip65s,
            textNotes: {}
              ..addAll(key1TextNotes)
              ..addAll(key2TextNotes)
              ..addAll(key3TextNotes)),
        relay22.startServer(
            nip65s: nip65s,
            textNotes: {}
              ..addAll(key1TextNotes)
              ..addAll(key2TextNotes)),
        relay23.startServer(
            nip65s: nip65s, textNotes: {}..addAll(key1TextNotes)),
        relay24.startServer(textNotes: key4TextNotes..addAll(key1TextNotes))
      ]);
    }

    stopServers() async {
      await Future.wait([
        relay21.stopServer(),
        relay22.stopServer(),
        relay23.stopServer(),
        relay24.stopServer(),
      ]);
    }

    test('query events from one seed relay', () async {
      await startServers();

      CacheManager cacheManager = MemCacheManager();

      EventVerifier eventVerifier = MockEventVerifier();
      GlobalState globalState = GlobalState();

      JitEngine manager = JitEngine(
        cache: cacheManager,
        ignoreRelays: [],
        seedRelays: [relay21.url, relay22.url, relay23.url, relay24.url],
        globalState: globalState,
      );

      RequestState myRequest =
          RequestState(NdkRequest.query("debug-get-events", filters: [
        Filter(kinds: [Nip01Event.TEXT_NODE_KIND], authors: [key4.publicKey]),
      ]));

      //todo: implement EOSE
      myRequest.stream.listen((event) {
        expectAsync1((event) {
          expect(event, key4TextNotes[key4]);
        })(event);
      });

      manager.handleRequest(myRequest);

      await Future.delayed(const Duration(seconds: 1));

      await stopServers();
    });

    test('query with inbox/outbox',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      await startServers();

      CacheManager cacheManager = MemCacheManager();

      // todo: discuss how saveEvents schuld work (saving additional nip65 data?)
      // save nip65 data
      await cacheManager
          .saveEvents(nip65s.values.map((e) => e.toEvent()).toList());

      await cacheManager.saveUserRelayLists(
        nip65s.values.map((e) => UserRelayList.fromNip65(e)).toList(),
      );

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cacheManager,
        engine: NdkEngine.JIT,
        bootstrapRelays: [], // dont connect to anything
      ));

      final response = ndk.requests.query(
        name: "qInOut",
        filters: [
          Filter(kinds: [
            Nip01Event.TEXT_NODE_KIND
          ], authors: [
            key1.publicKey,
            key2.publicKey,
            key3.publicKey,
            key4.publicKey,
          ]),
        ],
        desiredCoverage: 1,
      );
      // List<Nip01Event> responses = [];
      // response.stream.listen((event) {
      //   responses.add(event);
      // });

      final responses = await response.stream.toList();

      expect(responses.length, 4);
      // expect that all responses are there
      expect(responses.contains(key1TextNotes[key1]), true);
      expect(responses.contains(key2TextNotes[key2]), true);
      expect(responses.contains(key3TextNotes[key3]), true);
      expect(responses.contains(key4TextNotes[key4]), true);

      await stopServers();
    });
  });
}
