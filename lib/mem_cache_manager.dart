import 'dart:core';

import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';

import 'models/relay_set.dart';
import 'models/user_relay_list.dart';
import 'nips/nip01/metadata.dart';
import 'nips/nip05/nip05.dart';

class MemCacheManager implements CacheManager {

  Map<String, UserRelayList> userRelayLists = {};
  Map<String, RelaySet> relaySets = {};
  Map<String, ContactList> contactLists = {};
  Map<String, Metadata> metadatas = {};
  Map<String, Nip05> nip05s = {};
  Map<String, Nip01Event> events = {};

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    userRelayLists[userRelayList.pubKey] = userRelayList;
  }

  @override
  UserRelayList? loadUserRelayList(String pubKey) {
    return userRelayLists[pubKey];
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    for (var userRelayList in userRelayLists) {
      this.userRelayLists[userRelayList.pubKey] = userRelayList;
    }
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    userRelayLists.clear();
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    userRelayLists.remove(pubKey);
  }

  /*****************************************************************************/

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    nip05s[nip05.pubKey] = nip05;
  }

  @override
  Nip05? loadNip05(String pubKey) {
    return nip05s[pubKey];
  }
  @override
  List<Nip05?> loadNip05s(List<String> pubKeys) {
    List<Nip05> result = [];
    for(String pubKey in pubKeys) {
      Nip05? nip05 = nip05s[pubKey];
      if (nip05!=null) {
        result.add(nip05);
      }
    }
    return result;
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    for (var nip05 in nip05s) {
      this.nip05s[nip05.pubKey] = nip05;
    }
  }

  @override
  Future<void> removeAllNip05s() async {
    nip05s.clear();
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    nip05s.remove(pubKey);
  }

  /*****************************************************************************/
  
  @override
  RelaySet? loadRelaySet(String name, String pubKey) {
    return relaySets[RelaySet.buildId(name,pubKey)];
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    relaySets[relaySet.id] = relaySet;
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

  @override
  Iterable<Metadata> searchMetadatas(String search, int limit) {
    /// TODO
    return [];
  }

  @override
  Nip01Event? loadEvent(String id) {
    // TODO: implement loadEvent
    return null;
  }

  @override
  List<Nip01Event> loadEvents({List<String>? pubKeys, List<int>? kinds, String? pTag}) {
    // TODO: implement saveEvents
    return [];
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    // TODO: implement saveEvents
  }

  @override
  Future<void> removeAllEvents() async {
    // TODO: implement removeAllEvents
  }

  @override
  Future<void> removeEvent(String id) async {
    // TODO: implement removeEvent
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    // TODO: implement saveEvent
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    // TODO: implement saveEvents
  }
}
