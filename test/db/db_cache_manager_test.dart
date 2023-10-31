// ignore_for_file: avoid_print

import 'package:dart_ndk/db/db_cache_manager.dart';
import 'package:dart_ndk/db/db_contact_list.dart';
import 'package:dart_ndk/db/db_metadata.dart';
import 'package:dart_ndk/db/db_relay_set.dart';
import 'package:dart_ndk/db/db_user_relay_list.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/read_write.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart' as isar;

void main() async {
  await isar.Isar.initialize("./libisar.so");//initializeIsarCore(download: true);

  test('DbContactList', () async {
    DbCacheManager cacheManager = DbCacheManager();
    await cacheManager.init();
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String contact1 = "contact1";
    String pubKey1 = "pubKey1";
    DbContactList userContacts = DbContactList(pubKey: pubKey1, contacts: [contact1]);
    await cacheManager.saveContactList(userContacts);

    DbContactList? loadedUserContacts = cacheManager.loadContactList(pubKey1) as DbContactList?;
    expect(loadedUserContacts!.pubKey, userContacts.pubKey);
    expect(loadedUserContacts.contacts, userContacts.contacts);
  });

  test('DbUserRelayList', () async {
    DbCacheManager cacheManager = DbCacheManager();
    await cacheManager.init();
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String pubKey1 = "pubKey1";
    DbUserRelayList userRelayList =
      DbUserRelayList(pubKey: pubKey1, items: [DbRelayListItem("wss://bla.com", ReadWriteMarker.readWrite)], createdAt: now, refreshedTimestamp: now);
    await cacheManager.saveUserRelayList(userRelayList);

    DbUserRelayList? loadedUserRelayList = cacheManager.loadUserRelayList(pubKey1) as DbUserRelayList?;
    expect(loadedUserRelayList!.id, userRelayList.id);
    expect(loadedUserRelayList.items.length, userRelayList.items.length);
    for (var i = 0; i < userRelayList.items.length; i++) {
      expect(loadedUserRelayList.items[i].url, userRelayList.items[i].url);
      expect(loadedUserRelayList.items[i].marker, userRelayList.items[i].marker);
    }
  });
  test('DbRelaySet', () async {
    DbCacheManager cacheManager = DbCacheManager();
    await cacheManager.init();
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String pubKey1 = "pubKey1";
    String pubKey2 = "pubKey2";
    DbRelaySet relaySet = DbRelaySet(
      name: "feed",
      pubKey: pubKey1,
      relayMinCountPerPubkey: 2,
      items: [DbRelaySetItem("wss://bla.com", [DbPubkeyMapping(pubKey: pubKey2, marker: ReadWriteMarker.readWrite.name)])],
      // notCoveredPubkeys: [],
      direction: RelayDirection.outbox );
    await cacheManager.saveRelaySet(relaySet);

    DbRelaySet? loadedRelaySet = cacheManager.loadRelaySet(relaySet.name, relaySet.pubKey) as DbRelaySet?;
    expect(loadedRelaySet!.id, relaySet.id);
    expect(loadedRelaySet.items.length, relaySet.items.length);
    for (var i = 0; i < relaySet.items.length; i++) {
      expect(loadedRelaySet.items[i].url, relaySet.items[i].url);
      expect(loadedRelaySet.items[i].pubKeyMappings.length, relaySet.items[i].pubKeyMappings.length);
      expect(loadedRelaySet.relayMinCountPerPubkey, relaySet.relayMinCountPerPubkey);
      expect(loadedRelaySet.direction, relaySet.direction);
    }
  });
  test('DbMetadata', () async {
    DbCacheManager cacheManager = DbCacheManager();
    await cacheManager.init();
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String pubKey1 = "pubKey1";
    DbMetadata metadata = DbMetadata(
      pubKey: pubKey1,
      name: "name",
      about: "about",
      banner: "https://cdn.picture.com/banner.jpg",
      displayName: "displayName",
      lud06: "lud06",
      lud16: "lud16",
      nip05: "nip05@domain.com",
      picture: "https://cdn.picture.com/cat.jpg",
      updatedAt: now,
      website: "https://website.com"
    );
    await cacheManager.saveMetadata(metadata);

    DbMetadata? loaded = cacheManager.loadMetadata(pubKey1) as DbMetadata?;
    expect(loaded!.id, metadata.id);
    expect(loaded!.pubKey, metadata.pubKey);
    expect(loaded!.name, metadata.name);
    expect(loaded!.about, metadata.about);
    expect(loaded!.displayName, metadata.displayName);
    expect(loaded!.lud06, metadata.lud06);
    expect(loaded!.lud16, metadata.lud16);
    expect(loaded!.nip05, metadata.nip05);
    expect(loaded!.picture, metadata.picture);
    expect(loaded!.updatedAt, metadata.updatedAt);
    expect(loaded!.website, metadata.website);
  });
}
