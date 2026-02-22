import 'dart:core';

import '../../../domain_layer/entities/contact_list.dart';
import '../../../domain_layer/entities/filter_fetched_ranges.dart';
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

  /// In memory storage indexed by pubKey
  Map<String, Nip05> nip05s = {};

  /// In memory storage indexed by nip05 identifier
  Map<String, Nip05> nip05sByIdentifier = {};

  /// In memory storage
  Map<String, Nip01Event> events = {};

  /// In memory storage for filter fetched range records
  /// Key is filterHash:relayUrl:rangeStart
  Map<String, FilterFetchedRangeRecord> filterFetchedRangeRecords = {};

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
    nip05sByIdentifier[nip05.nip05] = nip05;
  }

  @override
  Future<Nip05?> loadNip05({String? pubKey, String? identifier}) async {
    if (pubKey != null) {
      return nip05s[pubKey];
    }
    if (identifier != null) {
      return nip05sByIdentifier[identifier];
    }
    return null;
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    List<Nip05?> result = [];
    for (String pubKey in pubKeys) {
      result.add(nip05s[pubKey]);
    }
    return result;
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    for (var nip05 in nip05s) {
      this.nip05s[nip05.pubKey] = nip05;
      nip05sByIdentifier[nip05.nip05] = nip05;
    }
  }

  @override
  Future<void> removeAllNip05s() async {
    nip05s.clear();
    nip05sByIdentifier.clear();
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    final nip05 = nip05s[pubKey];
    if (nip05 != null) {
      nip05sByIdentifier.remove(nip05.nip05);
    }
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
    List<Metadata?> result = [];
    for (String pubKey in pubKeys) {
      result.add(metadatas[pubKey]);
    }
    return result;
  }

  /// Search for metadata by name, nip05
  @override
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
  @Deprecated('Use loadEvents() instead')
  Future<Iterable<Nip01Event>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 100,
  }) async {
    return loadEvents(
      ids: ids,
      pubKeys: authors,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
      limit: limit,
    );
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    return events[id];
  }

  @override
  Future<List<Nip01Event>> loadEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
  }) async {
    List<Nip01Event> result = [];
    for (var event in events.values) {
      // Filter by ids
      if (ids != null && ids.isNotEmpty && !ids.contains(event.id)) {
        continue;
      }
      // Filter by pubKeys
      if (pubKeys != null &&
          pubKeys.isNotEmpty &&
          !pubKeys.contains(event.pubKey)) {
        continue;
      }
      // Filter by kinds
      if (kinds != null && kinds.isNotEmpty && !kinds.contains(event.kind)) {
        continue;
      }
      // Filter by time range
      if (since != null && event.createdAt < since) {
        continue;
      }
      if (until != null && event.createdAt > until) {
        continue;
      }
      // Filter by search in content
      if (search != null && search.isNotEmpty) {
        if (!event.content.toLowerCase().contains(search.toLowerCase())) {
          continue;
        }
      }
      // Filter by tags
      if (tags != null && tags.isNotEmpty) {
        bool matchesTags = tags.entries.every((tagEntry) {
          String tagKey = tagEntry.key;
          List<String> tagValues = tagEntry.value;

          // Handle the special case where tag key starts with '#'
          if (tagKey.startsWith('#') && tagKey.length > 1) {
            tagKey = tagKey.substring(1);
          }

          final eventTagValues = event.getTags(tagKey);

          if (tagValues.isEmpty &&
              event.tags.where((e) => e[0] == tagKey).isNotEmpty) {
            return true;
          }

          return tagValues.any((value) =>
              eventTagValues.contains(value) ||
              eventTagValues.contains(value.toLowerCase()));
        });
        if (!matchesTags) {
          continue;
        }
      }

      result.add(event);
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && limit > 0 && result.length > limit) {
      result = result.take(limit).toList();
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
  Future<void> removeEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
  }) async {
    // If all parameters are empty, return early (don't delete everything)
    if ((ids == null || ids.isEmpty) &&
        (pubKeys == null || pubKeys.isEmpty) &&
        (kinds == null || kinds.isEmpty) &&
        (tags == null || tags.isEmpty) &&
        since == null &&
        until == null) {
      return;
    }

    final eventsToRemove = await loadEvents(
      ids: ids,
      pubKeys: pubKeys,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
    );
    for (final event in eventsToRemove) {
      events.remove(event.id);
    }
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

  @override
  Future<void> close() async {
    return;
  }

  // =====================
  // Filter Fetched Ranges
  // =====================

  @override
  Future<void> saveFilterFetchedRangeRecord(
      FilterFetchedRangeRecord record) async {
    filterFetchedRangeRecords[record.key] = record;
  }

  @override
  Future<void> saveFilterFetchedRangeRecords(
      List<FilterFetchedRangeRecord> records) async {
    for (final record in records) {
      filterFetchedRangeRecords[record.key] = record;
    }
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
      String filterHash) async {
    return filterFetchedRangeRecords.values
        .where((r) => r.filterHash == filterHash)
        .toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
      String filterHash, String relayUrl) async {
    return filterFetchedRangeRecords.values
        .where((r) => r.filterHash == filterHash && r.relayUrl == relayUrl)
        .toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>>
      loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl) async {
    return filterFetchedRangeRecords.values
        .where((r) => r.relayUrl == relayUrl)
        .toList();
  }

  @override
  Future<void> removeFilterFetchedRangeRecords(String filterHash) async {
    filterFetchedRangeRecords
        .removeWhere((key, value) => value.filterHash == filterHash);
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
      String filterHash, String relayUrl) async {
    filterFetchedRangeRecords.removeWhere((key, value) =>
        value.filterHash == filterHash && value.relayUrl == relayUrl);
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl) async {
    filterFetchedRangeRecords
        .removeWhere((key, value) => value.relayUrl == relayUrl);
  }

  @override
  Future<void> removeAllFilterFetchedRangeRecords() async {
    filterFetchedRangeRecords.clear();
  }

  @override
  Future<void> clearAll() async {
    events.clear();
    userRelayLists.clear();
    relaySets.clear();
    contactLists.clear();
    metadatas.clear();
    nip05s.clear();
    nip05sByIdentifier.clear();
    filterFetchedRangeRecords.clear();
  }
}
