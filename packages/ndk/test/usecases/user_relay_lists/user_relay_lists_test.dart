import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../mocks/mock_event_verifier.dart';

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

    late var relay0;
    late var ndk;

    setUp(() async {
      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        bootstrapRelays: [],
      );

      ndk = Ndk(config);

      cache.saveUserRelayList(cache0);
      //cache.saveContactList(cache1ContactList);
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
  });
}
