import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/db/db_contact_list.dart';
import 'package:dart_ndk/db/db_metadata.dart';
import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/db/db_relay_set.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../models/relay_set.dart';
import '../nips/nip01/metadata.dart';

class DbCacheManager extends CacheManager {

  late Isar isar;

  Future<void> init({String? path}) async {
    // await Isar.initialize("./libisar_android_armv7.so");//initializeIsarCore(download: true);

    // final dir = await getApplicationDocumentsDirectory();
    // final dir = Directory.systemTemp.createTempSync()
    isar = Isar.open(
      inspector: kDebugMode,
      directory: path ?? Directory.systemTemp.path,
      engine: IsarEngine.isar,
      schemas: [
        UserRelayListSchema,
        DbRelaySetSchema,
        DbContactListSchema,
        DbMetadataSchema,
      ],
    );
    // await isar.writeAsync((isar) {
    //   isar.clear();
    // });
  }

  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.userRelayLists.put(userRelayList);
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED UserRelayList ${userRelayList.id} took ${duration.inMilliseconds} ms");
  }

  UserRelayList? loadUserRelayList(String pubKey) {
    return isar.userRelayLists.get(pubKey);
  }

  RelaySet? loadRelaySet(String name, String pubKey) {
    return isar.dbRelaySets.get(RelaySet.buildId(name, pubKey));
  }

  Future<void> saveRelaySet(RelaySet relaySet) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.dbRelaySets.put(DbRelaySet.fromRelaySet(relaySet));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED relaySet ${relaySet.name}+${relaySet.pubKey} took ${duration.inMilliseconds} ms");
  }

  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.userRelayLists.putAll(userRelayLists);
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
    await isar.writeAsync((isar) {
      isar.dbContactLists.put(DbContactList.fromContactList(contactList));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${contactList.pubKey} UserContacts took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveContactLists(List<ContactList> list) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
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
    await isar.writeAsync((isar) {
      isar.dbRelaySets.clear();
    });
  }

  @override
  Future<void> removeAllContactLists() async {
    await isar.writeAsync((isar) {
      isar.dbContactLists.clear();
    });
  }

  @override
  Future<void> removeAllMetadatas() async {
    await isar.writeAsync((isar) {
      isar.dbMetadatas.clear();
    });
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    await isar.writeAsync((isar) {
      isar.userRelayLists.clear();
    });
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    await isar.writeAsync((isar) {
      isar.dbRelaySets.delete(RelaySet.buildId(name, pubKey));
    });
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    await isar.writeAsync((isar) {
      isar.dbContactLists.delete(pubKey);
    });
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    await isar.writeAsync((isar) {
      isar.dbMetadatas.delete(pubKey);
    });
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    await isar.writeAsync((isar) {
      isar.userRelayLists.delete(pubKey);
    });
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.dbMetadatas.put(DbMetadata.fromMetadata(metadata));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED Metadata took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
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
}
