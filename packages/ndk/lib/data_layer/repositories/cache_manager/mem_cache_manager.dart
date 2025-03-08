import 'dart:core';

import '../../../domain_layer/entities/contact_list.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/nip_05.dart';
import '../../../domain_layer/entities/relay_set.dart';
import '../../../domain_layer/entities/user_relay_list.dart';
import '../../../domain_layer/entities/metadata.dart';
import '../../../domain_layer/repositories/cache_manager.dart';

/// In memory database implementation
/// benefits: very fast
/// drawbacks: does not persist
class MemCacheManager implements CacheManager {
  /// In memory storage
  Map<String, UserRelayList> userRelayLists = {};

  /// In memory storage
  Map<String, RelaySet> relaySets = {};

  /// In memory storage
  Map<String, ContactList> contactLists = {};

  /// In memory storage
  Map<String, Metadata> metadatas = {};

  /// In memory storage
  Map<String, Nip05> nip05s = {};

  /// In memory storage
  Map<String, Nip01Event> events = {};

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    userRelayLists[userRelayList.pubKey] = userRelayList;
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
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

  /// **************************************************************************

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    nip05s[nip05.pubKey] = nip05;
  }

  @override
  Future<Nip05?> loadNip05(String pubKey) async {
    return nip05s[pubKey];
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    List<Nip05> result = [];
    for (String pubKey in pubKeys) {
      Nip05? nip05 = nip05s[pubKey];
      if (nip05 != null) {
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

  /// **************************************************************************

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    return relaySets[RelaySet.buildId(name, pubKey)];
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    relaySets[relaySet.id] = relaySet;
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    return contactLists[pubKey];
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    contactLists[contactList.pubKey] = contactList;
  }

  @override
  Future<void> saveContactLists(List<ContactList> list) async {
    for (var contactList in list) {
      contactLists[contactList.pubKey] = contactList;
    }
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
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
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    List<Metadata> result = [];
    for (String pubKey in pubKeys) {
      Metadata? metadata = metadatas[pubKey];
      if (metadata != null) {
        result.add(metadata);
      }
    }
    return result;
  }

  @override

  /// Search for metadata by name, nip05
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    // Use a Set to track unique Metadata objects
    final Set<Metadata> uniqueResults = {};

    for (final metadata in metadatas.values) {
      if ((metadata.name != null && metadata.name!.contains(search)) ||
          (metadata.nip05 != null && metadata.nip05!.contains(search))) {
        uniqueResults.add(metadata);
      }
    }

    // Convert to list, sort by updatedAt, and take the limit
    final sortedResults = uniqueResults.toList()
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    return sortedResults.take(limit);
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    return events[id];
  }

  @override
  Future<List<Nip01Event>> loadEvents({
    List<String>? pubKeys,
    List<int>? kinds,
    String? pTag,
    int? since,
    int? until,
  }) async {
    List<Nip01Event> result = [];
    for (var event in events.values) {
      if (pubKeys != null && !pubKeys.contains(event.pubKey)) {
        continue;
      }
      if (kinds != null && !kinds.contains(event.kind)) {
        continue;
      }
      if (pTag != null && !event.pTags.contains(pTag)) {
        continue;
      }

      if (since != null && event.createdAt < since) {
        continue;
      }

      if (until != null && event.createdAt > until) {
        continue;
      }

      result.add(event);
    }
    return result;
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    events.removeWhere((key, value) => value.pubKey == pubKey);
  }

  @override
  Future<void> removeAllEvents() async {
    events.clear();
  }

  @override
  Future<void> removeEvent(String id) async {
    events.remove(id);
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    events[event.id] = event;
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    for (var event in events) {
      this.events[event.id] = event;
    }
  }
}
