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
        refreshedTimestamp: 0);

    KeyPair key1 = Bip340.generatePrivateKey();

    final UserRelayList cache1 = UserRelayList(
        pubKey: key1.publicKey,
        relays: {},
        createdAt: 100,
        refreshedTimestamp: 0);

    KeyPair key3 = Bip340.generatePrivateKey();

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5097);
      await relay0.startServer();

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay0.url],
        // logLevel: Logger.logLevels.trace,
        ignoreRelays: [],
      );

      ndk = Ndk(config);

      await ndk.relays.seedRelaysConnected;

      cache.saveUserRelayList(cache0);
    });

    tearDown(() async {
      await ndk.destroy();
    });

    test('user relay lists equal', () {
      expect(cache0, equals(cache0));
      expect(cache0, isNot(equals(cache1)));
    });

    test('getSingleUserRelayList - cache', () async {
      final rcv =
          await ndk.userRelayLists.getSingleUserRelayList(key0.publicKey);

      // cache
      expect(rcv, equals(cache0));
    });
    test('broadcastAdd/RemoveNip65Relay', () async {
      ndk.accounts
          .loginPrivateKey(pubkey: key3.publicKey, privkey: key3.privateKey!);
      final r1 = "wss://bla1.com";
      // add
      await ndk.userRelayLists.broadcastAddNip65Relay(
          relayUrl: r1,
          marker: ReadWriteMarker.readWrite,
          broadcastRelays: [relay0.url]);

      UserRelayList? list = await ndk.userRelayLists
          .getSingleUserRelayList(key3.publicKey, forceRefresh: true);
      expect(list!.relays.keys.contains(r1), true);
      expect(list.relays[r1], ReadWriteMarker.readWrite);

      // update marker
      await ndk.userRelayLists.broadcastUpdateNip65RelayMarker(
          relayUrl: r1,
          marker: ReadWriteMarker.readOnly,
          broadcastRelays: [relay0.url]);

      list = await ndk.userRelayLists
          .getSingleUserRelayList(key3.publicKey, forceRefresh: true);
      expect(list!.relays[r1], ReadWriteMarker.readOnly);

      // remove
      await ndk.userRelayLists.broadcastRemoveNip65Relay(
          relayUrl: r1,
          broadcastRelays: [relay0.url]);

      list = await ndk.userRelayLists
          .getSingleUserRelayList(key3.publicKey, forceRefresh: true);
      expect(list!.relays.containsKey(r1), false);
    });
  });
}
