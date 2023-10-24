import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/db/user_contacts.dart';
import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/db/relay_set.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

class IsarCacheManager implements CacheManager {

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
        UserRelayListSchema, RelaySetSchema, UserContactsSchema
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
}
