// ignore_for_file: avoid_print

import 'package:dart_ndk/db/db_cache_manager.dart';
import 'package:dart_ndk/db/relay_set.dart';
import 'package:dart_ndk/db/user_contacts.dart';
import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:dart_ndk/read_write.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart' as isar;

void main() async {
  await isar.Isar.initialize("./libisar.so");//initializeIsarCore(download: true);

  test('UserContacts', () async {
    IsarCacheManager cacheManager = IsarCacheManager();
    cacheManager.init();
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String contact1 = "contact1";
    String pubKey1 = "pubKey1";
    UserContacts userContacts = UserContacts(pubKey1, [Contact(contact1 = contact1, null, null)], now, now);
    await cacheManager.saveUserContacts(userContacts);

    UserContacts? loadedUserContacts = cacheManager.loadUserContacts(pubKey1);
    expect(loadedUserContacts!.pubKey, userContacts.pubKey);
    expect(loadedUserContacts.contacts.length, userContacts.contacts.length);
    for (var i = 0; i < userContacts.contacts.length; i++) {
      expect(loadedUserContacts.contacts[i].pubKey, userContacts.contacts[i].pubKey);
    }
  });

  test('UserRelayList', () async {
    IsarCacheManager cacheManager = IsarCacheManager();
    cacheManager.init();
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String pubKey1 = "pubKey1";
    UserRelayList userRelayList = UserRelayList(pubKey1, [RelayListItem("wss://bla.com", ReadWriteMarker.readWrite)], now, now);
    await cacheManager.saveUserRelayList(userRelayList);

    UserRelayList? loadedUserRelayList = cacheManager.loadUserRelayList(pubKey1);
    expect(loadedUserRelayList!.id, userRelayList.id);
    expect(loadedUserRelayList.items.length, userRelayList.items.length);
    for (var i = 0; i < userRelayList.items.length; i++) {
      expect(loadedUserRelayList.items[i].url, userRelayList.items[i].url);
      expect(loadedUserRelayList.items[i].marker, userRelayList.items[i].marker);
    }
  });
  test('RelaySet', () async {
    IsarCacheManager cacheManager = IsarCacheManager();
    cacheManager.init();
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String pubKey1 = "pubKey1";
    String pubKey2 = "pubKey2";
    RelaySet relaySet = RelaySet(
      relayMinCountPerPubkey: 2,
      items: [RelaySetItem("wss://bla.com", [PubkeyMapping(pubKey: pubKey2, rwMarker: ReadWriteMarker.readWrite)])],
      notCoveredPubkeys: [],
      direction: RelayDirection.outbox );
    relaySet.name="feed";
    relaySet.pubKey = pubKey1;
    await cacheManager.saveRelaySet(relaySet);

    RelaySet? loadedRelaySet = cacheManager.loadRelaySet(relaySet.name, relaySet.pubKey);
    expect(loadedRelaySet!.id, relaySet.id);
    expect(loadedRelaySet.items.length, relaySet.items.length);
    for (var i = 0; i < relaySet.items.length; i++) {
      expect(loadedRelaySet.items[i].url, relaySet.items[i].url);
      expect(loadedRelaySet.items[i].pubKeyMappings.length, relaySet.items[i].pubKeyMappings.length);
      expect(loadedRelaySet.relayMinCountPerPubkey, relaySet.relayMinCountPerPubkey);
      expect(loadedRelaySet.direction, relaySet.direction);
    }
  });
}
