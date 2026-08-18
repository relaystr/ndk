import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() {
  for (final engine in NdkEngine.values) {
    relayOutcomesTests(engine);
  }
  collapseTests();
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
        url: RelayRequestOutcome(RelayRequestOutcomeType.disconnected),
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
        url: RelayRequestOutcome(RelayRequestOutcomeType.eose),
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
        url: RelayRequestOutcome(RelayRequestOutcomeType.pending),
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
        relay1.url: RelayRequestOutcome(RelayRequestOutcomeType.eose),
      });
      expect(await response.relayOutcomesDone, response.relayOutcomes);
    });

    test('a request merged into an identical one reports its outcomes', () async {
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
        relay1.url: RelayRequestOutcome(RelayRequestOutcomeType.eose),
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
          RelayRequestOutcomeType.closed,
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
        relay1.url: RelayRequestOutcome(RelayRequestOutcomeType.timedOut),
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
        relay1.url: RelayRequestOutcome(RelayRequestOutcomeType.pending),
      });

      await ndk.requests.closeSubscription(response.requestId);

      expect(await response.relayOutcomesDone, {
        relay1.url: RelayRequestOutcome(RelayRequestOutcomeType.pending),
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
        expect(outcome?.type, RelayRequestOutcomeType.closed);
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
        relay1.url: RelayRequestOutcome(RelayRequestOutcomeType.eose),
      });
    });
  });
}
