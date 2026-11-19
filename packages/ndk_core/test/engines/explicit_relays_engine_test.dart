import 'dart:async';
import 'dart:convert';

import 'package:ndk_core/ndk_core.dart';
import 'package:test/test.dart';

class _Relay implements NostrTransport {
  final List<Nip01Event> stored;
  final List<List<dynamic>> received = [];
  final _incoming = StreamController<dynamic>.broadcast();
  bool _open = true;

  _Relay(this.stored);

  List<String> get receivedTypes =>
      received.map((m) => m[0] as String).toList();

  @override
  Future<void> ready = Future.value();

  @override
  bool isOpen() => _open;

  @override
  bool isConnecting() => false;

  @override
  Future<void> close() async {
    _open = false;
    await _incoming.close();
  }

  @override
  StreamSubscription listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) => _incoming.stream.listen(onData, onError: onError, onDone: onDone);

  @override
  void send(dynamic data) {
    final msg = jsonDecode(data as String) as List<dynamic>;
    received.add(msg);
    switch (msg[0]) {
      case 'REQ':
        for (final event in stored) {
          _incoming.add(
            jsonEncode([
              'EVENT',
              msg[1],
              Nip01EventModel.fromEntity(event).toJson(),
            ]),
          );
        }
        _incoming.add(jsonEncode(['EOSE', msg[1]]));
      case 'EVENT':
        _incoming.add(jsonEncode(['OK', msg[1]['id'], true, '']));
    }
  }

  @override
  int? closeCode() => null;

  @override
  String? closeReason() => null;
}

class _Relays implements NostrTransportFactory {
  final Map<String, List<Nip01Event>> stored;
  final Map<String, _Relay> opened = {};

  _Relays([this.stored = const {}]);

  @override
  NostrTransport call(
    String url, {
    Function? onReconnect,
    Function(int?, Object?, String?)? onDisconnect,
  }) => opened[url] = _Relay(stored[url] ?? const []);
}

const _bootstrap = 'wss://bootstrap.test';
const _a = 'wss://a.test';
const _b = 'wss://b.test';

void main() {
  final keyPair = Bip340.generatePrivateKey();
  final signer = Bip340EventSigner(
    privateKey: keyPair.privateKey,
    publicKey: keyPair.publicKey,
  );

  Nip01Event note(String content) => Nip01Event(
    pubKey: keyPair.publicKey,
    kind: 1,
    tags: const [],
    content: content,
  );

  late _Relays relays;
  late RelayManager relayManager;
  late ExplicitRelaysEngine engine;

  void start([Map<String, List<Nip01Event>> stored = const {}]) {
    relays = _Relays(stored);
    relayManager = RelayManager(
      globalState: GlobalState(),
      nostrTransportFactory: relays,
      bootstrapRelays: [_bootstrap],
    );
    engine = ExplicitRelaysEngine(
      relayManager: relayManager,
      bootstrapRelays: [_bootstrap],
    );
  }

  tearDown(() => relayManager.closeAllTransports());

  RequestState query({Iterable<String>? explicitRelays}) => RequestState(
    NdkRequest.query(
      'q',
      timeoutDuration: const Duration(seconds: 5),
      filters: [
        Filter(kinds: [1]),
      ],
      explicitRelays: explicitRelays,
    ),
  );

  BroadcastState broadcastOf(Nip01Event event) {
    final state = BroadcastState(timeout: const Duration(seconds: 5));
    relayManager.globalState.inFlightBroadcasts[event.id] = [state];
    return state;
  }

  test('a query goes to the relays it names, not to bootstrap', () async {
    start({
      _a: [note('from a')],
      _b: [note('from b')],
      _bootstrap: [note('from bootstrap')],
    });
    final state = query(explicitRelays: [_a, _b]);

    await engine.handleRequest(state);
    final events = await state.networkController.stream.toList();

    expect(events.map((e) => e.content), unorderedEquals(['from a', 'from b']));
    expect(relays.opened[_bootstrap]!.receivedTypes, isNot(contains('REQ')));
  });

  test('a query that names no relay goes to bootstrap', () async {
    start({
      _bootstrap: [note('from bootstrap')],
    });
    final state = query();

    await engine.handleRequest(state);
    final events = await state.networkController.stream.toList();

    expect(events.map((e) => e.content), ['from bootstrap']);
  });

  test('a broadcast goes to the relays it names, signed', () async {
    start();
    final event = note('hello');
    final state = broadcastOf(event);

    final responses = await engine
        .handleEventBroadcast(
          nostrEvent: event,
          signer: signer,
          broadcastState: state,
          specificRelays: [_a, _b],
        )
        .broadcastDoneFuture;

    expect(responses.map((r) => r.relayUrl), unorderedEquals([_a, _b]));
    expect(responses.every((r) => r.broadcastSuccessful), isTrue);
    final sent = relays.opened[_a]!.received.single[1] as Map;
    expect(sent['sig'], isNotNull);
    expect(relays.opened[_bootstrap]!.receivedTypes, isNot(contains('EVENT')));
  });

  test('a broadcast that names no relay goes to bootstrap', () async {
    start();
    final event = note('hello');
    final state = broadcastOf(event);

    final responses = await engine
        .handleEventBroadcast(
          nostrEvent: event,
          signer: signer,
          broadcastState: state,
        )
        .broadcastDoneFuture;

    expect(responses.map((r) => r.relayUrl), [_bootstrap]);
    expect(responses.single.broadcastSuccessful, isTrue);
  });

  test('a broadcast to no relay at all completes', () async {
    start();
    final event = note('hello');
    final state = broadcastOf(event);

    final responses = await engine
        .handleEventBroadcast(
          nostrEvent: event,
          signer: signer,
          broadcastState: state,
          specificRelays: const [],
        )
        .broadcastDoneFuture;

    expect(responses, isEmpty);
  });
}
