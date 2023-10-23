// ignore_for_file: avoid_print

import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/relay_set.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

class CacheManager {

  late Isar isar;

  Future<void> init(String? path) async {
    // await Isar.initialize("./libisar_android_armv7.so");//initializeIsarCore(download: true);

    // final dir = await getApplicationDocumentsDirectory();
    // final dir = Directory.systemTemp.createTempSync()
    isar = Isar.open(
      inspector: kDebugMode,
      directory: path?? Directory.systemTemp.path,
      engine: IsarEngine.isar,
      schemas: [
        UserRelayListSchema, RelaySetSchema
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
    return isar.relaySets.get(name+pubKey);
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

  Future<void> saveNip02ContactList(Nip02ContactList contactList) async {
    final startTime = DateTime.now();
    // await isar.writeAsync((isar) {
    //   isar.nip02ContactLists.put(contactList);
    // });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED nip02ContactList ${contactList.pubKey} took ${duration.inMilliseconds} ms");
  }

  Nip02ContactList? loadNip02ContactList(String pubKey) {
    return null;//isar.nip02ContactLists.get(pubKey);
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

  // Future<void> saveRelaySet(RelaySet relaySet) async {
  //   final startTime = DateTime.now();
  //   await isar.writeAsync((isar) {
  //     isar.relaySets.put(relaySet);
  //   });
  //   final endTime = DateTime.now();
  //   final duration = endTime.difference(startTime);
  //   print("SAVED relaySet ${relaySet.pubKey} took ${duration.inMilliseconds} ms");
  // }
  //
  // RelaySet? loadRelaySet(String pubKey) {
  //   return isar.relaySets.get(pubKey);
  // }
}
