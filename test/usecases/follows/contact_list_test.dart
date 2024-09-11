import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  group('follows', () {
    MockRelay relay0 = MockRelay(name: "relay 0", explicitPort: 4341);

    final cache = MemCacheManager();
    final NdkConfig config = NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: cache,
      engine: NdkEngine.JIT,
      bootstrapRelays: [relay0.url],
      ignoreRelays: [],
    );

    final ndk = Ndk(config);

    final Follows follows = ndk.follows;

    KeyPair key0 = Bip340.generatePrivateKey();
    final ContactList network0ContactList = ContactList(
      pubKey: key0.publicKey,
      contacts: [
        'old0',
        'old1',
        'old2',
        'old3',
        'old4',
        'old5',
      ],
    );
    network0ContactList.createdAt = 100;
    final ContactList cache0ContactList = ContactList(
      pubKey: key0.publicKey,
      contacts: [
        'contact0',
        'contact1',
        'contact2',
        'contact3',
        'contact4',
        'contact5',
      ],
    );

    //? network last
    KeyPair key1 = Bip340.generatePrivateKey();
    final ContactList network1ContactList = ContactList(
      pubKey: key1.publicKey,
      contacts: [
        'contact0',
        'contact1',
        'contact2',
      ],
    );

    final ContactList cache1ContactList = ContactList(
      pubKey: key1.publicKey,
      contacts: [
        'old0',
      ],
    );
    cache1ContactList.createdAt = 100;

    setUp(() async {
      cache.saveContactList(cache0ContactList);
      //cache.saveContactList(cache1ContactList);
      await relay0.startServer(textNotes: {
        key0: network0ContactList.toEvent(),
        key1: network1ContactList.toEvent(),
      });
    });

    tearDown(() async {
      await relay0.stopServer();
    });

    test('contactList equal', () {
      expect(cache0ContactList, equals(cache0ContactList));
      expect(cache0ContactList, isNot(equals(network0ContactList)));
    });

    test('getContactList', () async {});

    test('getContactListFuture - cache', () async {
      final rcvContactList = await follows.getContactListFuture(key0.publicKey);

      // cache
      expect(rcvContactList, equals(cache0ContactList));
    });

    test('getContactListFuture - network', () async {
      final rcvContactList = await follows.getContactListFuture(
        key1.publicKey,
        forceRefresh: true,
      );

      // cache
      expect(rcvContactList!.contacts, equals(network1ContactList.contacts));
    });
  });
}
