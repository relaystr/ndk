import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport_factory.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import 'package:ndk/domain_layer/entities/jit_engine_relay_connectivity_data.dart';
import 'package:ndk/domain_layer/repositories/nostr_transport.dart';
import 'package:ndk/domain_layer/usecases/jit_engine/relay_jit_request_strategies/relay_jit_specific_strategy.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/client_msg.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() {
  for (final engine in NdkEngine.values) {
    relayOutcomesTests(engine);
  }
  collapseTests();
  deadConnectionTests();
  notSentEndTests();
  fallbackTests();
}

/// What a response carries when it was built without a request behind it.
void fallbackTests() {
  group('relay outcomes fallback', () {
    test('a response built without outcomes reports empty ones', () async {
      final response = NdkResponse(
        "no-outcomes",
        const Stream<Nip01Event>.empty(),
      );

      expect(response.relayOutcomes, isEmpty);
      expect(await response.relayOutcomesDone, isEmpty);
      // the initial snapshot the stream promises, and then its end
      expect(await response.relayOutcomesStream.toList(), [
        <String, RelayRequestOutcome>{},
      ]);
    });
  });
}

/// Polls [condition] so a test does not depend on connect or reconnect timings.
Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String reason = 'condition never became true',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  fail(reason);
}

/// A socket that dies for good, which only the plain transport can be made to
/// do: the reconnecting one keeps its message stream open across a drop.
void deadConnectionTests() {
  group('relay outcomes on a dead connection', () {
    test('a request nothing will send again reports disconnected', () async {
      final relay = MockRelay(
        name: "relay 1",
        signEvents: false,
        silenceRequests: true,
      );
      await relay.startServer();

      final manager = RelayManager(
        globalState: ndk_entities.GlobalState(),
        bootstrapRelays: [relay.url],
        nostrTransportFactory: WebSocketNostrTransportFactory(),
      );
      await manager.connectRelay(
        dirtyUrl: relay.url,
        connectionSource: ndk_entities.ConnectionSource.seed,
      );

      final filter = Filter(kinds: [Nip01Event.kTextNodeKind]);
      final state = ndk_entities.RequestState(
        NdkRequest.query(
          "dead-connection-test",
          filters: [filter],
          // long enough that the timeout cannot be what ends the request
          timeoutDuration: Duration(seconds: 60),
        ),
      );
      final key = RelayConnectionKey.anonymous(relay.url);
      state.addRequest(key, [filter]);
      manager.globalState.inFlightRequests[state.id] = state;
      await manager.sendOrThrow(
        manager.globalState.relays[key]!,
        ClientMsg(ClientMsgType.kReq, id: state.id, filters: [filter]),
      );
      await _waitUntil(
        () => relay.connectedClientCount == 1,
        reason: 'the request never reached the relay',
      );

      // nothing will bring the socket back, so nothing owes the request a reply
      manager.allowReconnectRelays = false;
      await relay.closeClientSockets();

      await _waitUntil(
        () =>
            state.relayOutcomes[relay.url]?.status ==
            RelayRequestStatus.disconnected,
        reason: 'the request stayed on a socket nobody will reopen',
      );
      expect(state.networkController.isClosed, true);

      await relay.stopServer();
    });
  });
}

/// Sends the first connection to each of [failing] to [deadUrl], so that relay
/// is unreachable once and reachable after.
class _FailFirstConnectFactory implements NostrTransportFactory {
  _FailFirstConnectFactory(this.failing, this.deadUrl);

  final Set<String> failing;
  final String deadUrl;
  final _inner = WebSocketClientNostrTransportFactory();

  @override
  NostrTransport call(
    String url, {
    Function? onReconnect,
    Function(int?, Object?, String?)? onDisconnect,
  }) => _inner(
    failing.remove(url) ? deadUrl : url,
    onReconnect: onReconnect,
    onDisconnect: onDisconnect,
  );
}

/// A relay a request could not be sent to must neither hold the request open
/// nor end it while another relay still owes an answer.
void notSentEndTests() {
  group('relay outcomes of a request not sent everywhere', () {
    final key1 = Bip340.generatePrivateKey();
    final key2 = Bip340.generatePrivateKey();

    Nip01Event textNote(KeyPair key) => Nip01Utils.signWithPrivateKey(
      event: Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key.publicKey,
        content: "some note from ${key.publicKey}",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      privateKey: key.privateKey!,
    );

    Filter notesOf(KeyPair key) =>
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key.publicKey]);

    RelayManager buildManager(
      List<String> seeds, {
      NostrTransportFactory? factory,
    }) => RelayManager<JitEngineRelayConnectivityData>(
      globalState: ndk_entities.GlobalState(),
      bootstrapRelays: seeds,
      // the transport Ndk uses: the plain one reports a socket open before its
      // handshake, so a relay nothing listens on would look reachable
      nostrTransportFactory: factory ?? WebSocketClientNostrTransportFactory(),
      engineAdditionalDataFactory: JitEngineRelayConnectivityDataFactory(),
    );

    JitEngine buildEngine(RelayManager manager, List<String> seeds) =>
        JitEngine(
          relayManagerLight: manager,
          cache: MemCacheManager(),
          ignoreRelays: [],
          globalState: manager.globalState,
          bootstrapRelays: seeds,
        );

    ndk_entities.RequestState trackQuery(
      RelayManager manager,
      String id,
      List<Filter> filters, {
      List<String>? explicitRelays,
    }) {
      final state = ndk_entities.RequestState(
        NdkRequest.query(
          id,
          filters: filters,
          explicitRelays: explicitRelays,
          cacheRead: false,
          // long enough that the timeout cannot be what ends the request
          timeoutDuration: Duration(seconds: 60),
        ),
      );
      manager.globalState.inFlightRequests[state.id] = state;
      return state;
    }

    test(
      'a notSent relay with an open socket does not hold the request once the others are gone',
      () async {
        final notSent = MockRelay(name: "not sent", signEvents: false);
        final dropped = MockRelay(
          name: "dropped",
          signEvents: false,
          silenceRequests: true,
        );
        await notSent.startServer();
        await dropped.startServer();
        // the only transport whose socket can be made to die for good
        final manager = buildManager([
          notSent.url,
          dropped.url,
        ], factory: WebSocketNostrTransportFactory());
        addTearDown(() async {
          await manager.closeAllTransports();
          await notSent.stopServer();
          await dropped.stopServer();
        });
        await manager.seedRelaysConnected;

        final filter = notesOf(key1);
        final state = trackQuery(manager, "open-socket-test", [filter]);
        final droppedKey = RelayConnectionKey.anonymous(dropped.url);
        state.addRequest(droppedKey, [filter]);
        await manager.sendOrThrow(
          manager.globalState.relays[droppedKey]!,
          ClientMsg(ClientMsgType.kReq, id: state.id, filters: [filter]),
        );
        // a relay given up on that opened its socket afterwards: nothing
        // replays the request on a first connection
        final notSentKey = RelayConnectionKey.anonymous(notSent.url);
        manager.failRelayRequest(state, notSentKey, [
          filter,
        ], "could not connect");

        manager.allowReconnectRelays = false;
        await dropped.closeClientSockets();

        await _waitUntil(
          () =>
              state.relayOutcomes[dropped.url]?.status ==
              RelayRequestStatus.disconnected,
          reason: 'the dropped relay was never given up on',
        );
        expect(manager.isConnectionOpen(notSentKey), isTrue);
        expect(
          state.networkController.isClosed,
          isTrue,
          reason: 'no relay is left to answer, only the timeout would end it',
        );
      },
    );

    test(
      'a relay an earlier filter could not reach still answers a later one',
      () async {
        final seed = MockRelay(name: "seed", signEvents: false);
        final flaky = MockRelay(name: "flaky", signEvents: false);
        final nothingListens = MockRelay(
          name: "nothing listens",
          signEvents: false,
        );
        final note = textNote(key2);
        await seed.startServer();
        await flaky.startServer(textNotes: {key2: note});
        final manager = buildManager(
          [seed.url],
          factory: _FailFirstConnectFactory({flaky.url}, nothingListens.url),
        );
        addTearDown(() async {
          await manager.closeAllTransports();
          await seed.stopServer();
          await flaky.stopServer();
          await nothingListens.stopServer();
        });

        final state = trackQuery(
          manager,
          "later-filter-test",
          [notesOf(key1), notesOf(key2)],
          explicitRelays: [flaky.url],
        );
        final events = state.networkController.stream.toList();
        buildEngine(manager, [seed.url]).handleRequest(state);

        expect((await events).map((e) => e.id), contains(note.id));
      },
    );

    test(
      'a relay a later filter reached is waited for although an earlier one could not reach it',
      () async {
        final fast = MockRelay(name: "fast", signEvents: false);
        final flaky = MockRelay(name: "flaky", signEvents: false);
        final nothingListens = MockRelay(
          name: "nothing listens",
          signEvents: false,
        );
        final fastNote = textNote(key1);
        final flakyNote = textNote(key2);
        // the fast relay answers after the later filter went out, and before
        // the flaky relay does
        await fast.startServer(
          textNotes: {key1: fastNote},
          delayResponse: Duration(seconds: 1),
        );
        await flaky.startServer(
          textNotes: {key2: flakyNote},
          delayResponse: Duration(seconds: 2),
        );
        final manager = buildManager(
          [fast.url],
          factory: _FailFirstConnectFactory({flaky.url}, nothingListens.url),
        );
        addTearDown(() async {
          await manager.closeAllTransports();
          await fast.stopServer();
          await flaky.stopServer();
          await nothingListens.stopServer();
        });

        final state = trackQuery(
          manager,
          "waited-filter-test",
          [notesOf(key1), notesOf(key2)],
          explicitRelays: [flaky.url, fast.url],
        );
        final events = state.networkController.stream.toList();
        buildEngine(manager, [fast.url]).handleRequest(state);

        expect(
          (await events).map((e) => e.id),
          containsAll([fastNote.id, flakyNote.id]),
        );
      },
    );

    test('a relay still connecting is waited for, not reported notSent', () async {
      final connected = MockRelay(name: "connected", signEvents: false);
      final connecting = MockRelay(name: "connecting", signEvents: false);
      final connectedNote = textNote(key1);
      final connectingNote = textNote(key2);
      await connected.startServer(textNotes: {key1: connectedNote});
      await connecting.startServer(
        textNotes: {key2: connectingNote},
        delayConnection: Duration(seconds: 1),
      );
      final manager = buildManager([connected.url]);
      Future<void>? opening;
      addTearDown(() async {
        // MockRelay fails a handshake it still holds once its server stops
        await opening;
        await manager.closeAllTransports();
        await connected.stopServer();
        await connecting.stopServer();
      });
      await manager.seedRelaysConnected;

      // another request is already opening it
      opening = manager.connectRelay(
        dirtyUrl: connecting.url,
        connectionSource: ndk_entities.ConnectionSource.explicit,
      );
      final state = trackQuery(
        manager,
        "connecting-test",
        [
          Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey, key2.publicKey],
          ),
        ],
        explicitRelays: [connected.url, connecting.url],
      );
      final events = state.networkController.stream.toList();
      buildEngine(manager, [connected.url]).handleRequest(state);
      final received = await events;

      expect(state.relayOutcomes, {
        connected.url: RelayRequestOutcome(RelayRequestStatus.eose),
        connecting.url: RelayRequestOutcome(RelayRequestStatus.eose),
      });
      expect(received.map((e) => e.id), contains(connectingNote.id));
    });

    test(
      'a relay that got an earlier filter is not reported notSent when a later one cannot reach it',
      () async {
        final lost = MockRelay(
          name: "lost",
          signEvents: false,
          silenceRequests: true,
        );
        final silent = MockRelay(
          name: "silent",
          signEvents: false,
          silenceRequests: true,
        );
        await lost.startServer();
        await silent.startServer();
        final manager = buildManager([lost.url, silent.url]);
        addTearDown(() async {
          await manager.closeAllTransports();
          await lost.stopServer();
          await silent.stopServer();
        });
        await manager.seedRelaysConnected;

        final first = notesOf(key1);
        final second = notesOf(key2);
        final relays = [lost.url, silent.url];
        final state = trackQuery(manager, "earlier-filter-test", [
          first,
          second,
        ], explicitRelays: relays);

        // one filter after the other, as JitEngine.handleRequest does
        await RelayJitRequestSpecificStrategy.handleRequest(
          requestState: state,
          filter: first,
          closeOnEOSE: true,
          relayManager: manager,
          specificRelays: relays,
        );
        await _waitUntil(
          () => lost.connectionsThatRequested(state.id) == 1,
          reason: 'the first filter never reached the relay',
        );

        await lost.stopServer();
        await _waitUntil(
          () => !manager.isConnectionOpen(RelayConnectionKey.anonymous(lost.url)),
          reason: 'the relay never went away',
        );

        await RelayJitRequestSpecificStrategy.handleRequest(
          requestState: state,
          filter: second,
          closeOnEOSE: true,
          relayManager: manager,
          specificRelays: relays,
        );

        expect(
          state.relayOutcomes[lost.url]?.status,
          isNot(RelayRequestStatus.notSent),
          reason: 'the relay got the first filter, it was not left unsent',
        );
      },
    );
  });
}

/// What no relay can be made to do on demand: a connection that goes away, and
/// two connections to one relay ending differently.
void collapseTests() {
  group('relay outcomes collapse', () {
    const url = "wss://relay.example.com";
    final filter = Filter(kinds: [Nip01Event.kTextNodeKind]);

    ndk_entities.RequestState buildState() => ndk_entities.RequestState(
      NdkRequest.subscription("outcome-test", filters: [filter]),
    );

    test('a connection that went away reports disconnected', () {
      final state = buildState();
      final key = RelayConnectionKey.anonymous(url);
      state.addRequest(key, [filter]);
      state.requests[key]!.connectionGone = true;

      expect(state.relayOutcomes, {
        url: RelayRequestOutcome(RelayRequestStatus.disconnected),
      });
    });

    test('an eose on one connection wins over a closed on another', () {
      final state = buildState();
      final anonymous = RelayConnectionKey.anonymous(url);
      final authenticated = RelayConnectionKey.authenticated(url, "a" * 64);
      state.addRequest(anonymous, [filter]);
      state.addRequest(authenticated, [filter]);
      state.requests[anonymous]!
        ..receivedClosed = true
        ..closedMessage = "auth-required: we only serve authenticated users";
      state.requests[authenticated]!.receivedEOSE = true;

      expect(state.relayOutcomes, {
        url: RelayRequestOutcome(RelayRequestStatus.eose),
      });
    });

    test('a request that could not be sent reports notSent and why', () {
      final state = buildState();
      final key = RelayConnectionKey.anonymous(url);
      state.addRequest(key, [filter]);
      state.requests[key]!.markNotSent("could not connect");

      expect(state.relayOutcomes, {
        url: RelayRequestOutcome(
          RelayRequestStatus.notSent,
          message: "could not connect",
        ),
      });
      expect(state.didAllRequestsFinish, isTrue);
    });

    test('a request sent after all is no longer notSent', () {
      final state = buildState();
      final key = RelayConnectionKey.anonymous(url);
      state.addRequest(key, [filter]);
      state.requests[key]!.markNotSent("could not connect");

      state.requests[key]!.markSent();

      expect(state.relayOutcomes, {
        url: RelayRequestOutcome(RelayRequestStatus.pending),
      });
    });

    test('a connection sent again after it went away is pending once more', () {
      final state = buildState();
      final key = RelayConnectionKey.anonymous(url);
      state.addRequest(key, [filter]);
      state.requests[key]!.connectionGone = true;

      // what a subscription replayed on a replacement socket goes through
      state.requests[key]!.markSent();

      expect(state.relayOutcomes, {
        url: RelayRequestOutcome(RelayRequestStatus.pending),
      });
    });

    test('the stream reports a change once and a repeat not at all', () async {
      final state = buildState();
      final key = RelayConnectionKey.anonymous(url);
      state.addRequest(key, [filter]);

      final seen = <Map<String, RelayRequestOutcome>>[];
      final subscription = state.relayOutcomesStream.listen(seen.add);
      await Future.delayed(Duration.zero);

      state.requests[key]!.receivedEOSE = true;
      state.requests[key]!.receivedEOSE = true;
      await Future.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen, [
        {url: RelayRequestOutcome(RelayRequestStatus.pending)},
        {url: RelayRequestOutcome(RelayRequestStatus.eose)},
      ]);
    });

    test('a late listener gets the outcomes it was not there for', () async {
      final state = buildState();
      final key = RelayConnectionKey.anonymous(url);
      state.addRequest(key, [filter]);
      state.requests[key]!.receivedEOSE = true;

      expect(await state.relayOutcomesStream.first, {
        url: RelayRequestOutcome(RelayRequestStatus.eose),
      });
    });

    test('a connection retrying its authentication stays pending', () {
      final state = buildState();
      final key = RelayConnectionKey.anonymous(url);
      state.addRequest(key, [filter]);
      state.requests[key]!
        ..receivedClosed = true
        ..retryingAuth = true;

      expect(state.relayOutcomes, {
        url: RelayRequestOutcome(RelayRequestStatus.pending),
      });
    });
  });
}

/// Both engines track their requests in the same [RequestState], so both must
/// report the same outcomes.
void relayOutcomesTests(NdkEngine engine) {
  group('relay outcomes [${engine.name}]', () {
    final key1 = Bip340.generatePrivateKey();
    late MockRelay relay1;
    late Ndk ndk;

    Nip01Event textNote(KeyPair key) => Nip01Utils.signWithPrivateKey(
      event: Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key.publicKey,
        content: "some note from key1",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      privateKey: key.privateKey!,
    );

    Ndk buildNdk({AuthHandler? authHandler}) => Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: engine,
        bootstrapRelays: [relay1.url],
        authHandler: authHandler,
      ),
    );

    NdkResponse queryKey1({Duration? timeout}) => ndk.requests.query(
      filter: Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
      ),
      cacheRead: false,
      timeout: timeout,
    );

    tearDown(() async {
      await ndk.destroy();
      await relay1.stopServer();
    });

    test('a relay that sends its EOSE reports eose', () async {
      relay1 = MockRelay(name: "relay 1", signEvents: false);
      await relay1.startServer(textNotes: {key1: textNote(key1)});
      ndk = buildNdk();

      final response = queryKey1();
      final events = await response.future;

      expect(events, hasLength(1));
      expect(response.relayOutcomes, {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
      });
      expect(await response.relayOutcomesDone, response.relayOutcomes);
    });

    test(
      'a request merged into an identical one reports its outcomes',
      () async {
        relay1 = MockRelay(name: "relay 1", signEvents: false);
        await relay1.startServer(textNotes: {key1: textNote(key1)});
        ndk = buildNdk();

        final filter = Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        );
        final first = ndk.requests.query(filter: filter);
        final duplicate = ndk.requests.query(filter: filter);

        await first.future;
        await duplicate.future;

        expect(duplicate.relayOutcomes, {
          relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
        });
      },
    );

    test('the stream ends on the request, on its final outcomes', () async {
      relay1 = MockRelay(name: "relay 1", signEvents: false);
      await relay1.startServer(textNotes: {key1: textNote(key1)});
      ndk = buildNdk();

      final response = queryKey1();
      final streamed = response.relayOutcomesStream.toList();
      await response.future;

      final outcomes = await streamed;
      expect(outcomes.last, {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
      });
      expect(outcomes.last, await response.relayOutcomesDone);
    });

    test('the stream still ends when it is asked for too late', () async {
      relay1 = MockRelay(name: "relay 1", signEvents: false);
      await relay1.startServer(textNotes: {key1: textNote(key1)});
      ndk = buildNdk();

      final response = queryKey1();
      await response.future;

      // nothing is left to close a subject created this late, and it stays a
      // broadcast stream, so a second listener is served just like the first
      final stream = response.relayOutcomesStream;
      final ended = {relay1.url: RelayRequestOutcome(RelayRequestStatus.eose)};
      expect((await stream.toList()).last, ended);
      expect((await stream.toList()).last, ended);
    });

    test(
      'a merged request streams the outcomes of the one serving it',
      () async {
        relay1 = MockRelay(name: "relay 1", signEvents: false);
        await relay1.startServer(textNotes: {key1: textNote(key1)});
        ndk = buildNdk();

        final filter = Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        );
        final first = ndk.requests.query(filter: filter);
        final duplicate = ndk.requests.query(filter: filter);
        final streamed = duplicate.relayOutcomesStream.toList();

        await first.future;
        await duplicate.future;

        expect((await streamed).last, {
          relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
        });
      },
    );

    test('a relay that closes the request reports closed and why', () async {
      relay1 = MockRelay(
        name: "relay 1",
        signEvents: false,
        closeRequestsMessage: "blocked: you are not whitelisted",
      );
      await relay1.startServer(textNotes: {key1: textNote(key1)});
      ndk = buildNdk();

      final response = queryKey1();
      await response.future;

      expect(response.relayOutcomes, {
        relay1.url: RelayRequestOutcome(
          RelayRequestStatus.closed,
          message: "blocked: you are not whitelisted",
        ),
      });
    });

    test('a relay that stays silent reports timedOut', () async {
      relay1 = MockRelay(
        name: "relay 1",
        signEvents: false,
        silenceRequests: true,
      );
      await relay1.startServer(textNotes: {key1: textNote(key1)});
      ndk = buildNdk();

      final response = queryKey1(timeout: Duration(seconds: 1));
      await response.future;

      expect(response.relayOutcomes, {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.timedOut),
      });
    });

    test(
      'a relay no connection reaches reports notSent, and the others end the request',
      () async {
        relay1 = MockRelay(name: "relay 1", signEvents: false);
        await relay1.startServer(textNotes: {key1: textNote(key1)});
        // never started, so nothing listens on its port
        final unreachable = MockRelay(name: "unreachable", signEvents: false);
        ndk = buildNdk();

        var timedOut = false;
        final response = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey],
          ),
          explicitRelays: [relay1.url, unreachable.url],
          cacheRead: false,
          timeout: Duration(seconds: 30),
          timeoutCallback: () => timedOut = true,
        );
        final events = await response.future;

        expect(events, hasLength(1));
        expect(timedOut, isFalse);
        expect(await response.relayOutcomesDone, {
          relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
          unreachable.url: RelayRequestOutcome(
            RelayRequestStatus.notSent,
            message: "could not connect",
          ),
        });

        await unreachable.stopServer();
      },
    );

    test(
      'a request none of its relays can be sent to ends without its timeout',
      () async {
        relay1 = MockRelay(name: "relay 1", signEvents: false);
        await relay1.startServer(textNotes: {key1: textNote(key1)});
        final unreachable = MockRelay(name: "unreachable", signEvents: false);
        ndk = buildNdk();

        var timedOut = false;
        final response = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey],
          ),
          explicitRelays: [unreachable.url],
          cacheRead: false,
          timeout: Duration(seconds: 30),
          timeoutCallback: () => timedOut = true,
        );

        expect(await response.future, isEmpty);
        expect(timedOut, isFalse);
        expect(await response.relayOutcomesDone, {
          unreachable.url: RelayRequestOutcome(
            RelayRequestStatus.notSent,
            message: "could not connect",
          ),
        });

        await unreachable.stopServer();
      },
    );

    test(
      'a paginated query streams a relay while its page is running',
      () async {
        relay1 = MockRelay(name: "relay 1", signEvents: false);
        await relay1.startServer(
          textNotes: {key1: textNote(key1)},
          delayResponse: Duration(seconds: 1),
        );
        ndk = buildNdk();

        final response = ndk.requests.query(
          filter: Filter(
            kinds: [Nip01Event.kTextNodeKind],
            authors: [key1.publicKey],
          ),
          cacheRead: false,
          paginate: true,
        );
        final streamed = response.relayOutcomesStream.toList();
        await response.future;

        final outcomes = await streamed;
        expect(
          outcomes,
          anyElement(
            equals({
              relay1.url: RelayRequestOutcome(RelayRequestStatus.pending),
            }),
          ),
          reason: 'a page still running must show its relay as pending',
        );
        expect(outcomes.last, {
          relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
        });
      },
    );

    test('a subscription still waiting on a relay reports pending', () async {
      relay1 = MockRelay(
        name: "relay 1",
        signEvents: false,
        silenceRequests: true,
      );
      await relay1.startServer(textNotes: {key1: textNote(key1)});
      ndk = buildNdk();

      final response = ndk.requests.subscription(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
        cacheRead: false,
      );
      await Future.delayed(Duration(seconds: 1));

      expect(response.relayOutcomes, {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.pending),
      });

      await ndk.requests.closeSubscription(response.requestId);

      expect(await response.relayOutcomesDone, {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.pending),
      });
    });

    test('a subscription streams its relays until it is closed', () async {
      relay1 = MockRelay(
        name: "relay 1",
        signEvents: false,
        silenceRequests: true,
      );
      await relay1.startServer(textNotes: {key1: textNote(key1)});
      ndk = buildNdk();

      final response = ndk.requests.subscription(
        filter: Filter(
          kinds: [Nip01Event.kTextNodeKind],
          authors: [key1.publicKey],
        ),
        cacheRead: false,
      );
      final streamed = response.relayOutcomesStream.toList();
      await Future.delayed(Duration(seconds: 1));

      await ndk.requests.closeSubscription(response.requestId);

      expect((await streamed).last, {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.pending),
      });
    });

    test(
      'a relay asking for auth we cannot answer reports its refusal',
      () async {
        relay1 = MockRelay(
          name: "relay 1",
          signEvents: false,
          requireAuthForRequests: true,
        );
        await relay1.startServer(textNotes: {key1: textNote(key1)});
        ndk = buildNdk();

        final response = queryKey1(timeout: Duration(seconds: 5));
        await response.future;

        final outcome = response.relayOutcomes[relay1.url];
        expect(outcome?.status, RelayRequestStatus.closed);
        expect(outcome?.message, startsWith("auth-required"));
      },
    );

    test('the connections to one relay collapse into one outcome', () async {
      relay1 = MockRelay(
        name: "relay 1",
        signEvents: false,
        requireAuthForRequests: true,
      );
      await relay1.startServer(textNotes: {key1: textNote(key1)});
      ndk = buildNdk(authHandler: (_, _) async => true);

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      final response = queryKey1(timeout: Duration(seconds: 5));
      final events = await response.future;

      // the anonymous attempt was closed with auth-required and handed over to
      // an authenticated connection, which is the one that answered
      expect(events, hasLength(1));
      expect(response.relayOutcomes, {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
      });
    });
  });
}
