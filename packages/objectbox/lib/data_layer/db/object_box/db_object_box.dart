import 'dart:async';

import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../../../objectbox.g.dart';
import 'db_init_object_box.dart';
import 'schema/db_contact_list.dart';
import 'schema/db_metadata.dart';
import 'schema/db_nip_01_event.dart';
import 'schema/db_nip_05.dart';
import 'schema/db_relay_set.dart';
import 'schema/db_user_relay_list.dart';

class DbObjectBox implements CacheManager {
  final Completer _initCompleter = Completer();
  Future get dbRdy => _initCompleter.future;
  late ObjectBoxInit _objectBox;

  /// crates objectbox db instace
  /// [attach] to attach to already open instance (e.g. for isolates)
  /// [directory] optional custom directory for the database (useful for testing)
  DbObjectBox({bool attach = false, String? directory}) {
    _init(attach, directory);
  }

  Future _init(bool attach, String? directory) async {
    final objectbox;
    if (attach) {
      objectbox = await ObjectBoxInit.attach(directory: directory);
    } else {
      objectbox = await ObjectBoxInit.create(directory: directory);
    }

    _objectBox = objectbox;
    _initCompleter.complete();
  }

  close() async {
    _objectBox.store.close();
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    final existingContact = contactListBox
        .query(DbContactList_.pubKey.equals(pubKey))
        .order(DbContactList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingContact == null) {
      return null;
    }
    return existingContact.toNdk();
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final existingEvent =
        eventBox.query(DbNip01Event_.nostrId.equals(id)).build().findFirst();
    if (existingEvent == null) {
      return null;
    }
    return existingEvent.toNdk();
  }

  @override
  Future<List<Nip01Event>> loadEvents({
    List<String>? pubKeys,
    List<int>? kinds,
    String? pTag,
    int? since,
    int? until,
    int? limit,
  }) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    QueryBuilder<DbNip01Event> query;

    // Build condition based on available filters
    Condition<DbNip01Event>? condition;

    if (pubKeys != null && pubKeys.isNotEmpty) {
      condition = DbNip01Event_.pubKey.oneOf(pubKeys);
    }

    if (kinds != null && kinds.isNotEmpty) {
      final kindsCondition = DbNip01Event_.kind.oneOf(kinds);
      condition = condition != null
          ? condition.and(kindsCondition)
          : kindsCondition;
    }

    if (since != null) {
      final sinceCondition = DbNip01Event_.createdAt.greaterOrEqual(since);
      condition = condition != null
          ? condition.and(sinceCondition)
          : sinceCondition;
    }

    if (until != null) {
      final untilCondition = DbNip01Event_.createdAt.lessOrEqual(until);
      condition = condition != null
          ? condition.and(untilCondition)
          : untilCondition;
    }

    // Build query with or without conditions
    if (condition != null) {
      query = eventBox.query(condition);
    } else {
      query = eventBox.query();
    }

    query = query.order(DbNip01Event_.createdAt, flags: Order.descending);

    final Query<DbNip01Event> dbQuery;

    // apply limit
    if (limit != null && limit > 0) {
      dbQuery = query.build()..limit = limit;
    } else {
      dbQuery = query.build();
    }

    List<DbNip01Event> foundDb = dbQuery.find();

    // Filter by pTag in memory (ObjectBox doesn't support array element queries)
    final foundValid = foundDb.where((event) {
      if (pTag != null && !event.pTags.contains(pTag)) {
        return false;
      }
      return true;
    }).toList();

    // Apply limit after filtering
    final limitedResults = limit != null && limit > 0
        ? foundValid.take(limit).toList()
        : foundValid;

    return limitedResults.map((dbEvent) => dbEvent.toNdk()).toList();
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadata = metadataBox
        .query(DbMetadata_.pubKey.equals(pubKey))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingMetadata == null) {
      return null;
    }
    return existingMetadata.toNdk();
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadatas = metadataBox
        .query(DbMetadata_.pubKey.oneOf(pubKeys))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .find();

    // Create a map for quick lookup
    final metadataMap = <String, Metadata>{};
    for (final dbMetadata in existingMetadatas) {
      // Only keep the first (most recent) entry per pubKey
      if (!metadataMap.containsKey(dbMetadata.pubKey)) {
        metadataMap[dbMetadata.pubKey] = dbMetadata.toNdk();
      }
    }

    // Return list in the same order as input, with null for not found
    return pubKeys.map((pubKey) => metadataMap[pubKey]).toList();
  }

  @override
  Future<void> removeAllContactLists() async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    contactListBox.removeAll();
  }

  @override
  Future<void> removeAllEvents() async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.removeAll();
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final events =
        eventBox.query(DbNip01Event_.pubKey.equals(pubKey)).build().find();
    eventBox.removeMany(events.map((e) => e.dbId).toList());
  }

  @override
  Future<void> removeAllMetadatas() async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    metadataBox.removeAll();
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    final existingContact = contactListBox
        .query(DbContactList_.pubKey.equals(contactList.pubKey))
        .order(DbContactList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingContact != null) {
      contactListBox.remove(existingContact.dbId);
    }
    contactListBox.put(DbContactList.fromNdk(contactList));
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    contactListBox
        .putMany(contactLists.map((cl) => DbContactList.fromNdk(cl)).toList());
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final existingEvent = eventBox
        .query(DbNip01Event_.nostrId.equals(event.id))
        .build()
        .findFirst();
    if (existingEvent != null) {
      eventBox.remove(existingEvent.dbId);
    }
    eventBox.put(DbNip01Event.fromNdk(event));
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.putMany(events.map((e) => DbNip01Event.fromNdk(e)).toList());
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadatas = metadataBox
        .query(DbMetadata_.pubKey.equals(metadata.pubKey))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .find();
    if (existingMetadatas.length > 1) {
      metadataBox.removeMany(existingMetadatas.map((e) => e.dbId).toList());
    }
    if (existingMetadatas.isNotEmpty &&
        metadata.updatedAt! < existingMetadatas[0].updatedAt!) {
      return;
    }
    metadataBox.put(DbMetadata.fromNdk(metadata));
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await dbRdy;
    for (final metadata in metadatas) {
      await saveMetadata(metadata);
    }
  }

  @override
  Future<Nip05?> loadNip05(String pubKey) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.equals(pubKey))
        .order(DbNip05_.networkFetchTime, flags: Order.descending)
        .build()
        .findFirst();
    if (existing == null) {
      return null;
    }
    return existing.toNdk();
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.oneOf(pubKeys))
        .order(DbNip05_.networkFetchTime, flags: Order.descending)
        .build()
        .find();

    // Create a map for quick lookup
    final nip05Map = <String, Nip05>{};
    for (final dbNip05 in existing) {
      // Only keep the first (most recent) entry per pubKey
      if (!nip05Map.containsKey(dbNip05.pubKey)) {
        nip05Map[dbNip05.pubKey] = dbNip05.toNdk();
      }
    }

    // Return list in the same order as input, with null for not found
    return pubKeys.map((pubKey) => nip05Map[pubKey]).toList();
  }

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    await dbRdy;
    final box = _objectBox.store.box<DbRelaySet>();
    final id = RelaySet.buildId(name, pubKey);
    final existing = box.query(DbRelaySet_.id.equals(id)).build().findFirst();
    if (existing == null) {
      return null;
    }
    return existing.toNdk();
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    await dbRdy;
    final userRelayListBox = _objectBox.store.box<DbUserRelayList>();
    final existingUserRelayList = userRelayListBox
        .query(DbUserRelayList_.pubKey.equals(pubKey))
        .order(DbUserRelayList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingUserRelayList == null) {
      return null;
    }
    return existingUserRelayList.toNdk();
  }

  @override
  Future<void> removeAllNip05s() async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    box.removeAll();
  }

  @override
  Future<void> removeAllRelaySets() async {
    await dbRdy;
    final box = _objectBox.store.box<DbRelaySet>();
    box.removeAll();
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    await dbRdy;
    final userRelayListBox = _objectBox.store.box<DbUserRelayList>();
    userRelayListBox.removeAll();
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    final existingContact = contactListBox
        .query(DbContactList_.pubKey.equals(pubKey))
        .build()
        .findFirst();
    if (existingContact != null) {
      contactListBox.remove(existingContact.dbId);
    }
  }

  @override
  Future<void> removeEvent(String id) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final existingEvent =
        eventBox.query(DbNip01Event_.nostrId.equals(id)).build().findFirst();
    if (existingEvent != null) {
      eventBox.remove(existingEvent.dbId);
    }
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadata = metadataBox
        .query(DbMetadata_.pubKey.equals(pubKey))
        .build()
        .findFirst();
    if (existingMetadata != null) {
      metadataBox.remove(existingMetadata.dbId);
    }
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box.query(DbNip05_.pubKey.equals(pubKey)).build().find();
    if (existing.isNotEmpty) {
      box.removeMany(existing.map((e) => e.dbId).toList());
    }
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    await dbRdy;
    final box = _objectBox.store.box<DbRelaySet>();
    final id = RelaySet.buildId(name, pubKey);
    final existing = box.query(DbRelaySet_.id.equals(id)).build().findFirst();
    if (existing != null) {
      box.remove(existing.dbId);
    }
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    await dbRdy;
    final userRelayListBox = _objectBox.store.box<DbUserRelayList>();
    final existingUserRelayList = userRelayListBox
        .query(DbUserRelayList_.pubKey.equals(pubKey))
        .build()
        .findFirst();
    if (existingUserRelayList != null) {
      userRelayListBox.remove(existingUserRelayList.dbId);
    }
  }

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.equals(nip05.pubKey))
        .order(DbNip05_.networkFetchTime, flags: Order.descending)
        .build()
        .find();
    if (existing.length > 1) {
      box.removeMany(existing.map((e) => e.dbId).toList());
    }
    if (existing.isNotEmpty &&
        nip05.networkFetchTime! < existing[0].networkFetchTime!) {
      return;
    }
    box.put(DbNip05.fromNdk(nip05));
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    await dbRdy;
    for (final nip05 in nip05s) {
      await saveNip05(nip05);
    }
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    await dbRdy;
    final box = _objectBox.store.box<DbRelaySet>();
    final id = RelaySet.buildId(relaySet.name, relaySet.pubKey);
    final existing = box.query(DbRelaySet_.id.equals(id)).build().findFirst();
    if (existing != null) {
      box.remove(existing.dbId);
    }
    box.put(DbRelaySet.fromNdk(relaySet));
  }

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    await dbRdy;
    final userRelayListBox = _objectBox.store.box<DbUserRelayList>();
    final existingUserRelayList = userRelayListBox
        .query(DbUserRelayList_.pubKey.equals(userRelayList.pubKey))
        .order(DbUserRelayList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingUserRelayList != null) {
      userRelayListBox.remove(existingUserRelayList.dbId);
    }
    userRelayListBox.put(DbUserRelayList.fromNdk(userRelayList));
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    final wait = <Future>[];
    for (final userRelayList in userRelayLists) {
      wait.add(saveUserRelayList(userRelayList));
    }
    await Future.wait(wait);
  }

  // Search by name, nip05
  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();

    // Create a query with OR condition
    final query = metadataBox
        .query(DbMetadata_.splitNameWords
            .containsElement(search, caseSensitive: false)
            .or(DbMetadata_.name
                .startsWith(search, caseSensitive: false)
                .or(DbMetadata_.splitDisplayNameWords
                    .containsElement(search, caseSensitive: false))
                .or(DbMetadata_.displayName
                    .startsWith(search, caseSensitive: false))
                .or(DbMetadata_.nip05
                    .startsWith(search, caseSensitive: false))))
        .order(DbMetadata_.name, flags: Order.descending)
        .build();
    query..limit = limit;
    final results = query.find();

    return results.map((dbMetadata) => dbMetadata.toNdk()).take(limit);
  }

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
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();

    // Build conditions
    Condition<DbNip01Event>? condition;

    // Add search condition if provided (NIP-50)
    if (search != null && search.isNotEmpty) {
      condition = DbNip01Event_.content.contains(search, caseSensitive: false);
    }

    // Add ids filter
    if (ids != null && ids.isNotEmpty) {
      Condition<DbNip01Event> idsCondition = DbNip01Event_.nostrId.oneOf(ids);
      condition =
          (condition == null) ? idsCondition : condition.and(idsCondition);
    }

    // Add authors filter
    if (authors != null && authors.isNotEmpty) {
      Condition<DbNip01Event> authorsCondition =
          DbNip01Event_.pubKey.oneOf(authors);
      condition = (condition == null)
          ? authorsCondition
          : condition.and(authorsCondition);
    }

    // Add kinds filter
    if (kinds != null && kinds.isNotEmpty) {
      Condition<DbNip01Event> kindsCondition = DbNip01Event_.kind.oneOf(kinds);
      condition =
          (condition == null) ? kindsCondition : condition.and(kindsCondition);
    }

    // Add since filter
    if (since != null) {
      Condition<DbNip01Event> sinceCondition =
          DbNip01Event_.createdAt.greaterOrEqual(since);
      condition =
          (condition == null) ? sinceCondition : condition.and(sinceCondition);
    }

    // Add until filter
    if (until != null) {
      Condition<DbNip01Event> untilCondition =
          DbNip01Event_.createdAt.lessOrEqual(until);
      condition =
          (condition == null) ? untilCondition : condition.and(untilCondition);
    }

    // Create and build the query
    QueryBuilder<DbNip01Event> queryBuilder;
    if (condition != null) {
      queryBuilder = eventBox.query(condition);
    } else {
      queryBuilder = eventBox.query();
    }

    // Apply sorting
    queryBuilder.order(DbNip01Event_.createdAt, flags: Order.descending);

    // Build and execute the query
    final query = queryBuilder.build();
    query..limit = limit;
    final results = query.find();

    // For tag filtering, we need to do it in memory since ObjectBox doesn't support
    // complex JSON querying within arrays
    List<DbNip01Event> filteredResults = results;

    // Apply tag filters in memory if needed
    if (tags != null && tags.isNotEmpty) {
      filteredResults = results.where((event) {
        // Check if the event matches all tag filters
        return tags.entries.every((tagEntry) {
          String tagKey = tagEntry.key;
          List<String> tagValues = tagEntry.value;

          // Handle the special case where tag key starts with '#'
          if (tagKey.startsWith('#') && tagKey.length > 1) {
            tagKey = tagKey.substring(1); // Remove the '#' prefix
          }

          // Get all tags with this key
          List<DbTag> eventTags =
              event.tags.where((t) => t.key == tagKey).toList();

          // Check if any of the event's tags with this key have a value in the requested values
          return eventTags.any((tag) =>
              tagValues.contains(tag.value) ||
              tagValues.contains(tag.value.toLowerCase()));
        });
      }).toList();
    }

    return filteredResults.map((dbEvent) => dbEvent.toNdk()).take(limit);
  }
}
