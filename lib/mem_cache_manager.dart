import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/db/user_contacts.dart';
import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/db/relay_set.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

class MemCacheManager implements CacheManager {

  Map<String, UserRelayList> userRelayLists = {};
  Map<String, RelaySet> relaySets = {};
  Map<String, UserContacts> userContacts = {};

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    userRelayLists[userRelayList.id] = userRelayList;
  }

  @override
  UserRelayList? loadUserRelayList(String pubKey) {
    return userRelayLists[pubKey];
  }

  @override
  RelaySet? loadRelaySet(String name, String pubKey) {
    return relaySets[RelaySet.buildId(name,pubKey)];
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    relaySets[relaySet.id] = relaySet;
  }


  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    for (var userRelayList in userRelayLists) {
      this.userRelayLists[userRelayList.id] = userRelayList;
    }
  }

  @override
  UserContacts? loadUserContacts(String pubKey) {
    return userContacts[pubKey];
  }

  @override
  Future<void> saveUserContacts(UserContacts userContacts) async {
    this.userContacts[userContacts.pubKey] = userContacts;
  }
}
