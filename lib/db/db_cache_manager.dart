import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/db/user_contacts.dart';
import 'package:dart_ndk/db/user_metadata.dart';
import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/db/relay_set.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

class IsarCacheManager extends CacheManager {

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
        RelaySetSchema,
        UserContactsSchema,
        UserMetadataSchema,
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
    return isar.relaySets.get(RelaySet.buildId(name, pubKey));
  }

  Future<void> saveRelaySet(RelaySet relaySet) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.relaySets.put(relaySet);
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
  UserContacts? loadUserContacts(String pubKey) {
    return isar.userContacts.get(pubKey);
  }

  @override
  Future<void> saveUserContacts(UserContacts userContacts) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.userContacts.put(userContacts);
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${userContacts.pubKey} UserContacts took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveManyUserContacts(List<UserContacts> list) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.userContacts.putAll(list);
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${list.length} UserContacts took ${duration.inMilliseconds} ms");
  }

  @override
  UserMetadata? loadUserMetadata(String pubKey) {
    return isar.userMetadatas.get(pubKey);
  }

  @override
  Future<void> removeAllRelaySets() async {
    await isar.writeAsync((isar) {
      isar.relaySets.clear();
    });
  }

  @override
  Future<void> removeAllUserContacts() async {
    await isar.writeAsync((isar) {
      isar.userContacts.clear();
    });
  }

  @override
  Future<void> removeAllUserMetadatas() async {
    await isar.writeAsync((isar) {
      isar.userMetadatas.clear();
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
      isar.relaySets.delete(RelaySet.buildId(name, pubKey));
    });
  }

  @override
  Future<void> removeUserContacts(String pubKey) async {
    await isar.writeAsync((isar) {
      isar.userContacts.delete(pubKey);
    });
  }

  @override
  Future<void> removeUserMetadata(String pubKey) async {
    await isar.writeAsync((isar) {
      isar.userMetadatas.delete(pubKey);
    });
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    await isar.writeAsync((isar) {
      isar.userRelayLists.delete(pubKey);
    });
  }

  @override
  Future<void> saveUserMetadata(UserMetadata metadata) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.userMetadatas.put(metadata);
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED UserMetadata took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveUserMetadatas(List<UserMetadata> metadatas) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.userMetadatas.putAll(metadatas);
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED ${metadatas.length} UserMetadatas took ${duration.inMilliseconds} ms");
  }

  @override
  List<UserMetadata?> loadUserMetadatas(List<String> pubKeys) {
    return isar.userMetadatas.getAll(pubKeys);
  }
}
