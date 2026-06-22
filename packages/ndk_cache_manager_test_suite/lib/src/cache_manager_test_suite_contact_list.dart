part of 'cache_manager_test_suite.dart';

void _runContactListTests(CacheManager Function() getCacheManager) {
  test('saveContactList and loadContactList', () async {
    final cacheManager = getCacheManager();
    final contactList = ContactList(
      pubKey: 'contact_list_pubkey_1',
      contacts: ['contact1', 'contact2', 'contact3'],
    );
    contactList.createdAt = 1234567890;
    contactList.petnames = ['Alice', 'Bob', 'Carol'];
    contactList.followedTags = ['nostr', 'bitcoin'];

    await cacheManager.saveContactList(contactList);
    final loaded = await cacheManager.loadContactList('contact_list_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(contactList.pubKey));
    expect(loaded.contacts, equals(contactList.contacts));
    expect(loaded.createdAt, equals(contactList.createdAt));
    expect(loaded.petnames, equals(contactList.petnames));
    expect(loaded.followedTags, equals(contactList.followedTags));
  });

  test('saveContactLists batch operation', () async {
    final cacheManager = getCacheManager();
    final contactLists = [
      ContactList(pubKey: 'contact_batch_1', contacts: ['c1']),
      ContactList(pubKey: 'contact_batch_2', contacts: ['c2']),
    ];

    await cacheManager.saveContactLists(contactLists);

    for (final contactList in contactLists) {
      final loaded = await cacheManager.loadContactList(contactList.pubKey);
      expect(loaded, isNotNull);
      expect(loaded!.contacts, equals(contactList.contacts));
    }
  });

  test('removeContactList', () async {
    final cacheManager = getCacheManager();
    final contactList = ContactList(
      pubKey: 'contact_remove',
      contacts: ['contact1'],
    );

    await cacheManager.saveContactList(contactList);
    expect(await cacheManager.loadContactList('contact_remove'), isNotNull);

    await cacheManager.removeContactList('contact_remove');
    expect(await cacheManager.loadContactList('contact_remove'), isNull);
  });

  test('removeAllContactLists', () async {
    final cacheManager = getCacheManager();
    final contactLists = [
      ContactList(pubKey: 'contact_clear_1', contacts: ['c1']),
      ContactList(pubKey: 'contact_clear_2', contacts: ['c2']),
    ];

    await cacheManager.saveContactLists(contactLists);
    await cacheManager.removeAllContactLists();

    for (final contactList in contactLists) {
      expect(await cacheManager.loadContactList(contactList.pubKey), isNull);
    }
  });
}
