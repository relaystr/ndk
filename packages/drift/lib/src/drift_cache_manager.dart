import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_keyset.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_mint_info.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/domain_layer/entities/pubkey_mapping.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/cashu/cashu_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/nwc/nwc_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/lnurl/lnurl_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/event_kind_classification.dart';
import 'package:ndk/shared/nips/nip01/event_eviction_planner.dart';

import 'database/database.dart';

/// A Drift-based implementation of the CacheManager for NDK.
class DriftCacheManager extends WalletsRepo implements CacheManager {
  static const String _defaultWalletForReceivingKey =
      'default_wallet_for_receiving';
  static const String _defaultWalletForSendingKey =
      'default_wallet_for_sending';
  static const String _decryptedPayloadKeyPrefix = 'decrypted_payload:';
  static const String _eventDeliverySnapshotKeyPrefix =
      'event_delivery_snapshot:';

  final NdkCacheDatabase _db;
  String? _defaultWalletIdForReceiving;
  String? _defaultWalletIdForSending;

  DriftCacheManager(this._db) {
    unawaited(_initializeWalletDefaults());
  }

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

    final deletionRows = await (_db.select(
      _db.events,
    )..where((t) => t.kind.equals(5))).get();
    final deletions = deletionRows.map(_eventFromRow).toList();

    events = _applyEventVisibilityRules(events, deletions);
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && limit > 0 && events.length > limit) {
      events = events.take(limit).toList();
    }

    return events;
  }

  @override
  Future<void> removeEvent(String id) async {
    final removedEvent = await loadEvent(id);
    await (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
    await _removeEventSidecarsByIds([id]);
    if (removedEvent != null) {
      await _syncUserRelayListProjectionForEvent(removedEvent);
    }
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    final rows = await (_db.select(
      _db.events,
    )..where((t) => t.pubKey.equals(pubKey))).get();
    final eventIds = rows.map((row) => row.id).toList();
    await (_db.delete(_db.events)..where((t) => t.pubKey.equals(pubKey))).go();
    await _removeEventSidecarsByIds(eventIds);
    await _syncUserRelayListProjection(pubKey);
  }

  @override
  Future<void> removeAllEvents() async {
    await Future.wait([
      _db.delete(_db.events).go(),
      _db.delete(_db.eventSourcesTable).go(),
      _db.delete(_db.eventDeliveryRecordsTable).go(),
      _db.delete(_db.relayDeliveryTargetsTable).go(),
      _db.delete(_db.userRelayLists).go(),
      removeAllDecryptedEventPayloadRecords(),
      _removeAllEventDeliverySnapshots(),
    ]);
  }

  @override
  Future<EvictionResult> evict(EvictionPolicy policy) async {
    final rawRows = await _db.select(_db.events).get();
    final rawEvents = rawRows.map(_eventFromRow).toList();
    final deliveryRecords = await loadEventDeliveryRecords();
    final relayTargets = await loadRelayDeliveryTargets();
    final lockedEventIds = <String>{
      ...deliveryRecords.map((record) => record.eventId),
      ...relayTargets.map((target) => target.eventId),
    };
    final plan = EventEvictionPlanner.plan(
      rawEvents: rawEvents,
      lockedEventIds: lockedEventIds,
      policy: policy,
    );

    if (plan.eventIdsToRemove.isEmpty) {
      return plan.toResult();
    }

    final idsToRemove = plan.eventIdsToRemove.toList();
    await _db.transaction(() async {
      await (_db.delete(_db.events)..where((t) => t.id.isIn(idsToRemove))).go();
      await _removeEventSidecarsByIds(idsToRemove);
    });

    return plan.toResult();
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
    final hasNoFilters =
        (ids == null || ids.isEmpty) &&
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
      await _removeEventSidecarsByIds(idsToRemove);
      await _syncUserRelayListProjections(
        eventsToRemove.map((event) => event.pubKey),
      );
      return;
    }

    final rows =
        await (_db.select(_db.events)..where((t) {
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
            }))
            .get();
    final removedEventIds = rows.map((row) => row.id).toList();
    final affectedPubKeys = rows.map((row) => row.pubKey).toSet();

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
        }))
        .go();

    await _removeEventSidecarsByIds(removedEventIds);
    await _syncUserRelayListProjections(affectedPubKeys);
  }

  Future<void> _removeEventSidecarsByIds(Iterable<String> eventIds) async {
    final ids = eventIds.toSet().toList();
    if (ids.isEmpty) return;

    await (_db.delete(
      _db.eventSourcesTable,
    )..where((t) => t.eventId.isIn(ids))).go();
    await (_db.delete(
      _db.eventDeliveryRecordsTable,
    )..where((t) => t.eventId.isIn(ids))).go();
    await (_db.delete(
      _db.relayDeliveryTargetsTable,
    )..where((t) => t.eventId.isIn(ids))).go();
    await (_db.delete(_db.keyValues)..where((kv) {
          final conditions = ids
              .expand(
                (id) => [
                  kv.key.like('$_decryptedPayloadKeyPrefix$id|%'),
                  kv.key.equals(_eventDeliverySnapshotKey(id)),
                ],
              )
              .toList();
          if (conditions.length == 1) {
            return conditions.first;
          }
          return conditions.reduce((a, b) => a | b);
        }))
        .go();
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

  List<Nip01Event> _applyEventVisibilityRules(
    List<Nip01Event> events,
    List<Nip01Event> deletions,
  ) {
    final visible = <Nip01Event>[];
    final replaceableWinners = <String, Nip01Event>{};
    final now = Nip01Event.secondsSinceEpoch();

    for (final event in events) {
      if (_isExpired(event, now)) continue;
      if (_isDeletedByAuthor(event, deletions)) continue;

      final coordinateKey = _coordinateKey(event);
      if (coordinateKey == null) {
        visible.add(event);
        continue;
      }

      final current = replaceableWinners[coordinateKey];
      if (current == null || _isMoreRecentReplaceable(event, current)) {
        replaceableWinners[coordinateKey] = event;
      }
    }

    visible.addAll(replaceableWinners.values);
    return visible;
  }

  bool _isDeletedByAuthor(Nip01Event target, List<Nip01Event> deletions) {
    if (target.kind == 5) return false;

    for (final deletion in deletions) {
      if (deletion.pubKey != target.pubKey) continue;
      if (deletion.getTags('e').contains(target.id.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  bool _isExpired(Nip01Event event, int now) {
    final expirationValue = event.getFirstTag('expiration');
    if (expirationValue == null) return false;
    final expiration = int.tryParse(expirationValue);
    if (expiration == null) return false;
    return expiration <= now;
  }

  String? _coordinateKey(Nip01Event event) {
    if (!EventKindClassification.isReplaceableKind(event.kind)) return null;
    final dTag = event.getDtag() ?? '';
    return '${event.kind}:${event.pubKey}:$dTag';
  }

  bool _isMoreRecentReplaceable(Nip01Event candidate, Nip01Event current) {
    if (candidate.createdAt != current.createdAt) {
      return candidate.createdAt > current.createdAt;
    }

    return candidate.id.compareTo(current.id) < 0;
  }

  Future<Nip01Event?> _loadLatestVisibleEvent({
    required String pubKey,
    required int kind,
  }) async {
    final events = await loadEvents(pubKeys: [pubKey], kinds: [kind], limit: 1);
    if (events.isEmpty) return null;
    return events.first;
  }

  // =====================
  // Metadata
  // =====================

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await saveEvent(metadata.toEvent());
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await saveEvents(metadatas.map((metadata) => metadata.toEvent()).toList());
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    final event = await _loadLatestVisibleEvent(
      pubKey: pubKey,
      kind: Metadata.kKind,
    );
    if (event == null) return null;
    final metadata = Metadata.fromEvent(event);
    metadata.refreshedTimestamp = Nip01Event.secondsSinceEpoch();
    return metadata;
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    return Future.wait(pubKeys.map(loadMetadata));
  }

  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    final events = await loadEvents(kinds: [Metadata.kKind]);
    final normalizedSearch = search.trim().toLowerCase();
    final matches = events.map((event) => Metadata.fromEvent(event)).where((
      metadata,
    ) {
      if (normalizedSearch.isEmpty) return true;
      return metadata.matchesSearch(normalizedSearch) ||
          (metadata.about?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (metadata.cleanNip05?.contains(normalizedSearch) ?? false);
    }).toList()..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    return matches.take(limit);
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    await removeEvents(pubKeys: [pubKey], kinds: [Metadata.kKind]);
  }

  @override
  Future<void> removeAllMetadatas() async {
    await removeEvents(kinds: [Metadata.kKind]);
  }

  // =====================
  // Contact Lists
  // =====================

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await saveEvent(contactList.toEvent());
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    await saveEvents(
      contactLists.map((contactList) => contactList.toEvent()).toList(),
    );
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    final event = await _loadLatestVisibleEvent(
      pubKey: pubKey,
      kind: ContactList.kKind,
    );
    if (event == null) return null;
    return ContactList.fromEvent(event);
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    await removeEvents(pubKeys: [pubKey], kinds: [ContactList.kKind]);
  }

  @override
  Future<void> removeAllContactLists() async {
    await removeEvents(kinds: [ContactList.kKind]);
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
    final fromEvents = await _deriveUserRelayListFromEvents(pubKey);
    if (fromEvents != null) {
      return fromEvents;
    }

    final row = await (_db.select(
      _db.userRelayLists,
    )..where((t) => t.pubKey.equals(pubKey))).getSingleOrNull();
    if (row == null) return null;
    return _userRelayListFromRow(row);
  }

  Future<UserRelayList?> _deriveUserRelayListFromEvents(String pubKey) async {
    final events = await loadEvents(
      pubKeys: [pubKey],
      kinds: [Nip65.kKind, ContactList.kKind],
    );

    Nip01Event? latestNip65;
    Nip01Event? latestContactListWithRelays;
    for (final event in events) {
      if (event.kind == Nip65.kKind) {
        latestNip65 ??= event;
      } else if (event.kind == ContactList.kKind &&
          ContactList.relaysFromContent(event).isNotEmpty) {
        latestContactListWithRelays ??= event;
      }
    }

    if (latestNip65 != null) {
      return UserRelayList.fromNip65(Nip65.fromEvent(latestNip65));
    }

    if (latestContactListWithRelays != null) {
      return UserRelayList.fromNip02EventContent(latestContactListWithRelays);
    }

    return null;
  }

  Future<void> _syncUserRelayListProjection(String pubKey) async {
    final derived = await _deriveUserRelayListFromEvents(pubKey);
    if (derived == null) {
      await (_db.delete(
        _db.userRelayLists,
      )..where((t) => t.pubKey.equals(pubKey))).go();
      return;
    }

    await saveUserRelayList(derived);
  }

  Future<void> _syncUserRelayListProjectionForEvent(Nip01Event event) async {
    if (!_affectsUserRelayListProjection(event.kind)) {
      return;
    }
    await _syncUserRelayListProjection(event.pubKey);
  }

  Future<void> _syncUserRelayListProjections(Iterable<String> pubKeys) async {
    for (final pubKey in pubKeys.toSet()) {
      await _syncUserRelayListProjection(pubKey);
    }
  }

  bool _affectsUserRelayListProjection(int kind) {
    return kind == ContactList.kKind || kind == Nip65.kKind;
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

  // =====================
  // Event Sources
  // =====================

  @override
  Future<void> addEventSource({
    required String eventId,
    required String relayUrl,
  }) async {
    await _db
        .into(_db.eventSourcesTable)
        .insertOnConflictUpdate(
          EventSourcesTableCompanion.insert(
            eventId: eventId,
            relayUrl: relayUrl,
          ),
        );
  }

  @override
  Future<void> addEventSources({
    required String eventId,
    required Iterable<String> relayUrls,
  }) async {
    await _db.batch((batch) {
      for (final relayUrl in relayUrls) {
        batch.insert(
          _db.eventSourcesTable,
          EventSourcesTableCompanion.insert(
            eventId: eventId,
            relayUrl: relayUrl,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  @override
  Future<List<String>> loadEventSources(String eventId) async {
    final rows = await (_db.select(
      _db.eventSourcesTable,
    )..where((t) => t.eventId.equals(eventId))).get();
    return rows.map((r) => r.relayUrl).toList();
  }

  @override
  Future<void> removeEventSources(String eventId) async {
    await (_db.delete(
      _db.eventSourcesTable,
    )..where((t) => t.eventId.equals(eventId))).go();
  }

  // =====================
  // Event Delivery Records
  // =====================

  @override
  Future<void> saveEventDeliveryRecord(EventDeliveryRecord record) async {
    await _db
        .into(_db.eventDeliveryRecordsTable)
        .insertOnConflictUpdate(
          EventDeliveryRecordsTableCompanion.insert(
            eventId: record.eventId,
            status: record.status.name,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            signedAt: Value(record.signedAt),
            completedAt: Value(record.completedAt),
            requiresNetworkSigner: Value(record.requiresInteractiveSigning),
          ),
        );
    await _saveEventDeliverySnapshot(record);
  }

  @override
  Future<void> saveEventDeliveryRecords(
    List<EventDeliveryRecord> records,
  ) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.eventDeliveryRecordsTable,
        records
            .map(
              (record) => EventDeliveryRecordsTableCompanion.insert(
                eventId: record.eventId,
                status: record.status.name,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                signedAt: Value(record.signedAt),
                completedAt: Value(record.completedAt),
                requiresNetworkSigner: Value(record.requiresInteractiveSigning),
              ),
            )
            .toList(),
      );
    });
    await Future.wait(records.map(_saveEventDeliverySnapshot));
  }

  @override
  Future<EventDeliveryRecord?> loadEventDeliveryRecord(String eventId) async {
    final row = await (_db.select(
      _db.eventDeliveryRecordsTable,
    )..where((t) => t.eventId.equals(eventId))).getSingleOrNull();
    if (row == null) return null;
    return _withEventDeliverySnapshot(_eventDeliveryRecordFromRow(row));
  }

  @override
  Future<List<EventDeliveryRecord>> loadEventDeliveryRecords({
    EventDeliveryStatus? status,
    int? limit,
  }) async {
    var query = _db.select(_db.eventDeliveryRecordsTable);
    if (status != null) {
      query = query..where((t) => t.status.equals(status.name));
    }
    if (limit != null) {
      query = query..limit(limit);
    }
    final rows = await query.get();
    return Future.wait(
      rows.map(
        (row) => _withEventDeliverySnapshot(_eventDeliveryRecordFromRow(row)),
      ),
    );
  }

  @override
  Future<void> removeEventDeliveryRecord(String eventId) async {
    await Future.wait([
      (_db.delete(
        _db.eventDeliveryRecordsTable,
      )..where((t) => t.eventId.equals(eventId))).go(),
      _removeEventDeliverySnapshot(eventId),
    ]);
  }

  @override
  Future<void> removeAllEventDeliveryRecords() async {
    await Future.wait([
      _db.delete(_db.eventDeliveryRecordsTable).go(),
      _removeAllEventDeliverySnapshots(),
    ]);
  }

  EventDeliveryRecord _eventDeliveryRecordFromRow(DbEventDeliveryRecord row) {
    return EventDeliveryRecord(
      eventId: row.eventId,
      status: EventDeliveryStatus.values.byName(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      signedAt: row.signedAt,
      completedAt: row.completedAt,
      requiresInteractiveSigning: row.requiresNetworkSigner,
    );
  }

  Future<void> _saveEventDeliverySnapshot(EventDeliveryRecord record) async {
    final hasSnapshotPayload =
        (record.serializedEventJson != null &&
            record.serializedEventJson!.isNotEmpty) ||
        record.signingState != EventSigningState.notNeeded ||
        record.signAttemptCount > 0 ||
        record.lastSignAttemptAt != null ||
        record.nextSignRetryAt != null ||
        record.lastSignError != null;
    if (!hasSnapshotPayload) {
      await _removeEventDeliverySnapshot(record.eventId);
      return;
    }

    final snapshotJson = jsonEncode(record.toJson());
    await _db
        .into(_db.keyValues)
        .insertOnConflictUpdate(
          KeyValuesCompanion.insert(
            key: _eventDeliverySnapshotKey(record.eventId),
            value: Value(snapshotJson),
          ),
        );
  }

  Future<EventDeliveryRecord> _withEventDeliverySnapshot(
    EventDeliveryRecord record,
  ) async {
    final snapshotRow =
        await (_db.select(_db.keyValues)..where(
              (kv) => kv.key.equals(_eventDeliverySnapshotKey(record.eventId)),
            ))
            .getSingleOrNull();
    final snapshotValue = snapshotRow?.value;
    if (snapshotValue == null || snapshotValue.isEmpty) {
      return record;
    }

    try {
      final decoded = jsonDecode(snapshotValue);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('eventId') &&
          decoded.containsKey('status')) {
        return EventDeliveryRecord.fromJson(decoded);
      }
    } catch (_) {
      // Older snapshots stored only the serialized event JSON string.
    }

    return record.copyWith(serializedEventJson: snapshotValue);
  }

  Future<void> _removeEventDeliverySnapshot(String eventId) async {
    await (_db.delete(
      _db.keyValues,
    )..where((kv) => kv.key.equals(_eventDeliverySnapshotKey(eventId)))).go();
  }

  Future<void> _removeAllEventDeliverySnapshots() async {
    await (_db.delete(
      _db.keyValues,
    )..where((kv) => kv.key.like('$_eventDeliverySnapshotKeyPrefix%'))).go();
  }

  String _eventDeliverySnapshotKey(String eventId) {
    return '$_eventDeliverySnapshotKeyPrefix$eventId';
  }

  // =====================
  // Relay Delivery Targets
  // =====================

  @override
  Future<void> saveRelayDeliveryTarget(RelayDeliveryTarget target) async {
    await _db
        .into(_db.relayDeliveryTargetsTable)
        .insertOnConflictUpdate(
          RelayDeliveryTargetsTableCompanion.insert(
            eventId: target.eventId,
            relayUrl: target.relayUrl,
            reason: target.reason.name,
            state: target.state.name,
            attemptCount: Value(target.attemptCount),
            lastAttemptAt: Value(target.lastAttemptAt),
            nextRetryAt: Value(target.nextRetryAt),
            lastError: Value(target.lastError),
            lastOkMessage: Value(target.lastOkMessage),
          ),
        );
  }

  @override
  Future<void> saveRelayDeliveryTargets(
    List<RelayDeliveryTarget> targets,
  ) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.relayDeliveryTargetsTable,
        targets
            .map(
              (target) => RelayDeliveryTargetsTableCompanion.insert(
                eventId: target.eventId,
                relayUrl: target.relayUrl,
                reason: target.reason.name,
                state: target.state.name,
                attemptCount: Value(target.attemptCount),
                lastAttemptAt: Value(target.lastAttemptAt),
                nextRetryAt: Value(target.nextRetryAt),
                lastError: Value(target.lastError),
                lastOkMessage: Value(target.lastOkMessage),
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<RelayDeliveryTarget?> loadRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    final row =
        await (_db.select(_db.relayDeliveryTargetsTable)..where(
              (t) => t.eventId.equals(eventId) & t.relayUrl.equals(relayUrl),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return _relayDeliveryTargetFromRow(row);
  }

  @override
  Future<List<RelayDeliveryTarget>> loadRelayDeliveryTargets({
    String? eventId,
    String? relayUrl,
    RelayDeliveryState? state,
    bool excludeAcked = false,
    int? limit,
  }) async {
    var query = _db.select(_db.relayDeliveryTargetsTable);

    query = query
      ..where((t) {
        final conditions = <Expression<bool>>[];
        if (eventId != null) {
          conditions.add(t.eventId.equals(eventId));
        }
        if (relayUrl != null) {
          conditions.add(t.relayUrl.equals(relayUrl));
        }
        if (state != null) {
          conditions.add(t.state.equals(state.name));
        }
        if (excludeAcked) {
          conditions.add(t.state.equals(RelayDeliveryState.acked.name).not());
        }
        if (conditions.isEmpty) return const Constant(true);
        return conditions.reduce((a, b) => a & b);
      })
      ..orderBy([
        (t) => OrderingTerm.asc(t.nextRetryAt),
        (t) => OrderingTerm.asc(t.eventId),
        (t) => OrderingTerm.asc(t.relayUrl),
      ]);

    if (limit != null) {
      query = query..limit(limit);
    }

    final rows = await query.get();
    return rows.map(_relayDeliveryTargetFromRow).toList();
  }

  @override
  Future<void> removeRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    await (_db.delete(_db.relayDeliveryTargetsTable)..where(
          (t) => t.eventId.equals(eventId) & t.relayUrl.equals(relayUrl),
        ))
        .go();
  }

  @override
  Future<void> removeRelayDeliveryTargets(String eventId) async {
    await (_db.delete(
      _db.relayDeliveryTargetsTable,
    )..where((t) => t.eventId.equals(eventId))).go();
  }

  @override
  Future<void> removeAllRelayDeliveryTargets() async {
    await _db.delete(_db.relayDeliveryTargetsTable).go();
  }

  RelayDeliveryTarget _relayDeliveryTargetFromRow(DbRelayDeliveryTarget row) {
    return RelayDeliveryTarget(
      eventId: row.eventId,
      relayUrl: row.relayUrl,
      reason: RelayDeliveryReason.values.byName(row.reason),
      state: RelayDeliveryState.values.byName(row.state),
      attemptCount: row.attemptCount,
      lastAttemptAt: row.lastAttemptAt,
      nextRetryAt: row.nextRetryAt,
      lastError: row.lastError,
      lastOkMessage: row.lastOkMessage,
    );
  }

  String _decryptedPayloadKey(String eventId, String viewerPubKey) =>
      '$_decryptedPayloadKeyPrefix$eventId|$viewerPubKey';

  @override
  Future<void> saveDecryptedEventPayloadRecord(
    DecryptedEventPayloadRecord record,
  ) async {
    await _storeKeyValue(
      key: _decryptedPayloadKey(record.eventId, record.viewerPubKey),
      value: jsonEncode(record.toJson()),
    );
  }

  @override
  Future<void> saveDecryptedEventPayloadRecords(
    List<DecryptedEventPayloadRecord> records,
  ) async {
    await _db.batch((batch) {
      for (final record in records) {
        batch.insert(
          _db.keyValues,
          KeyValuesCompanion.insert(
            key: _decryptedPayloadKey(record.eventId, record.viewerPubKey),
            value: Value(jsonEncode(record.toJson())),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<DecryptedEventPayloadRecord?> loadDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  }) async {
    final raw = await _getKeyValue(_decryptedPayloadKey(eventId, viewerPubKey));
    if (raw == null) {
      return null;
    }
    return DecryptedEventPayloadRecord.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<DecryptedEventPayloadRecord>> loadDecryptedEventPayloadRecords({
    String? eventId,
    String? viewerPubKey,
    DecryptedPayloadStatus? status,
    int? limit,
  }) async {
    final rows = await (_db.select(
      _db.keyValues,
    )..where((kv) => kv.key.like('$_decryptedPayloadKeyPrefix%'))).get();

    var records = rows
        .where((row) => row.value != null)
        .map(
          (row) => DecryptedEventPayloadRecord.fromJson(
            jsonDecode(row.value!) as Map<String, dynamic>,
          ),
        )
        .where((record) {
          if (eventId != null && record.eventId != eventId) {
            return false;
          }
          if (viewerPubKey != null && record.viewerPubKey != viewerPubKey) {
            return false;
          }
          if (status != null && record.status != status) {
            return false;
          }
          return true;
        })
        .toList();

    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (limit != null && limit > 0 && records.length > limit) {
      records = records.take(limit).toList();
    }
    return records;
  }

  @override
  Future<void> removeDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  }) async {
    await (_db.delete(_db.keyValues)..where(
          (kv) => kv.key.equals(_decryptedPayloadKey(eventId, viewerPubKey)),
        ))
        .go();
  }

  @override
  Future<void> removeDecryptedEventPayloadRecords(String eventId) async {
    await (_db.delete(_db.keyValues)
          ..where((kv) => kv.key.like('$_decryptedPayloadKeyPrefix$eventId|%')))
        .go();
  }

  @override
  Future<void> removeAllDecryptedEventPayloadRecords() async {
    await (_db.delete(
      _db.keyValues,
    )..where((kv) => kv.key.like('$_decryptedPayloadKeyPrefix%'))).go();
  }

  // =====================
  // Cashu Methods
  // =====================

  @override
  Future<void> saveKeyset(CahsuKeyset keyset) async {
    await _db
        .into(_db.cashuKeysets)
        .insertOnConflictUpdate(
          CashuKeysetsCompanion.insert(
            id: keyset.id,
            mintUrl: keyset.mintUrl,
            unit: keyset.unit,
            active: keyset.active,
            inputFeePPK: keyset.inputFeePPK,
            mintKeyPairsJson: jsonEncode(
              keyset.mintKeyPairs
                  .map((pair) => {'amount': pair.amount, 'pubkey': pair.pubkey})
                  .toList(),
            ),
            fetchedAt: Value(keyset.fetchedAt),
          ),
        );
  }

  @override
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl}) async {
    var query = _db.select(_db.cashuKeysets);
    if (mintUrl != null) {
      query = query..where((k) => k.mintUrl.equals(mintUrl));
    }
    final rows = await query.get();
    return rows.map(_keysetFromRow).toList();
  }

  CahsuKeyset _keysetFromRow(DbCashuKeyset row) {
    final keyPairs = (jsonDecode(row.mintKeyPairsJson) as List)
        .map(
          (e) => CahsuMintKeyPair(
            amount: e['amount'] as int,
            pubkey: e['pubkey'] as String,
          ),
        )
        .toSet();
    return CahsuKeyset(
      id: row.id,
      mintUrl: row.mintUrl,
      unit: row.unit,
      active: row.active,
      inputFeePPK: row.inputFeePPK,
      mintKeyPairs: keyPairs,
      fetchedAt: row.fetchedAt,
    );
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    await _db.batch((batch) {
      for (final proof in proofs) {
        batch.insert(
          _db.cashuProofs,
          CashuProofsCompanion.insert(
            Y: proof.Y,
            keysetId: proof.keysetId,
            amount: proof.amount,
            secret: proof.secret,
            unblindedSig: proof.unblindedSig,
            state: proof.state.value,
            mintUrl: mintUrl,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  }) async {
    var query = _db.select(_db.cashuProofs)
      ..where((p) => p.state.equals(state.value));

    if (mintUrl != null) {
      query = query..where((p) => p.mintUrl.equals(mintUrl));
    }
    if (keysetId != null) {
      query = query..where((p) => p.keysetId.equals(keysetId));
    }

    final rows = await query.get();
    return rows.map(_proofFromRow).toList();
  }

  CashuProof _proofFromRow(DbCashuProof row) {
    return CashuProof(
      keysetId: row.keysetId,
      amount: row.amount,
      secret: row.secret,
      unblindedSig: row.unblindedSig,
      state: CashuProofState.fromValue(row.state),
    );
  }

  @override
  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    final yValues = proofs.map((p) => p.Y).toList();
    await (_db.delete(
      _db.cashuProofs,
    )..where((p) => p.mintUrl.equals(mintUrl) & p.Y.isIn(yValues))).go();
  }

  @override
  Future<void> saveMintInfo({required CashuMintInfo mintInfo}) async {
    final id = mintInfo.urls.isNotEmpty ? mintInfo.urls.first : '';
    await _db
        .into(_db.cashuMintInfos)
        .insertOnConflictUpdate(
          CashuMintInfosCompanion.insert(
            id: id,
            urlsJson: jsonEncode(mintInfo.urls),
            name: Value(mintInfo.name),
            pubkey: Value(mintInfo.pubkey),
            version: Value(mintInfo.version),
            description: Value(mintInfo.description),
            descriptionLong: Value(mintInfo.descriptionLong),
            contactJson: jsonEncode(
              mintInfo.contact.map((c) => c.toJson()).toList(),
            ),
            motd: Value(mintInfo.motd),
            iconUrl: Value(mintInfo.iconUrl),
            time: Value(mintInfo.time),
            tosUrl: Value(mintInfo.tosUrl),
            nutsJson: jsonEncode(
              mintInfo.nuts.map((k, v) => MapEntry(k.toString(), v.toJson())),
            ),
          ),
        );
  }

  @override
  Future<void> removeMintInfo({required String mintUrl}) async {
    await (_db.delete(
      _db.cashuMintInfos,
    )..where((tbl) => tbl.id.equals(mintUrl))).go();
  }

  @override
  Future<List<CashuMintInfo>?> getMintInfos({List<String>? mintUrls}) async {
    var query = _db.select(_db.cashuMintInfos);
    if (mintUrls != null && mintUrls.isNotEmpty) {
      // This is a simplification - ideally we'd parse the JSON array
      query = query..where((m) => m.id.isIn(mintUrls));
    }
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return rows.map(_mintInfoFromRow).toList();
  }

  CashuMintInfo _mintInfoFromRow(DbCashuMintInfo row) {
    return CashuMintInfo.fromJson({
      'name': row.name,
      'pubkey': row.pubkey,
      'version': row.version,
      'description': row.description,
      'description_long': row.descriptionLong,
      'contact': jsonDecode(row.contactJson),
      'motd': row.motd,
      'icon_url': row.iconUrl,
      'urls': jsonDecode(row.urlsJson),
      'time': row.time,
      'tos_url': row.tosUrl,
      'nuts': jsonDecode(row.nutsJson),
    }, mintUrl: row.id);
  }

  @override
  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  }) async {
    final id = '$mintUrl|$keysetId';
    final row = await (_db.select(
      _db.cashuSecretCounters,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row?.counter ?? 0;
  }

  @override
  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  }) async {
    final id = '$mintUrl|$keysetId';
    await _db
        .into(_db.cashuSecretCounters)
        .insertOnConflictUpdate(
          CashuSecretCountersCompanion.insert(
            id: id,
            mintUrl: mintUrl,
            keysetId: keysetId,
            counter: counter,
          ),
        );
  }

  // =====================
  // Wallet Methods
  // =====================

  @override
  Future<void> storeWallet(Wallet wallet) async {
    await _db
        .into(_db.wallets)
        .insertOnConflictUpdate(
          WalletsCompanion.insert(
            id: wallet.id,
            name: wallet.name,
            type: wallet.type.name,
            supportedUnitsJson: jsonEncode(wallet.supportedUnits.toList()),
            metadataJson: jsonEncode(wallet.toMetadata()),
          ),
        );
  }

  @override
  Future<void> removeWallet(String id) async {
    await (_db.delete(_db.wallets)..where((w) => w.id.equals(id))).go();

    if (getDefaultWalletIdForReceiving() == id) {
      setDefaultWalletForReceiving(null);
    }
    if (getDefaultWalletIdForSending() == id) {
      setDefaultWalletForSending(null);
    }
  }

  @override
  Future<List<Wallet>> getWallets({List<String>? ids}) async {
    var query = _db.select(_db.wallets);
    if (ids != null && ids.isNotEmpty) {
      query = query..where((w) => w.id.isIn(ids));
    }
    final rows = await query.get();
    if (rows.isEmpty && ids != null) return [];
    return rows.map(_walletFromRow).toList();
  }

  Future<String?> _getKeyValue(String key) async {
    final row = await (_db.select(
      _db.keyValues,
    )..where((kv) => kv.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _storeKeyValue({required String key, required String? value}) {
    return _db
        .into(_db.keyValues)
        .insertOnConflictUpdate(
          KeyValuesCompanion.insert(key: key, value: Value(value)),
        );
  }

  @override
  String? getDefaultWalletIdForReceiving() {
    return _defaultWalletIdForReceiving;
  }

  @override
  String? getDefaultWalletIdForSending() {
    return _defaultWalletIdForSending;
  }

  @override
  void setDefaultWalletForReceiving(String? walletId) {
    _defaultWalletIdForReceiving = walletId;
    unawaited(
      _storeKeyValue(key: _defaultWalletForReceivingKey, value: walletId),
    );
  }

  @override
  void setDefaultWalletForSending(String? walletId) {
    _defaultWalletIdForSending = walletId;
    unawaited(
      _storeKeyValue(key: _defaultWalletForSendingKey, value: walletId),
    );
  }

  Future<void> _initializeWalletDefaults() async {
    _defaultWalletIdForReceiving = await _getKeyValue(
      _defaultWalletForReceivingKey,
    );
    _defaultWalletIdForSending = await _getKeyValue(
      _defaultWalletForSendingKey,
    );
  }

  Wallet _walletFromRow(DbWallet row) {
    final metadata = jsonDecode(row.metadataJson) as Map<String, dynamic>;
    final type = WalletType.values.firstWhere(
      (t) => t.name == row.type,
      orElse: () => WalletType.CASHU,
    );
    final supportedUnits = (jsonDecode(row.supportedUnitsJson) as List)
        .map((e) => e.toString())
        .toSet();

    switch (type) {
      case WalletType.CASHU:
        return CashuWallet(
          id: row.id,
          name: row.name,
          supportedUnits: supportedUnits,
          mintUrl: metadata['mintUrl'] as String,
          mintInfo: CashuMintInfo.fromJson(
            metadata['mintInfo'] as Map<String, dynamic>,
            mintUrl: metadata['mintUrl'] as String,
          ),
        );
      case WalletType.NWC:
        return NwcWallet(
          id: row.id,
          name: row.name,
          supportedUnits: supportedUnits,
          nwcUrl: metadata['nwcUrl'] as String,
        );
      case WalletType.LNURL:
        return LnurlWallet(
          id: row.id,
          name: row.name,
          supportedUnits: supportedUnits,
          identifier: metadata['identifier'] as String,
          lnurlPayUrl: metadata['lnurlPayUrl'] as String,
          minSendable: metadata['minSendable'] as int?,
          maxSendable: metadata['maxSendable'] as int?,
          metadataFetchedAt: metadata['metadataFetchedAt'] as int?,
        );
    }
  }

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) async {
    await _db.batch((batch) {
      for (final transaction in transactions) {
        batch.insert(
          _db.walletTransactions,
          WalletTransactionsCompanion.insert(
            id: transaction.id,
            walletId: transaction.walletId,
            changeAmount: transaction.changeAmount,
            unit: transaction.unit,
            type: transaction.walletType.name,
            state: transaction.state.value,
            completionMsg: Value(transaction.completionMsg),
            transactionDate: Value(transaction.transactionDate),
            initiatedDate: Value(transaction.initiatedDate),
            metadataJson: jsonEncode(transaction.metadata),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<void> removeTransactions(List<String>? transactionIds) async {
    if (transactionIds == null || transactionIds.isEmpty) {
      _db.delete(_db.walletTransactions).go();
      return;
    }

    await (_db.delete(
      _db.walletTransactions,
    )..where((t) => t.id.isIn(transactionIds))).go();
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) async {
    var query = _db.select(_db.walletTransactions);

    if (walletId != null) {
      query = query..where((t) => t.walletId.equals(walletId));
    }
    if (unit != null) {
      query = query..where((t) => t.unit.equals(unit));
    }
    if (walletType != null) {
      query = query..where((t) => t.type.equals(walletType.name));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.initiatedDate)]);

    if (limit != null && limit > 0) {
      if (offset != null && offset > 0) {
        query = query..limit(limit, offset: offset);
      } else {
        query = query..limit(limit);
      }
    }

    final rows = await query.get();
    return rows.map(_transactionFromRow).toList();
  }

  WalletTransaction _transactionFromRow(DbWalletTransaction row) {
    final type = WalletType.values.firstWhere(
      (t) => t.name == row.type,
      orElse: () => WalletType.CASHU,
    );
    final metadata = jsonDecode(row.metadataJson) as Map<String, dynamic>;

    return WalletTransaction.toTransactionType(
      id: row.id,
      walletId: row.walletId,
      changeAmount: row.changeAmount,
      unit: row.unit,
      walletType: type,
      state: WalletTransactionState.fromValue(row.state),
      metadata: metadata,
      completionMsg: row.completionMsg,
      transactionDate: row.transactionDate,
      initiatedDate: row.initiatedDate,
    );
  }

  @override
  Future<void> clearAll() async {
    await Future.wait([
      _db.delete(_db.events).go(),
      _db.delete(_db.userRelayLists).go(),
      _db.delete(_db.relaySets).go(),
      _db.delete(_db.nip05s).go(),
      _db.delete(_db.filterFetchedRangeRecords).go(),
      _db.delete(_db.eventSourcesTable).go(),
      _db.delete(_db.eventDeliveryRecordsTable).go(),
      _db.delete(_db.relayDeliveryTargetsTable).go(),
      // Cashu tables
      _db.delete(_db.cashuProofs).go(),
      _db.delete(_db.cashuKeysets).go(),
      _db.delete(_db.cashuMintInfos).go(),
      _db.delete(_db.cashuSecretCounters).go(),
      _db.delete(_db.keyValues).go(),
      _db.delete(_db.wallets).go(),
      _db.delete(_db.walletTransactions).go(),
    ]);
    _defaultWalletIdForReceiving = null;
    _defaultWalletIdForSending = null;
  }
}
