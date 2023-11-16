import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/db/db_contact_list.dart';
import 'package:dart_ndk/db/db_event.dart';
import 'package:dart_ndk/db/db_metadata.dart';
import 'package:dart_ndk/db/db_nip05.dart';
import 'package:dart_ndk/db/db_relay_set.dart';
import 'package:dart_ndk/db/db_user_relay_list.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../models/relay_set.dart';
import '../models/user_relay_list.dart';
import '../nips/nip01/metadata.dart';
import '../nips/nip05/nip05.dart';

class DbCacheManager extends CacheManager {

  late Isar isar;

  Future<void> init({String? directory}) async {
    // await Isar.initialize("./libisar_android_armv7.so");//initializeIsarCore(download: true);

    // final dir = await getApplicationDocumentsDirectory();
    // final dir = Directory.systemTemp.createTempSync()
    if (directory == Isar.sqliteInMemory) {
      await Isar.initialize();
    }
    isar = Isar.open(
      name: "db_ndk_${kDebugMode?"debug":"release"}",
      inspector: kDebugMode,
      directory: directory ?? Directory.systemTemp.path,
      engine: directory == Isar.sqliteInMemory ? IsarEngine.sqlite: IsarEngine.isar,
      schemas: [
        DbEventSchema,
        DbUserRelayListSchema,
        DbRelaySetSchema,
        DbContactListSchema,
        DbMetadataSchema,
        DbNip05Schema
      ],
    );
    // isar.write((isar) {
    //   isar.clear();
    // });
  }

  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbUserRelayLists.put(DbUserRelayList.fromUserRelayList(userRelayList));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED UserRelayList ${userRelayList.pubKey} took ${duration.inMilliseconds} ms");
  }

  UserRelayList? loadUserRelayList(String pubKey) {
    return isar.dbUserRelayLists.get(pubKey);
  }

  RelaySet? loadRelaySet(String name, String pubKey) {
    return isar.dbRelaySets.get(RelaySet.buildId(name, pubKey));
  }

  Future<void> saveRelaySet(RelaySet relaySet) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbRelaySets.put(DbRelaySet.fromRelaySet(relaySet));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED relaySet ${relaySet.name}+${relaySet.pubKey} took ${duration.inMilliseconds} ms");
  }

  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbUserRelayLists.putAll(userRelayLists.map((e) => DbUserRelayList.fromUserRelayList(e),).toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${userRelayLists.length } UserRelayLists took ${duration.inMilliseconds} ms");
  }

  @override
  ContactList? loadContactList(String pubKey) {
    return isar.dbContactLists.get(pubKey);
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbContactLists.put(DbContactList.fromContactList(contactList));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${contactList.pubKey} ContacList took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveContactLists(List<ContactList> list) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbContactLists.putAll(list.map((e) => DbContactList.fromContactList(e)).toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${list.length} ContactLists took ${duration.inMilliseconds} ms");
  }

  @override
  Metadata? loadMetadata(String pubKey) {
    return isar.dbMetadatas.get(pubKey);
  }

  @override
  Future<void> removeAllRelaySets() async {
    isar.write((isar) {
      isar.dbRelaySets.clear();
    });
  }

  @override
  Future<void> removeAllContactLists() async {
    isar.write((isar) {
      isar.dbContactLists.clear();
    });
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    isar.write((isar) {
      isar.dbUserRelayLists.clear();
    });
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    isar.write((isar) {
      isar.dbRelaySets.delete(RelaySet.buildId(name, pubKey));
    });
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    isar.write((isar) {
      isar.dbContactLists.delete(pubKey);
    });
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    isar.write((isar) {
      isar.dbUserRelayLists.delete(pubKey);
    });
  }
  
  /************************************************************************************************/

  @override
  Future<void> removeMetadata(String pubKey) async {
    isar.write((isar) {
      isar.dbMetadatas.delete(pubKey);
    });
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbMetadatas.put(DbMetadata.fromMetadata(metadata));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED Metadata took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbMetadatas.putAll(metadatas.map((metadata) => DbMetadata.fromMetadata(metadata)).toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${metadatas.length} UserMetadatas took ${duration.inMilliseconds} ms");
  }

  @override
  List<Metadata?> loadMetadatas(List<String> pubKeys) {
    return isar.dbMetadatas.getAll(pubKeys);
  }

  Iterable<Metadata> searchMetadatas(String search, int limit) {
    return isar.dbMetadatas.where().splitDisplayNameWordsElementStartsWith(search).or().splitNameWordsElementStartsWith(search).findAll().take(limit);
  }

  @override
  Future<void> removeAllMetadatas() async {
    isar.write((isar) {
      isar.dbMetadatas.clear();
    });
  }

  /************************************************************************************************/

  @override
  Future<void> removeNip05(String pubKey) async {
    isar.write((isar) {
      isar.dbNip05s.delete(pubKey);
    });
  }

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbNip05s.put(DbNip05.fromNip05(nip05));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED Nip05 took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbNip05s.putAll(nip05s.map((nip05) => DbNip05.fromNip05(nip05)).toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${nip05s.length} UserNip05s took ${duration.inMilliseconds} ms");
  }

  @override
  List<Nip05?> loadNip05s(List<String> pubKeys) {
    return isar.dbNip05s.getAll(pubKeys);
  }

  @override
  Nip05? loadNip05(String pubKey) {
    return isar.dbNip05s.get(pubKey);
  }

  @override
  Future<void> removeAllNip05s() async {
    isar.write((isar) {
      isar.dbNip05s.clear();
    });
  }
  /************************************************************************************************/

  @override
  Future<void> removeEvent(String id) async {
    isar.write((isar) {
      isar.dbEvents.delete(id);
    });
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbEvents.put(DbEvent.fromNip01Event(event));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED Event took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    final startTime = DateTime.now();
    isar.write((isar) {
      isar.dbEvents.putAll(events.map((event) => DbEvent.fromNip01Event(event)).toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${events.length} Events took ${duration.inMilliseconds} ms");
  }

  @override
  List<Nip01Event> loadEvents(List<String> pubKeys, List<int> kinds) {
    return isar.dbEvents.where()
        .optional(kinds!=null && kinds.isNotEmpty, (q) => q.anyOf(kinds, (q, kind) => q.kindEqualTo(kind)))
        .and()
        .optional(pubKeys!=null && pubKeys.isNotEmpty, (q) => q.anyOf(pubKeys, (q, pubKey) => q.pubKeyEqualTo(pubKey)))
        .findAll();
  }

  @override
  Nip01Event? loadEvent(String id) {
    return isar.dbEvents.get(id);
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    isar.write((isar) {
      isar.dbEvents.where().pubKeyEqualTo(pubKey).deleteAll();
    });
  }

  @override
  Future<void> removeAllEvents() async {
    isar.write((isar) {
      isar.dbEvents.clear();
    });
  }
}
