import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

/// The combined engine serves a request that named a relay set with the relay
/// sets engine, and everything else with the JIT engine, over one pool.
void main() {
  late KeyPair author;
  late Nip01Event note;
  late MockRelay setRelay;
  late MockRelay otherRelay;
  late MemCacheManager cache;

  Ndk combinedNdk() => Ndk(
    NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: cache,
      engine: NdkEngine.COMBINED,
      // no bootstrap relays: every connection here is one a request asked for,
      // which is what makes the pool contents assertable
      bootstrapRelays: [],
    ),
  );

  RelaySet setNaming(Iterable<String> urls) => RelaySet(
    name: 'set',
    pubKey: author.publicKey,
    relaysMap: {for (final url in urls) url: []},
    direction: RelayDirection.outbox,
    fallbackToBootstrapRelays: false,
  );

  Filter notesOf(KeyPair key) =>
      Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key.publicKey]);

  void registerFixtures() {
    setUp(() async {
      author = Bip340.generatePrivateKey();
      note = Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          kind: Nip01Event.kTextNodeKind,
          pubKey: author.publicKey,
          content: 'a note',
          tags: [],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        privateKey: author.privateKey!,
      );

      setRelay = MockRelay(name: 'set-relay');
      otherRelay = MockRelay(name: 'other-relay');

      // the jit engine ranks from cached nip65 data, so that is where the two
      // relays have to be announced. It makes both a candidate the jit engine
      // could pick, leaving the request as the only thing deciding which one is
      // actually used.
      //
      // saved as the kind 10002 event rather than through saveUserRelayLists:
      // that projection is derived from the cached event and is rebuilt whenever
      // an event for the same pubkey lands, which a query response does.
      cache = MemCacheManager();
      await cache.saveEvents([
        Nip65.fromMap(author.publicKey, {
          setRelay.url: ReadWriteMarker.readWrite,
          otherRelay.url: ReadWriteMarker.readWrite,
        }).toEvent(),
      ]);

      // only setRelay stores the note, so a query that comes back with it was
      // served by setRelay and one that comes back empty was not
      await Future.wait([
        setRelay.startServer(textNotes: {author: note}),
        otherRelay.startServer(textNotes: {}),
      ]);
    });

    tearDown(() async {
      await setRelay.stopServer();
      await otherRelay.stopServer();
    });
  }

  group('routing', () {
    registerFixtures();

    test(
      'a request naming a relay set goes only to the relays in the set',
      () async {
        final ndk = combinedNdk();
        addTearDown(ndk.destroy);

        final response = ndk.requests.query(
          filter: notesOf(author),
          relaySet: setNaming([setRelay.url]),
        );

        expect(await response.future, [note]);
        expect(
          ndk.relays.globalState.relays.keys.map((key) => key.url),
          [setRelay.url],
          reason: 'the relay sets engine must not open anything else for this',
        );
      },
    );

    test('a request naming no relay set is served by the jit engine', () async {
      final ndk = combinedNdk();
      addTearDown(ndk.destroy);

      final response = ndk.requests.query(filter: notesOf(author));

      expect(await response.future, [
        note,
      ], reason: 'the jit engine ranks by usefulness and picks setRelay');
      expect(
        ndk.relays.globalState.relays.keys.map((key) => key.url),
        isNotEmpty,
        reason: 'the jit engine resolved relays from the cached nip65 data',
      );
    });

    test('a relay set wins over explicit relays', () async {
      final ndk = combinedNdk();
      addTearDown(ndk.destroy);

      final response = ndk.requests.query(
        filter: notesOf(author),
        relaySet: setNaming([setRelay.url]),
        explicitRelays: [otherRelay.url],
      );

      expect(await response.future, [
        note,
      ], reason: 'the set is the statement of where to go');
      expect(
        ndk.relays.globalState.relays.keys.map((key) => key.url),
        isNot(contains(otherRelay.url)),
        reason: 'a jit dispatch would have gone to the explicit relay instead',
      );
    });
  });

  group('shared connection pool', () {
    registerFixtures();

    test('mixed traffic to one relay opens a single socket', () async {
      final ndk = combinedNdk();
      addTearDown(ndk.destroy);

      // both requests want setRelay, one naming it in a relay set and one as an
      // explicit relay, started together. Whichever path opens the socket, the
      // other has to find it in the pool instead of opening a second one.
      final fromSet = ndk.requests.query(
        filter: notesOf(author),
        relaySet: setNaming([setRelay.url]),
      );
      final fromExplicit = ndk.requests.query(
        filter: notesOf(author),
        explicitRelays: [setRelay.url],
      );

      expect(await fromSet.future, [note]);
      expect(
        await fromExplicit.future,
        [note],
        reason:
            'a request must not be dropped because another engine holds '
            'the relay it named as still connecting',
      );

      expect(
        setRelay.connectedClientCount,
        1,
        reason:
            'the pool is keyed by relay and identity, so both share a socket',
      );
      expect(
        ndk.relays.globalState.relays.keys
            .where((key) => key.url == setRelay.url)
            .length,
        1,
        reason: 'one pool entry per relay, whichever engine created it',
      );
    });

    test('a socket opened for a relay set carries the jit bookkeeping', () async {
      final ndk = combinedNdk();
      addTearDown(ndk.destroy);

      final fromSet = ndk.requests.query(
        filter: notesOf(author),
        relaySet: setNaming([setRelay.url]),
      );
      expect(await fromSet.future, [note]);

      // the jit engine records which pubkeys it assigned to a relay. The socket
      // was opened by the relay sets engine, so this is the check that the jit
      // data is present on a connection it did not create itself, and that the
      // jit path can go on to use the very same entry.
      //
      // cacheRead is off: the note is already cached by the request above, and a
      // request answered from cache never reaches an engine.
      final fromJit = ndk.requests.query(
        filter: notesOf(author),
        cacheRead: false,
      );
      expect(await fromJit.future, [note]);

      final entry = ndk.relays.globalState.relays.values.firstWhere(
        (v) => v.url == setRelay.url,
      );
      expect(
        entry.specificEngineData.jit.assignedPubkeys.map((a) => a.pubkey),
        contains(author.publicKey),
      );
      expect(setRelay.connectedClientCount, 1);
    });

    test(
      'an authenticated request does not disturb the shared anonymous one',
      () async {
        final ndk = combinedNdk();
        addTearDown(ndk.destroy);

        final account = Account(
          pubkey: author.publicKey,
          type: AccountType.privateKey,
          signer: Bip340EventSigner(
            privateKey: author.privateKey!,
            publicKey: author.publicKey,
          ),
        );
        ndk.accounts.addAccount(
          pubkey: account.pubkey,
          type: account.type,
          signer: account.signer,
        );

        final fromSet = ndk.requests.query(
          filter: notesOf(author),
          relaySet: setNaming([setRelay.url]),
        );
        expect(await fromSet.future, [note]);

        final authenticated = ndk.requests.query(
          filter: notesOf(author),
          relaySet: setNaming([setRelay.url]),
          auth: AuthPolicy.require(account),
        );
        expect(await authenticated.future, [note]);

        // two sockets towards one relay is not a duplicate: the authenticated
        // request is bound to an identity and may only ever assume it, so it
        // cannot travel on the anonymous socket.
        expect(setRelay.connectedClientCount, 2);
        expect(
          ndk.relays.globalState.relays.keys
              .where((key) => key.url == setRelay.url)
              .map((key) => key.pubkey),
          [null, author.publicKey],
        );
      },
    );
  });
}
