import 'dart:core';

import 'package:isar/isar.dart';
import 'package:ndk/domain_layer/entities/filter_fetched_ranges.dart';
import 'package:ndk/domain_layer/repositories/cache_manager.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/shared/logger/logger.dart';

import '../../data_sources/isar_db.dart';
import '../../models/db/db_contact_list.dart';
import '../../models/db/db_event.dart';
import '../../models/db/db_filter_fetched_range_record.dart';
import '../../models/db/db_metadata.dart';
import '../../models/db/db_nip05.dart';
import '../../models/db/db_relay_set.dart';
import '../../models/db/db_user_relay_list.dart';

class IsarCacheManager extends CacheManager {
  late IsarDbDs isar_ds;
  EventFilter? eventFilter;

  IsarCacheManager({IsarDbDs? isar_ds, String? dbDir}) {
    this.isar_ds = isar_ds ?? IsarDbDs();
  }

  Future<void> init({String? directory}) async {
    await isar_ds.init(directory: directory);
  }

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbUserRelayLists
          .put(DbUserRelayList.fromUserRelayList(userRelayList));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED UserRelayList ${userRelayList.pubKey} took ${duration.inMilliseconds} ms");
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    return isar_ds.isar.dbUserRelayLists.get(pubKey);
  }

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    return isar_ds.isar.dbRelaySets.get(RelaySet.buildId(name, pubKey));
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbRelaySets.put(DbRelaySet.fromRelaySet(relaySet));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED relaySet ${relaySet.name}+${relaySet.pubKey} took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbUserRelayLists.putAll(userRelayLists
          .map(
            (e) => DbUserRelayList.fromUserRelayList(e),
          )
          .toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED ${userRelayLists.length} UserRelayLists took ${duration.inMilliseconds} ms");
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    return isar_ds.isar.dbContactLists.get(pubKey);
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbContactLists.put(DbContactList.fromContactList(contactList));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED ${contactList.pubKey} ContacList took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbContactLists.putAll(
          contactLists.map((e) => DbContactList.fromContactList(e)).toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED ${contactLists.length} ContactLists took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> removeAllRelaySets() async {
    isar_ds.isar.write((isar) {
      isar.dbRelaySets.clear();
    });
  }

  @override
  Future<void> removeAllContactLists() async {
    isar_ds.isar.write((isar) {
      isar.dbContactLists.clear();
    });
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    isar_ds.isar.write((isar) {
      isar.dbUserRelayLists.clear();
    });
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    isar_ds.isar.write((isar) {
      isar.dbRelaySets.delete(RelaySet.buildId(name, pubKey));
    });
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    isar_ds.isar.write((isar) {
      isar.dbContactLists.delete(pubKey);
    });
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    isar_ds.isar.write((isar) {
      isar.dbUserRelayLists.delete(pubKey);
    });
  }

  /// *********************************************************************************************

  @override
  Future<void> removeMetadata(String pubKey) async {
    isar_ds.isar.write((isar) {
      isar.dbMetadatas.delete(pubKey);
    });
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbMetadatas.put(DbMetadata.fromMetadata(metadata));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t("SAVED Metadata took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbMetadatas.putAll(metadatas
          .map((metadata) => DbMetadata.fromMetadata(metadata))
          .toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED ${metadatas.length} UserMetadatas took ${duration.inMilliseconds} ms");
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    return isar_ds.isar.dbMetadatas.get(pubKey);
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    return isar_ds.isar.dbMetadatas.getAll(pubKeys);
  }

  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    return isar_ds.isar.dbMetadatas
        .where()
        .splitDisplayNameWordsElementStartsWith(search)
        .or()
        .splitNameWordsElementStartsWith(search)
        .findAll()
        .take(limit);
  }

  @override
  Future<void> removeAllMetadatas() async {
    isar_ds.isar.write((isar) {
      isar.dbMetadatas.clear();
    });
  }

  /// *********************************************************************************************

  @override
  Future<void> removeNip05(String pubKey) async {
    isar_ds.isar.write((isar) {
      isar.dbNip05s.delete(pubKey);
    });
  }

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbNip05s.put(DbNip05.fromNip05(nip05));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t("SAVED Nip05 took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbNip05s
          .putAll(nip05s.map((nip05) => DbNip05.fromNip05(nip05)).toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED ${nip05s.length} UserNip05s took ${duration.inMilliseconds} ms");
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    return isar_ds.isar.dbNip05s.getAll(pubKeys);
  }

  @override
  Future<Nip05?> loadNip05(String pubKey) async {
    return isar_ds.isar.dbNip05s.get(pubKey);
  }

  @override
  Future<void> removeAllNip05s() async {
    isar_ds.isar.write((isar) {
      isar.dbNip05s.clear();
    });
  }

  /// *********************************************************************************************

  @override
  Future<void> removeEvent(String id) async {
    isar_ds.isar.write((isar) {
      isar.dbEvents.delete(id);
    });
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbEvents.put(DbEvent.fromNip01Event(event));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t("SAVED Event took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbEvents.putAll(
          events.map((event) => DbEvent.fromNip01Event(event)).toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log
        .t("SAVED ${events.length} Events took ${duration.inMilliseconds} ms");
  }

  // @override
  // List<Nip01Event> loadEvents(List<String> pubKeys, List<int> kinds) {
  //   List<Nip01Event> events = isar.dbEvents.where()
  //       .optional(kinds!=null && kinds.isNotEmpty, (q) => q.anyOf(kinds, (q, kind) => q.kindEqualTo(kind)))
  //       .and()
  //       .optional(pubKeys!=null && pubKeys.isNotEmpty, (q) => q.anyOf(pubKeys, (q, pubKey) => q.pubKeyEqualTo(pubKey)))
  //       .findAll();
  //   return eventFilter!=null? events.where((event) => eventFilter!.filter(event)).toList() : events;
  // }

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
    List<Nip01Event> events = isar_ds.isar.dbEvents
        .where()
        .optional(ids != null && ids.isNotEmpty,
            (q) => q.anyOf(ids!, (q, id) => q.idEqualTo(id)))
        .and()
        .optional(kinds != null && kinds.isNotEmpty,
            (q) => q.anyOf(kinds!, (q, kind) => q.kindEqualTo(kind)))
        .and()
        .optional(pubKeys != null && pubKeys.isNotEmpty,
            (q) => q.anyOf(pubKeys!, (q, pubKey) => q.pubKeyEqualTo(pubKey)))
        .sortByCreatedAtDesc()
        .findAll(limit: limit);

    // Apply time filters in memory
    if (since != null) {
      events = events.where((event) => event.createdAt >= since).toList();
    }
    if (until != null) {
      events = events.where((event) => event.createdAt <= until).toList();
    }

    // Apply search filter in memory
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      events = events
          .where((event) => event.content.toLowerCase().contains(searchLower))
          .toList();
    }

    // Apply tag filters in memory
    if (tags != null && tags.isNotEmpty) {
      events = events.where((event) {
        return tags.entries.every((tagEntry) {
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
      }).toList();
    }

    // Apply limit after memory filtering
    if (limit != null && limit > 0 && events.length > limit) {
      events = events.take(limit).toList();
    }

    return eventFilter != null
        ? events.where((event) => eventFilter!.filter(event)).toList()
        : events;
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    Nip01Event? event = isar_ds.isar.dbEvents.get(id);
    return event != null &&
            (eventFilter == null || (eventFilter!.filter(event)))
        ? event
        : null;
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    isar_ds.isar.write((isar) {
      isar.dbEvents.where().pubKeyEqualTo(pubKey).deleteAll();
    });
  }

  @override
  Future<void> removeAllEvents() async {
    isar_ds.isar.write((isar) {
      isar.dbEvents.clear();
    });
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
  Future<void> close() async {
    isar_ds.isar.close();
  }

  // =====================
  // Filter Fetched Ranges
  // =====================

  @override
  Future<void> saveFilterFetchedRangeRecord(
      FilterFetchedRangeRecord record) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbFilterFetchedRangeRecords
          .put(DbFilterFetchedRangeRecord.fromFilterFetchedRangeRecord(record));
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED FilterFetchedRangeRecord took ${duration.inMilliseconds} ms");
  }

  @override
  Future<void> saveFilterFetchedRangeRecords(
      List<FilterFetchedRangeRecord> records) async {
    final startTime = DateTime.now();
    isar_ds.isar.write((isar) {
      isar.dbFilterFetchedRangeRecords.putAll(records
          .map((r) => DbFilterFetchedRangeRecord.fromFilterFetchedRangeRecord(r))
          .toList());
    });
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.log.t(
        "SAVED ${records.length} FilterFetchedRangeRecords took ${duration.inMilliseconds} ms");
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
      String filterHash) async {
    return isar_ds.isar.dbFilterFetchedRangeRecords
        .where()
        .filterHashEqualTo(filterHash)
        .findAll()
        .map((r) => r.toFilterFetchedRangeRecord())
        .toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
      String filterHash, String relayUrl) async {
    return isar_ds.isar.dbFilterFetchedRangeRecords
        .where()
        .filterHashEqualTo(filterHash)
        .and()
        .relayUrlEqualTo(relayUrl)
        .findAll()
        .map((r) => r.toFilterFetchedRangeRecord())
        .toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>>
      loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl) async {
    return isar_ds.isar.dbFilterFetchedRangeRecords
        .where()
        .relayUrlEqualTo(relayUrl)
        .findAll()
        .map((r) => r.toFilterFetchedRangeRecord())
        .toList();
  }

  @override
  Future<void> removeFilterFetchedRangeRecords(String filterHash) async {
    isar_ds.isar.write((isar) {
      isar.dbFilterFetchedRangeRecords
          .where()
          .filterHashEqualTo(filterHash)
          .deleteAll();
    });
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
      String filterHash, String relayUrl) async {
    isar_ds.isar.write((isar) {
      isar.dbFilterFetchedRangeRecords
          .where()
          .filterHashEqualTo(filterHash)
          .and()
          .relayUrlEqualTo(relayUrl)
          .deleteAll();
    });
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl) async {
    isar_ds.isar.write((isar) {
      isar.dbFilterFetchedRangeRecords
          .where()
          .relayUrlEqualTo(relayUrl)
          .deleteAll();
    });
  }

  @override
  Future<void> removeAllFilterFetchedRangeRecords() async {
    isar_ds.isar.write((isar) {
      isar.dbFilterFetchedRangeRecords.clear();
    });
  }
}
