import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
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
      expect(
        await response.relayOutcomesStream.toList(),
        [<String, RelayRequestOutcome>{}],
      );
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

    Ndk buildNdk() => Ndk(
          NdkConfig(
            eventVerifier: MockEventVerifier(),
            cache: MemCacheManager(),
            engine: engine,
            bootstrapRelays: [relay1.url],
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

    test('a request merged into an identical one reports its outcomes',
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
    });

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
      final ended = {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
      };
      expect((await stream.toList()).last, ended);
      expect((await stream.toList()).last, ended);
    });

    test('a merged request streams the outcomes of the one serving it',
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
    });

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

    test('a paginated query streams a relay while its page is running',
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
        anyElement(equals({
          relay1.url: RelayRequestOutcome(RelayRequestStatus.pending),
        })),
        reason: 'a page still running must show its relay as pending',
      );
      expect(outcomes.last, {
        relay1.url: RelayRequestOutcome(RelayRequestStatus.eose),
      });
    });

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
      ndk = buildNdk();

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
