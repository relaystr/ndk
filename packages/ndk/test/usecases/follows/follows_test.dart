import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  group('follows', () {
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

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 5095);
      await relay0.startServer(contactLists: {
        key0.publicKey: network0ContactList.toEvent(),
        key1.publicKey: network1ContactList.toEvent(),
      });

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay0.url],
        ignoreRelays: [],
      );

      ndk = Ndk(config);

      await ndk.relays.seedRelaysConnected;

      cache.saveContactList(cache0ContactList);
      //cache.saveContactList(cache1ContactList);
    });

    tearDown(() async {
      await ndk.destroy();
      await relay0.stopServer();
    });

    test('contactList equal', () {
      expect(cache0ContactList, equals(cache0ContactList));
      expect(cache0ContactList, isNot(equals(network0ContactList)));
    });

    test('getContactList - cache', () async {
      final rcvContactList = await ndk.follows.getContactList(key0.publicKey);

      // cache
      expect(rcvContactList, equals(cache0ContactList));
    });

    test('getContactList- network', () async {
      final rcvContactList = await ndk.follows.getContactList(
        key1.publicKey,
        forceRefresh: true,
      );

      // cache
      expect(rcvContactList!.contacts, equals(network1ContactList.contacts));
    });

    test('add/remove contact', () async {
      var list = await ndk.follows.getContactList(
        key0.publicKey,
      );
      expect(list!.contacts.contains(key1.publicKey), false);

      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);

      // overwrite same list
      await ndk.follows.broadcastSetContactList(list);

      // add key1
      await ndk.follows.broadcastAddContact(key1.publicKey);

      list =
          await ndk.follows.getContactList(key0.publicKey, forceRefresh: true);
      expect(list!.contacts.contains(key1.publicKey), true);

      // remove key1
      await ndk.follows.broadcastRemoveContact(key1.publicKey);

      list =
          await ndk.follows.getContactList(key0.publicKey, forceRefresh: true);
      expect(list!.contacts.contains(key1.publicKey), false);
    });

    test('add/remove followed tag', () async {
      var list = await ndk.follows.getContactList(
        key0.publicKey,
      );
      final tag = "myTag";
      expect(list!.followedTags.contains(tag), false);

      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);

      // add tag
      await ndk.follows.broadcastAddFollowedTag(tag);

      list = await ndk.follows.getContactList(
        key0.publicKey,
      );
      expect(list!.followedTags.contains(tag), true);

      list =
          await ndk.follows.getContactList(key0.publicKey, forceRefresh: true);
      expect(list!.followedTags.contains(tag), true);

      // remove key1
      await ndk.follows.broadcastRemoveFollowedTag(tag);

      list = await ndk.follows.getContactList(
        key0.publicKey,
      );
      expect(list!.followedTags.contains(tag), false);
      list =
          await ndk.follows.getContactList(key0.publicKey, forceRefresh: true);
      expect(list!.followedTags.contains(tag), false);
    });

    test('add/remove followed community', () async {
      var list = await ndk.follows.getContactList(
        key0.publicKey,
      );
      final community = "myCommunity";
      expect(list!.followedCommunities.contains(community), false);

      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);

      // add community
      await ndk.follows.broadcastAddFollowedCommunity(community);

      list =
          await ndk.follows.getContactList(key0.publicKey, forceRefresh: true);
      expect(list!.followedCommunities.contains(community), true);

      // remove community
      await ndk.follows.broadcastRemoveFollowedCommunity(community);

      list =
          await ndk.follows.getContactList(key0.publicKey, forceRefresh: true);
      expect(list!.followedCommunities.contains(community), false);
    });

    test('add/remove followed event', () async {
      var list = await ndk.follows.getContactList(
        key0.publicKey,
      );
      final event = "myEvent";
      expect(list!.followedEvents.contains(event), false);

      ndk.accounts
          .loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);

      // add community
      await ndk.follows.broadcastAddFollowedEvent(event);

      list =
          await ndk.follows.getContactList(key0.publicKey, forceRefresh: true);
      expect(list!.followedEvents.contains(event), true);

      // remove community
      await ndk.follows.broadcastRemoveFollowedEvent(event);

      list =
          await ndk.follows.getContactList(key0.publicKey, forceRefresh: true);
      expect(list!.followedEvents.contains(event), false);
    });
  });
}
