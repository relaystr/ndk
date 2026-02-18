import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/pubkey_mapping.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';

import 'database/database.dart';

/// A Drift-based implementation of the CacheManager for NDK.
class DriftCacheManager extends CacheManager {
  final NdkCacheDatabase _db;

  DriftCacheManager(this._db);

  /// Creates a DriftCacheManager with a default database name.
  static Future<DriftCacheManager> create({String? dbName}) async {
    final db = NdkCacheDatabase(dbName: dbName);
    return DriftCacheManager(db);
  }

  @override
  Future<void> close() async {
    await _db.close();
  }

  // =====================
  // Events
  // =====================

  @override
  Future<void> saveEvent(Nip01Event event) async {
    await _db
        .into(_db.events)
        .insertOnConflictUpdate(
          EventsCompanion.insert(
            id: event.id,
            pubKey: event.pubKey,
            kind: event.kind,
            createdAt: event.createdAt,
            content: event.content,
            sig: Value(event.sig),
            validSig: Value(event.validSig),
            tagsJson: jsonEncode(event.tags),
            sourcesJson: jsonEncode(event.sources),
          ),
        );
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.events,
        events
            .map(
              (event) => EventsCompanion.insert(
                id: event.id,
                pubKey: event.pubKey,
                kind: event.kind,
                createdAt: event.createdAt,
                content: event.content,
                sig: Value(event.sig),
                validSig: Value(event.validSig),
                tagsJson: jsonEncode(event.tags),
                sourcesJson: jsonEncode(event.sources),
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    final row = await (_db.select(
      _db.events,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _eventFromRow(row);
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
    var query = _db.select(_db.events);

    // Build WHERE clause
    query = query
      ..where((t) {
        final conditions = <Expression<bool>>[];

        if (ids != null && ids.isNotEmpty) {
          conditions.add(t.id.isIn(ids));
        }

        if (pubKeys != null && pubKeys.isNotEmpty) {
          conditions.add(t.pubKey.isIn(pubKeys));
        }

        if (kinds != null && kinds.isNotEmpty) {
          conditions.add(t.kind.isIn(kinds));
        }

        if (since != null) {
          conditions.add(t.createdAt.isBiggerOrEqualValue(since));
        }

        if (until != null) {
          conditions.add(t.createdAt.isSmallerOrEqualValue(until));
        }

        if (search != null && search.isNotEmpty) {
          conditions.add(t.content.contains(search));
        }

        if (conditions.isEmpty) {
          return const Constant(true);
        }

        return conditions.reduce((a, b) => a & b);
      })
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (limit != null) {
      query = query..limit(limit);
    }

    final rows = await query.get();
    var events = rows.map(_eventFromRow).toList();

    // Filter by tags in memory (Drift doesn't support JSON field queries well)
    if (tags != null && tags.isNotEmpty) {
      events = events.where((event) {
        return tags.entries.every((tagEntry) {
          var tagName = tagEntry.key;
          final tagValues = tagEntry.value;

          // Handle the special case where tag key starts with '#'
          if (tagName.startsWith('#') && tagName.length > 1) {
            tagName = tagName.substring(1);
          }

          final eventTags = event.getTags(tagName);

          if (tagValues.isEmpty &&
              event.tags.where((e) => e[0] == tagName).isNotEmpty) {
            return true;
          }

          return tagValues.any(
            (value) => eventTags.contains(value.toLowerCase()),
          );
        });
      }).toList();
    }

    return events;
  }

  @override
  Future<void> removeEvent(String id) async {
    await (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    await (_db.delete(_db.events)..where((t) => t.pubKey.equals(pubKey))).go();
  }

  @override
  Future<void> removeAllEvents() async {
    await _db.delete(_db.events).go();
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
    final hasNoFilters = (ids == null || ids.isEmpty) &&
        (pubKeys == null || pubKeys.isEmpty) &&
        (kinds == null || kinds.isEmpty) &&
        (tags == null || tags.isEmpty) &&
        since == null &&
        until == null;

    if (hasNoFilters) return;

    // With tags filter, we need to load events first (tags filtered in memory)
    if (tags != null && tags.isNotEmpty) {
      final eventsToRemove = await loadEvents(
        ids: ids,
        pubKeys: pubKeys,
        kinds: kinds,
        tags: tags,
        since: since,
        until: until,
      );

      if (eventsToRemove.isEmpty) return;

      final idsToRemove = eventsToRemove.map((e) => e.id).toList();
      await (_db.delete(_db.events)..where((t) => t.id.isIn(idsToRemove))).go();
      return;
    }

    // No tags filter, delete directly without loading events
    await (_db.delete(_db.events)..where((t) {
      final conditions = <Expression<bool>>[];

      if (ids != null && ids.isNotEmpty) {
        conditions.add(t.id.isIn(ids));
      }
      if (pubKeys != null && pubKeys.isNotEmpty) {
        conditions.add(t.pubKey.isIn(pubKeys));
      }
      if (kinds != null && kinds.isNotEmpty) {
        conditions.add(t.kind.isIn(kinds));
      }
      if (since != null) {
        conditions.add(t.createdAt.isBiggerOrEqualValue(since));
      }
      if (until != null) {
        conditions.add(t.createdAt.isSmallerOrEqualValue(until));
      }

      return conditions.reduce((a, b) => a & b);
    })).go();
  }

  Nip01Event _eventFromRow(DbEvent row) {
    final tags = (jsonDecode(row.tagsJson) as List)
        .map((e) => (e as List).map((item) => item.toString()).toList())
        .toList();
    final sources = (jsonDecode(row.sourcesJson) as List)
        .map((e) => e.toString())
        .toList();

    return Nip01Event(
      id: row.id,
      pubKey: row.pubKey,
      kind: row.kind,
      createdAt: row.createdAt,
      content: row.content,
      sig: row.sig,
      validSig: row.validSig,
      tags: tags,
      sources: sources,
    );
  }

  // =====================
  // Metadata
  // =====================

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await _db
        .into(_db.metadatas)
        .insertOnConflictUpdate(
          MetadatasCompanion.insert(
            pubKey: metadata.pubKey,
            name: Value(metadata.name),
            displayName: Value(metadata.displayName),
            picture: Value(metadata.picture),
            banner: Value(metadata.banner),
            website: Value(metadata.website),
            about: Value(metadata.about),
            nip05: Value(metadata.nip05),
            lud16: Value(metadata.lud16),
            lud06: Value(metadata.lud06),
            updatedAt: Value(metadata.updatedAt),
            refreshedTimestamp: Value(metadata.refreshedTimestamp),
            sourcesJson: jsonEncode(metadata.sources),
          ),
        );
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.metadatas,
        metadatas
            .map(
              (metadata) => MetadatasCompanion.insert(
                pubKey: metadata.pubKey,
                name: Value(metadata.name),
                displayName: Value(metadata.displayName),
                picture: Value(metadata.picture),
                banner: Value(metadata.banner),
                website: Value(metadata.website),
                about: Value(metadata.about),
                nip05: Value(metadata.nip05),
                lud16: Value(metadata.lud16),
                lud06: Value(metadata.lud06),
                updatedAt: Value(metadata.updatedAt),
                refreshedTimestamp: Value(metadata.refreshedTimestamp),
                sourcesJson: jsonEncode(metadata.sources),
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    final row = await (_db.select(
      _db.metadatas,
    )..where((t) => t.pubKey.equals(pubKey))).getSingleOrNull();
    if (row == null) return null;
    return _metadataFromRow(row);
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    final rows = await (_db.select(
      _db.metadatas,
    )..where((t) => t.pubKey.isIn(pubKeys))).get();

    final map = {for (var row in rows) row.pubKey: _metadataFromRow(row)};
    return pubKeys.map((pk) => map[pk]).toList();
  }

  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    final rows =
        await (_db.select(_db.metadatas)
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(limit))
            .get();

    final metadatas = rows.map(_metadataFromRow).toList();

    if (search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      return metadatas.where((metadata) {
        return (metadata.name?.toLowerCase().contains(searchLower) ?? false) ||
            (metadata.displayName?.toLowerCase().contains(searchLower) ??
                false) ||
            (metadata.about?.toLowerCase().contains(searchLower) ?? false) ||
            (metadata.nip05?.toLowerCase().contains(searchLower) ?? false);
      });
    }

    return metadatas;
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    await (_db.delete(
      _db.metadatas,
    )..where((t) => t.pubKey.equals(pubKey))).go();
  }

  @override
  Future<void> removeAllMetadatas() async {
    await _db.delete(_db.metadatas).go();
  }

  Metadata _metadataFromRow(DbMetadata row) {
    final metadata = Metadata(
      pubKey: row.pubKey,
      name: row.name,
      displayName: row.displayName,
      picture: row.picture,
      banner: row.banner,
      website: row.website,
      about: row.about,
      nip05: row.nip05,
      lud16: row.lud16,
      lud06: row.lud06,
      updatedAt: row.updatedAt,
      refreshedTimestamp: row.refreshedTimestamp,
    );
    metadata.sources = (jsonDecode(row.sourcesJson) as List)
        .map((e) => e.toString())
        .toList();
    return metadata;
  }

  // =====================
  // Contact Lists
  // =====================

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await _db
        .into(_db.contactLists)
        .insertOnConflictUpdate(
          ContactListsCompanion.insert(
            pubKey: contactList.pubKey,
            contactsJson: jsonEncode(contactList.contacts),
            contactRelaysJson: jsonEncode(contactList.contactRelays),
            petnamesJson: jsonEncode(contactList.petnames),
            followedTagsJson: jsonEncode(contactList.followedTags),
            followedCommunitiesJson: jsonEncode(
              contactList.followedCommunities,
            ),
            followedEventsJson: jsonEncode(contactList.followedEvents),
            createdAt: contactList.createdAt,
            loadedTimestamp: Value(contactList.loadedTimestamp),
            sourcesJson: jsonEncode(contactList.sources),
          ),
        );
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.contactLists,
        contactLists
            .map(
              (contactList) => ContactListsCompanion.insert(
                pubKey: contactList.pubKey,
                contactsJson: jsonEncode(contactList.contacts),
                contactRelaysJson: jsonEncode(contactList.contactRelays),
                petnamesJson: jsonEncode(contactList.petnames),
                followedTagsJson: jsonEncode(contactList.followedTags),
                followedCommunitiesJson: jsonEncode(
                  contactList.followedCommunities,
                ),
                followedEventsJson: jsonEncode(contactList.followedEvents),
                createdAt: contactList.createdAt,
                loadedTimestamp: Value(contactList.loadedTimestamp),
                sourcesJson: jsonEncode(contactList.sources),
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    final row = await (_db.select(
      _db.contactLists,
    )..where((t) => t.pubKey.equals(pubKey))).getSingleOrNull();
    if (row == null) return null;
    return _contactListFromRow(row);
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    await (_db.delete(
      _db.contactLists,
    )..where((t) => t.pubKey.equals(pubKey))).go();
  }

  @override
  Future<void> removeAllContactLists() async {
    await _db.delete(_db.contactLists).go();
  }

  ContactList _contactListFromRow(DbContactList row) {
    final contactList = ContactList(
      pubKey: row.pubKey,
      contacts: (jsonDecode(row.contactsJson) as List)
          .map((e) => e.toString())
          .toList(),
    );
    contactList.contactRelays = (jsonDecode(row.contactRelaysJson) as List)
        .map((e) => e.toString())
        .toList();
    contactList.petnames = (jsonDecode(row.petnamesJson) as List)
        .map((e) => e.toString())
        .toList();
    contactList.followedTags = (jsonDecode(row.followedTagsJson) as List)
        .map((e) => e.toString())
        .toList();
    contactList.followedCommunities =
        (jsonDecode(row.followedCommunitiesJson) as List)
            .map((e) => e.toString())
            .toList();
    contactList.followedEvents = (jsonDecode(row.followedEventsJson) as List)
        .map((e) => e.toString())
        .toList();
    contactList.createdAt = row.createdAt;
    contactList.loadedTimestamp = row.loadedTimestamp;
    contactList.sources = (jsonDecode(row.sourcesJson) as List)
        .map((e) => e.toString())
        .toList();
    return contactList;
  }

  // =====================
  // User Relay Lists
  // =====================

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    await _db
        .into(_db.userRelayLists)
        .insertOnConflictUpdate(
          UserRelayListsCompanion.insert(
            pubKey: userRelayList.pubKey,
            createdAt: userRelayList.createdAt,
            refreshedTimestamp: userRelayList.refreshedTimestamp,
            relaysJson: jsonEncode(_encodeRelaysMap(userRelayList.relays)),
          ),
        );
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.userRelayLists,
        userRelayLists
            .map(
              (userRelayList) => UserRelayListsCompanion.insert(
                pubKey: userRelayList.pubKey,
                createdAt: userRelayList.createdAt,
                refreshedTimestamp: userRelayList.refreshedTimestamp,
                relaysJson: jsonEncode(_encodeRelaysMap(userRelayList.relays)),
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    final row = await (_db.select(
      _db.userRelayLists,
    )..where((t) => t.pubKey.equals(pubKey))).getSingleOrNull();
    if (row == null) return null;
    return _userRelayListFromRow(row);
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    await (_db.delete(
      _db.userRelayLists,
    )..where((t) => t.pubKey.equals(pubKey))).go();
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    await _db.delete(_db.userRelayLists).go();
  }

  Map<String, Map<String, bool>> _encodeRelaysMap(
    Map<String, ReadWriteMarker> relays,
  ) {
    return relays.map(
      (key, value) =>
          MapEntry(key, {'read': value.isRead, 'write': value.isWrite}),
    );
  }

  Map<String, ReadWriteMarker> _decodeRelaysMap(Map<String, dynamic> json) {
    return json.map((key, value) {
      final map = value as Map<String, dynamic>;
      return MapEntry(
        key,
        ReadWriteMarker.from(
          read: map['read'] as bool? ?? false,
          write: map['write'] as bool? ?? false,
        ),
      );
    });
  }

  UserRelayList _userRelayListFromRow(DbUserRelayList row) {
    final relaysJson = jsonDecode(row.relaysJson) as Map<String, dynamic>;
    return UserRelayList(
      pubKey: row.pubKey,
      createdAt: row.createdAt,
      refreshedTimestamp: row.refreshedTimestamp,
      relays: _decodeRelaysMap(relaysJson),
    );
  }

  // =====================
  // Relay Sets
  // =====================

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    await _db
        .into(_db.relaySets)
        .insertOnConflictUpdate(
          RelaySetsCompanion.insert(
            id: relaySet.id,
            name: relaySet.name,
            pubKey: relaySet.pubKey,
            relayMinCountPerPubkey: relaySet.relayMinCountPerPubkey,
            direction: relaySet.direction.index,
            relaysMapJson: jsonEncode(
              _encodeRelaysMapWithMappings(relaySet.relaysMap),
            ),
            fallbackToBootstrapRelays: relaySet.fallbackToBootstrapRelays,
            notCoveredPubkeysJson: jsonEncode(
              _encodeNotCoveredPubkeys(relaySet.notCoveredPubkeys),
            ),
          ),
        );
  }

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    final id = RelaySet.buildId(name, pubKey);
    final row = await (_db.select(
      _db.relaySets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _relaySetFromRow(row);
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    final id = RelaySet.buildId(name, pubKey);
    await (_db.delete(_db.relaySets)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> removeAllRelaySets() async {
    await _db.delete(_db.relaySets).go();
  }

  List<Map<String, dynamic>> _encodeNotCoveredPubkeys(
    List<NotCoveredPubKey> notCoveredPubkeys,
  ) {
    return notCoveredPubkeys
        .map((pk) => {'pubKey': pk.pubKey, 'coverage': pk.coverage})
        .toList();
  }

  Map<String, List<Map<String, dynamic>>> _encodeRelaysMapWithMappings(
    Map<String, List<PubkeyMapping>> relaysMap,
  ) {
    return relaysMap.map(
      (key, value) => MapEntry(
        key,
        value
            .map(
              (mapping) => {
                'pubKey': mapping.pubKey,
                'rwMarker': {
                  'read': mapping.rwMarker.isRead,
                  'write': mapping.rwMarker.isWrite,
                },
              },
            )
            .toList(),
      ),
    );
  }

  RelaySet _relaySetFromRow(DbRelaySet row) {
    final relaysMapJson = jsonDecode(row.relaysMapJson) as Map<String, dynamic>;
    final relaysMap = <String, List<PubkeyMapping>>{};
    relaysMapJson.forEach((key, value) {
      final mappings = (value as List).map((mapping) {
        final m = mapping as Map<String, dynamic>;
        final rwMarker = m['rwMarker'] as Map<String, dynamic>;
        return PubkeyMapping(
          pubKey: m['pubKey'] as String,
          rwMarker: ReadWriteMarker.from(
            read: rwMarker['read'] as bool? ?? false,
            write: rwMarker['write'] as bool? ?? false,
          ),
        );
      }).toList();
      relaysMap[key] = mappings;
    });

    final notCoveredJson = jsonDecode(row.notCoveredPubkeysJson) as List;
    final notCoveredPubkeys = notCoveredJson
        .map(
          (item) => NotCoveredPubKey(
            (item as Map<String, dynamic>)['pubKey'] as String,
            item['coverage'] as int,
          ),
        )
        .toList();

    return RelaySet(
      name: row.name,
      pubKey: row.pubKey,
      relayMinCountPerPubkey: row.relayMinCountPerPubkey,
      direction: RelayDirection.values[row.direction],
      relaysMap: relaysMap,
      notCoveredPubkeys: notCoveredPubkeys,
      fallbackToBootstrapRelays: row.fallbackToBootstrapRelays,
    );
  }

  // =====================
  // NIP-05
  // =====================

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    await _db
        .into(_db.nip05s)
        .insertOnConflictUpdate(
          Nip05sCompanion.insert(
            pubKey: nip05.pubKey,
            nip05: nip05.nip05,
            valid: nip05.valid,
            networkFetchTime: Value(nip05.networkFetchTime),
            relaysJson: jsonEncode(nip05.relays ?? []),
          ),
        );
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.nip05s,
        nip05s
            .map(
              (nip05) => Nip05sCompanion.insert(
                pubKey: nip05.pubKey,
                nip05: nip05.nip05,
                valid: nip05.valid,
                networkFetchTime: Value(nip05.networkFetchTime),
                relaysJson: jsonEncode(nip05.relays ?? []),
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<Nip05?> loadNip05({String? pubKey, String? identifier}) async {
    if (pubKey != null) {
      final row = await (_db.select(
        _db.nip05s,
      )..where((t) => t.pubKey.equals(pubKey))).getSingleOrNull();
      if (row == null) return null;
      return _nip05FromRow(row);
    }
    if (identifier != null) {
      final row = await (_db.select(
        _db.nip05s,
      )..where((t) => t.nip05.equals(identifier))).getSingleOrNull();
      if (row == null) return null;
      return _nip05FromRow(row);
    }
    return null;
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    final rows = await (_db.select(
      _db.nip05s,
    )..where((t) => t.pubKey.isIn(pubKeys))).get();

    final map = {for (var row in rows) row.pubKey: _nip05FromRow(row)};
    return pubKeys.map((pk) => map[pk]).toList();
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    await (_db.delete(_db.nip05s)..where((t) => t.pubKey.equals(pubKey))).go();
  }

  @override
  Future<void> removeAllNip05s() async {
    await _db.delete(_db.nip05s).go();
  }

  Nip05 _nip05FromRow(DbNip05 row) {
    return Nip05(
      pubKey: row.pubKey,
      nip05: row.nip05,
      valid: row.valid,
      networkFetchTime: row.networkFetchTime,
      relays: (jsonDecode(row.relaysJson) as List)
          .map((e) => e.toString())
          .toList(),
    );
  }

  // =====================
  // Filter Fetched Ranges
  // =====================

  @override
  Future<void> saveFilterFetchedRangeRecord(
    FilterFetchedRangeRecord record,
  ) async {
    await _db
        .into(_db.filterFetchedRangeRecords)
        .insertOnConflictUpdate(
          FilterFetchedRangeRecordsCompanion.insert(
            key: record.key,
            filterHash: record.filterHash,
            relayUrl: record.relayUrl,
            rangeStart: record.rangeStart,
            rangeEnd: record.rangeEnd,
          ),
        );
  }

  @override
  Future<void> saveFilterFetchedRangeRecords(
    List<FilterFetchedRangeRecord> records,
  ) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.filterFetchedRangeRecords,
        records
            .map(
              (record) => FilterFetchedRangeRecordsCompanion.insert(
                key: record.key,
                filterHash: record.filterHash,
                relayUrl: record.relayUrl,
                rangeStart: record.rangeStart,
                rangeEnd: record.rangeEnd,
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
    String filterHash,
  ) async {
    final rows = await (_db.select(
      _db.filterFetchedRangeRecords,
    )..where((t) => t.filterHash.equals(filterHash))).get();
    return rows.map(_filterFetchedRangeRecordFromRow).toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
    String filterHash,
    String relayUrl,
  ) async {
    final rows =
        await (_db.select(_db.filterFetchedRangeRecords)..where(
              (t) =>
                  t.filterHash.equals(filterHash) & t.relayUrl.equals(relayUrl),
            ))
            .get();
    return rows.map(_filterFetchedRangeRecordFromRow).toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>>
  loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl) async {
    final rows = await (_db.select(
      _db.filterFetchedRangeRecords,
    )..where((t) => t.relayUrl.equals(relayUrl))).get();
    return rows.map(_filterFetchedRangeRecordFromRow).toList();
  }

  @override
  Future<void> removeFilterFetchedRangeRecords(String filterHash) async {
    await (_db.delete(
      _db.filterFetchedRangeRecords,
    )..where((t) => t.filterHash.equals(filterHash))).go();
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
    String filterHash,
    String relayUrl,
  ) async {
    await (_db.delete(_db.filterFetchedRangeRecords)..where(
          (t) => t.filterHash.equals(filterHash) & t.relayUrl.equals(relayUrl),
        ))
        .go();
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl) async {
    await (_db.delete(
      _db.filterFetchedRangeRecords,
    )..where((t) => t.relayUrl.equals(relayUrl))).go();
  }

  @override
  Future<void> removeAllFilterFetchedRangeRecords() async {
    await _db.delete(_db.filterFetchedRangeRecords).go();
  }

  FilterFetchedRangeRecord _filterFetchedRangeRecordFromRow(
    DbFilterFetchedRangeRecord row,
  ) {
    return FilterFetchedRangeRecord(
      filterHash: row.filterHash,
      relayUrl: row.relayUrl,
      rangeStart: row.rangeStart,
      rangeEnd: row.rangeEnd,
    );
  }

  // =====================
  // Deprecated Search Events
  // =====================

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
  Future<void> clearAll() async {
    await Future.wait([
      _db.delete(_db.events).go(),
      _db.delete(_db.metadatas).go(),
      _db.delete(_db.contactLists).go(),
      _db.delete(_db.userRelayLists).go(),
      _db.delete(_db.relaySets).go(),
      _db.delete(_db.nip05s).go(),
      _db.delete(_db.filterFetchedRangeRecords).go(),
    ]);
  }
}
