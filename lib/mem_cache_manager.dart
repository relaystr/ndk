import 'dart:core';
import 'dart:io';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/db/db_contact_list.dart';
import 'package:dart_ndk/db/user_relay_list.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/db/db_relay_set.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'db/db_metadata.dart';
import 'models/relay_set.dart';
import 'nips/nip01/metadata.dart';

class MemCacheManager implements CacheManager {

  Map<String, UserRelayList> userRelayLists = {};
  Map<String, RelaySet> relaySets = {};
  Map<String, ContactList> contactLists = {};
  Map<String, Metadata> metadatas = {};

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
  ContactList? loadContactList(String pubKey) {
    return contactLists[pubKey];
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    this.contactLists[contactList.pubKey] = contactList;
  }

  @override
  Future<void> saveContactLists(List<ContactList> list) async {
    for (var contactList in list) {
      this.contactLists[contactList.pubKey] = contactList;
    }
  }

  @override
  Metadata? loadMetadata(String pubKey) {
    return metadatas[pubKey];
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    metadatas[metadata.pubKey] = metadata;
  }

  @override
  Future<void> saveMetadatas(List<Metadata> list) async {
    for (var metadata in list) {
      metadatas[metadata.pubKey] = metadata;
    }
  }

  @override
  Future<void> removeAllRelaySets() async {
    relaySets.clear();
  }

  @override
  Future<void> removeAllContactLists() async {
    contactLists.clear();
  }

  @override
  Future<void> removeAllMetadatas() async {
    metadatas.clear();
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
  Future<void> removeContactList(String pubKey) async {
    contactLists.remove(pubKey);
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    metadatas.remove(pubKey);
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    userRelayLists.remove(pubKey);
  }

  @override
  List<Metadata?> loadMetadatas(List<String> pubKeys) {
    List<Metadata> result = [];
    for(String pubKey in pubKeys) {
      Metadata? metadata = metadatas[pubKey];
      if (metadata!=null) {
        result.add(metadata);
      }
    }
    return result;
  }
}
