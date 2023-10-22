// ignore_for_file: avoid_print

import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'nips/nip65/nip65.dart';

class CacheManager {

  late Isar isar;

  Future<void> init() async {
    // await Isar.initialize("./libisar_android_armv7.so");//initializeIsarCore(download: true);

    // final dir = await getApplicationDocumentsDirectory();
    // final dir = Directory.systemTemp.createTempSync()
    isar = Isar.open(
      inspector: kDebugMode,
      directory: Directory.systemTemp.path,
      engine: IsarEngine.isar,
      schemas: [
        Nip65Schema, Nip02ContactListSchema
      ],
    );
  }

  Future<void> saveNip65(Nip65 nip65) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.nip65s.put(nip65);
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED nip65 ${nip65.pubKey} took ${duration.inMilliseconds} ms");
  }

  Nip65? loadNip65(String pubKey) {
    return isar.nip65s.get(pubKey);
  }

  Future<void> saveNip02ContactList(Nip02ContactList contactList) async {
    final startTime = DateTime.now();
    await isar.writeAsync((isar) {
      isar.nip02ContactLists.put(contactList);
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print("SAVED nip02ContactList ${contactList.pubKey} took ${duration.inMilliseconds} ms");
  }

  Nip02ContactList? loadNip02ContactList(String pubKey) {
    return isar.nip02ContactLists.get(pubKey);
  }
}
