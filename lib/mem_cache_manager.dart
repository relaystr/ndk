import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/db/user_contacts.dart';
import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/db/relay_set.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'db/user_metadata.dart';

class MemCacheManager implements CacheManager {

  Map<String, UserRelayList> userRelayLists = {};
  Map<String, RelaySet> relaySets = {};
  Map<String, UserContacts> userContacts = {};
  Map<String, UserMetadata> userMetadatas = {};

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

  @override
  Future<void> saveManyUserContacts(List<UserContacts> list) async {
    for (var userContacts in list) {
      this.userContacts[userContacts.pubKey] = userContacts;
    }
  }

  @override
  UserMetadata? loadUserMetadata(String pubKey) {
    return userMetadatas[pubKey];
  }

  @override
  Future<void> saveUserMetadata(UserMetadata metadata) async {
    userMetadatas[metadata.pubKey] = metadata;
  }

  @override
  Future<void> saveUserMetadatas(List<UserMetadata> list) async {
    for (var metadata in list) {
      this.userMetadatas[metadata.pubKey] = metadata;
    }
  }

  @override
  Future<void> removeAllRelaySets() async {
    relaySets.clear();
  }

  @override
  Future<void> removeAllUserContacts() async {
    userContacts.clear();
  }

  @override
  Future<void> removeAllUserMetadatas() async {
    userMetadatas.clear();
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    userRelayLists.clear();
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    relaySets.remove(RelaySet.buildId(name, pubKey));
  }

  @override
  Future<void> removeUserContacts(String pubKey) async {
    userContacts.remove(pubKey);
  }

  @override
  Future<void> removeUserMetadata(String pubKey) async {
    userMetadatas.remove(pubKey);
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    userRelayLists.remove(pubKey);
  }

  @override
  List<UserMetadata?> loadUserMetadatas(List<String> pubKeys) {
    List<UserMetadata> result = [];
    for(String pubKey in pubKeys) {
      UserMetadata? metadata = userMetadatas[pubKey];
      if (metadata!=null) {
        result.add(metadata);
      }
    }
    return result;
  }
}
