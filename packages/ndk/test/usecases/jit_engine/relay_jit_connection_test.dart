import 'dart:async';

import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/domain_layer/repositories/nostr_transport.dart';
import 'package:ndk/domain_layer/usecases/jit_engine/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';

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
      kind: Nip01Event.kTextNodeKind,
      pubKey: key2.publicKey,
      content: "some note from key ${keyNames[key2]}",
      tags: [],
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};
  Map<KeyPair, Nip01Event> key2TextNotes = {key2: textNote(key2)};
  Map<KeyPair, Nip01Event> key3TextNotes = {key3: textNote(key3)};
  Map<KeyPair, Nip01Event> key4TextNotes = {key4: textNote(key4)};

  MockRelay relay21 = MockRelay(name: "relay 21", explicitPort: 5021);
  MockRelay relay22 = MockRelay(name: "relay 22", explicitPort: 5022);
  MockRelay relay23 = MockRelay(name: "relay 23", explicitPort: 5023);
  MockRelay relay24 = MockRelay(name: "relay 24", explicitPort: 5024);

  group("Calculate best relays (internal MOCKs)", () {
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
    Nip65 nip65ForKey3 = Nip65.fromMap(key3.publicKey, {
      relay21.url: ReadWriteMarker.readWrite,
    });
    Nip65 nip65ForKey4 = Nip65.fromMap(key4.publicKey, {
      relay24.url: ReadWriteMarker.readWrite,
    });

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
            ..addAll(key3TextNotes),
        ),
        relay22.startServer(
          nip65s: nip65s,
          textNotes: {}
            ..addAll(key1TextNotes)
            ..addAll(key2TextNotes),
        ),
        relay23.startServer(
          nip65s: nip65s,
          textNotes: {}..addAll(key1TextNotes),
        ),
        relay24.startServer(textNotes: key4TextNotes..addAll(key1TextNotes)),
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

      GlobalState globalState = GlobalState();
      NostrTransportFactory nostrTransportFactory =
          WebSocketNostrTransportFactory();

      RelayManager relayManagerLight = RelayManager(
        bootstrapRelays: [relay21.url, relay22.url, relay23.url, relay24.url],
        globalState: globalState,
        nostrTransportFactory: nostrTransportFactory,
      );

      JitEngine manager = JitEngine(
        relayManagerLight: relayManagerLight,
        cache: cacheManager,
        ignoreRelays: [],
        globalState: globalState,
        bootstrapRelays: [relay21.url],
      );

      RequestState myRequest = RequestState(
        NdkRequest.query(
          "debug-get-events",
          filters: [
            Filter(
              kinds: [Nip01Event.kTextNodeKind],
              authors: [key4.publicKey],
            ),
          ],
          timeoutDuration: Duration(seconds: 5),
        ),
      );

      myRequest.stream.listen((event) {
        expectAsync1((event) {
          expect(event, key4TextNotes[key4]);
        })(event);
      });

      manager.handleRequest(myRequest);

      await Future.delayed(const Duration(seconds: 1));

      await stopServers();
    });

    test(
      'query with inbox/outbox',
      timeout: const Timeout(Duration(seconds: 5)),
      () async {
        await startServers();

        CacheManager cacheManager = MemCacheManager();

        // save nip65 data
        await cacheManager.saveEvents(
          nip65s.values.map((e) => e.toEvent()).toList(),
        );

        await cacheManager.saveUserRelayLists(
          nip65s.values.map((e) => UserRelayList.fromNip65(e)).toList(),
        );

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: MockEventVerifier(),
            cache: cacheManager,
            engine: NdkEngine.JIT,
            bootstrapRelays: [], // dont connect to anything
          ),
        );

        final response = ndk.requests.query(
          name: "qInOut",
          filters: [
            Filter(
              kinds: [Nip01Event.kTextNodeKind],
              authors: [
                key1.publicKey,
                key2.publicKey,
                key3.publicKey,
                key4.publicKey,
              ],
            ),
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
      },
    );

    test('starts relay candidate connections concurrently', () async {
      final delayedUrl = 'ws://delayed.example';
      final immediateUrl = 'ws://immediate.example';
      final delayedTransport = _ControlledTransport(open: false);
      final immediateTransport = _ControlledTransport(open: true);
      final factory = _ControlledTransportFactory({
        delayedUrl: delayedTransport,
        immediateUrl: immediateTransport,
      });
      addTearDown(() async {
        await delayedTransport.close();
        await immediateTransport.close();
      });

      final relayLists = [
        Nip65.fromMap(key1.publicKey, {
          delayedUrl: ReadWriteMarker.readWrite,
        }),
        Nip65.fromMap(key2.publicKey, {
          delayedUrl: ReadWriteMarker.readWrite,
        }),
        Nip65.fromMap(key3.publicKey, {
          immediateUrl: ReadWriteMarker.readWrite,
        }),
      ];
      final cacheManager = MemCacheManager();
      await cacheManager.saveUserRelayLists(
        relayLists.map(UserRelayList.fromNip65).toList(),
      );

      final globalState = GlobalState();
      final relayManager = RelayManager(
        bootstrapRelays: const [],
        globalState: globalState,
        nostrTransportFactory: factory,
      );
      final requestState = RequestState(
        NdkRequest.query(
          'concurrent-candidates',
          timeoutDuration: const Duration(seconds: 2),
          filters: [
            Filter(authors: [
              key1.publicKey,
              key2.publicKey,
              key3.publicKey,
            ]),
          ],
        ),
      );

      final handling = RelayJitPubkeyStrategy.handleRequest(
        requestState: requestState,
        globalState: globalState,
        filter: requestState.unresolvedFilters.single,
        connectedRelays: const [],
        bootstrapRelays: const [],
        cacheManager: cacheManager,
        desiredCoverage: 1,
        closeOnEOSE: true,
        direction: ReadWriteMarker.writeOnly,
        ignoreRelays: const [],
        relayManager: relayManager,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(factory.startedUrls, containsAll([delayedUrl, immediateUrl]));

      delayedTransport.open();
      await handling;
    });
  });
}

class _ControlledTransportFactory implements NostrTransportFactory {
  final Map<String, _ControlledTransport> transports;
  final List<String> startedUrls = [];

  _ControlledTransportFactory(this.transports);

  @override
  NostrTransport call(
    String url, {
    Function? onReconnect,
    Function(int?, Object?, String?)? onDisconnect,
  }) {
    startedUrls.add(url);
    return transports[url]!;
  }
}

class _ControlledTransport implements NostrTransport {
  final StreamController<dynamic> _messages = StreamController.broadcast();
  final Completer<void> _ready = Completer<void>();
  bool _open;

  _ControlledTransport({required bool open}) : _open = open {
    ready = _ready.future;
    if (open) {
      _ready.complete();
    }
  }

  void open() {
    _open = true;
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }

  @override
  late Future<void> ready;

  @override
  Future<void> close() async {
    _open = false;
    if (!_ready.isCompleted) {
      _ready.complete();
    }
    if (!_messages.isClosed) {
      await _messages.close();
    }
  }

  @override
  int? closeCode() => null;

  @override
  String? closeReason() => null;

  @override
  bool isConnecting() => !_open;

  @override
  bool isOpen() => _open;

  @override
  StreamSubscription listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) =>
      _messages.stream.listen(onData, onError: onError, onDone: onDone);

  @override
  void send(dynamic data) {}
}
