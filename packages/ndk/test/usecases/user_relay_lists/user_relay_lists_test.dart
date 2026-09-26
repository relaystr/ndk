import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  group('user relay lists', () {
    KeyPair key0 = Bip340.generatePrivateKey();

    final UserRelayList cache0 = UserRelayList(
      pubKey: key0.publicKey,
      relays: {},
      createdAt: 50,
      refreshedTimestamp: 0,
    );

    KeyPair key1 = Bip340.generatePrivateKey();

    final UserRelayList cache1 = UserRelayList(
      pubKey: key1.publicKey,
      relays: {},
      createdAt: 100,
      refreshedTimestamp: 0,
    );

    KeyPair key3 = Bip340.generatePrivateKey();

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5101);
      await relay0.startServer();

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay0.url],
        indexerRelays: [],
        // logLevel: Logger.logLevels.trace,
        ignoreRelays: [],
      );

      ndk = Ndk(config);

      await ndk.relays.seedRelaysConnected;

      cache.saveUserRelayList(cache0);
    });

    tearDown(() async {
      await ndk.destroy();
      await relay0.stopServer();
    });

    test('user relay lists equal', () {
      expect(cache0, equals(cache0));
      expect(cache0, isNot(equals(cache1)));
    });

    test('readUrls and writeUrls', () {
      final event = Nip01Event(
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: key0.publicKey,
        kind: Nip65.kKind,
        content: "",
        tags: [
          ['r', 'wss://relay.read', 'read'],
          ['r', 'wss://relay.write', 'write'],
          ['r', 'wss://relay.readwrite'],
        ],
      );
      final nip65 = Nip65.fromEvent(event);
      final userRelayList = UserRelayList.fromNip65(nip65);

      expect(userRelayList.readUrls.toList(), [
        'wss://relay.read',
        'wss://relay.readwrite',
      ]);
      expect(userRelayList.writeUrls.toList(), [
        'wss://relay.write',
        'wss://relay.readwrite',
      ]);
    });

    test('getSingleUserRelayList - cache', () async {
      final rcv = await ndk.userRelayLists.getSingleUserRelayList(
        key0.publicKey,
      );

      // cache
      expect(rcv, equals(cache0));
    });
    test('getDmRelays - returns null when no kind 10050 found', () async {
      final dmRelays = await ndk.userRelayLists.getDmRelays(key1.publicKey);
      expect(dmRelays, isNull);
    });

    test('getDmRelays - reads from cache', () async {
      final event = Nip01Event(
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: key0.publicKey,
        kind: Nip51List.kDmRelays,
        content: "",
        tags: [
          ['relay', 'wss://dm1.example'],
          ['relay', 'wss://dm2.example'],
        ],
      );
      await ndk.config.cache.saveEvent(event);

      final dmRelays = await ndk.userRelayLists.getDmRelays(key0.publicKey);
      expect(dmRelays, ['wss://dm1.example', 'wss://dm2.example']);
    });

    test('broadcastAdd/RemoveNip65Relay', () async {
      ndk.accounts.loginPrivateKey(
        pubkey: key3.publicKey,
        privkey: key3.privateKey!,
      );
      final r1 = "wss://bla1.com";
      // add
      await ndk.userRelayLists.broadcastAddNip65Relay(
        relayUrl: r1,
        marker: ReadWriteMarker.readWrite,
        broadcastRelays: [relay0.url],
      );

      UserRelayList? list = await ndk.userRelayLists.getSingleUserRelayList(
        key3.publicKey,
        forceRefresh: true,
      );
      expect(list!.relays.keys.contains(r1), true);
      expect(list.relays[r1], ReadWriteMarker.readWrite);

      // update marker
      await ndk.userRelayLists.broadcastUpdateNip65RelayMarker(
        relayUrl: r1,
        marker: ReadWriteMarker.readOnly,
        broadcastRelays: [relay0.url],
      );

      list = await ndk.userRelayLists.getSingleUserRelayList(
        key3.publicKey,
        forceRefresh: true,
      );
      expect(list!.relays[r1], ReadWriteMarker.readOnly);

      // remove
      await ndk.userRelayLists.broadcastRemoveNip65Relay(
        relayUrl: r1,
        broadcastRelays: [relay0.url],
      );

      list = await ndk.userRelayLists.getSingleUserRelayList(
        key3.publicKey,
        forceRefresh: true,
      );
      expect(list!.relays.containsKey(r1), false);
    });
  });

  group('nip65 lookup on indexer relays', () {
    KeyPair key = Bip340.generatePrivateKey();

    late MockRelay indexer;
    late MockRelay bootstrap;
    late Ndk ndk;

    setUp(() async {
      indexer = MockRelay(name: "indexer");
      bootstrap = MockRelay(name: "bootstrap");

      await indexer.startServer(
        nip65s: {
          key: Nip65.fromMap(key.publicKey, {
            "wss://relay.write": ReadWriteMarker.writeOnly,
          }),
        },
      );
      await bootstrap.startServer();

      ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: [bootstrap.url],
          indexerRelays: [indexer.url],
        ),
      );

      await ndk.relays.seedRelaysConnected;
    });

    tearDown(() async {
      await ndk.destroy();
      await indexer.stopServer();
      await bootstrap.stopServer();
    });

    test('resolved from an indexer the bootstrap relays do not know', () async {
      final list = await ndk.userRelayLists.getSingleUserRelayList(
        key.publicKey,
      );

      expect(list!.writeUrls, contains("wss://relay.write"));
    });
  });

  group('nip65 refresh before editing the own list', () {
    KeyPair key = Bip340.generatePrivateKey();

    late MockRelay indexer;
    late MockRelay bootstrap;
    late MockRelay own;
    late MemCacheManager cache;
    late Ndk ndk;

    setUp(() async {
      indexer = MockRelay(name: "indexer");
      bootstrap = MockRelay(name: "bootstrap");
      own = MockRelay(name: "own");

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await indexer.startServer(
        nip65s: {
          key: Nip65(
            pubKey: key.publicKey,
            relays: {"wss://relay.stale": ReadWriteMarker.readWrite},
            createdAt: now - 3600,
          ),
        },
      );
      await bootstrap.startServer();
      await own.startServer(
        nip65s: {
          key: Nip65(
            pubKey: key.publicKey,
            relays: {"wss://relay.fresh": ReadWriteMarker.readWrite},
            createdAt: now,
          ),
        },
      );

      cache = MemCacheManager();
      ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: cache,
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: [bootstrap.url],
          indexerRelays: [indexer.url],
        ),
      );

      await ndk.relays.seedRelaysConnected;

      ndk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );
    });

    tearDown(() async {
      await ndk.destroy();
      await indexer.stopServer();
      await bootstrap.stopServer();
      await own.stopServer();
    });

    test('picks up an edit the indexers have not caught up with', () async {
      await cache.saveUserRelayList(
        UserRelayList(
          pubKey: key.publicKey,
          relays: {own.url: ReadWriteMarker.readWrite},
          createdAt: 0,
          refreshedTimestamp: 0,
        ),
      );

      final list = await ndk.userRelayLists.broadcastAddNip65Relay(
        relayUrl: "wss://relay.added",
        marker: ReadWriteMarker.readWrite,
        broadcastRelays: [own.url],
      );

      expect(list.relays.keys, contains("wss://relay.fresh"));
      expect(list.relays.keys, isNot(contains("wss://relay.stale")));
    });
  });
}
