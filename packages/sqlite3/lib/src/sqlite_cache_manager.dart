import 'dart:convert';

import 'package:ndk/data_layer/repositories/cache_manager/ndk_extensions.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_keyset.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_mint_info.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_factory.dart';
import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/event_kind_classification.dart';
import 'package:ndk/shared/nips/nip01/event_visibility_resolver.dart';
import 'package:ndk/shared/nips/nip09/deletion.dart';
import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';
import 'sql.dart';

/// A [CacheManager] stored in SQLite through `package:sqlite3`.
///
/// It runs in pure Dart, so command line tools and servers can use it as well
/// as Flutter apps. Filters, visibility rules and eviction run in SQL: no read
/// loads more rows than it returns.
///
/// SQLite calls are synchronous, each method blocks the calling isolate until
/// its queries finish.
class SqliteCacheManager extends WalletsRepo implements CacheManager {
  static const _defaultWalletForReceivingKey = 'default_wallet_for_receiving';
  static const _defaultWalletForSendingKey = 'default_wallet_for_sending';

  static const _eventSidecarTables = [
    'event_sources',
    'event_delivery_records',
    'relay_delivery_targets',
    'decrypted_payloads',
  ];

  final Database _db;
  String? _defaultWalletIdForReceiving;
  String? _defaultWalletIdForSending;

  /// Uses the already opened [db], which [close] closes.
  SqliteCacheManager(this._db) {
    _db.execute('PRAGMA foreign_keys = ON');
    migrate(_db);
    _defaultWalletIdForReceiving = _getKeyValue(_defaultWalletForReceivingKey);
    _defaultWalletIdForSending = _getKeyValue(_defaultWalletForSendingKey);
  }

  /// Opens the database file at [path], creating it when missing.
  factory SqliteCacheManager.open(String path) {
    final db = sqlite3.open(path);
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA synchronous = NORMAL');
    return SqliteCacheManager(db);
  }

  @override
  Future<void> close() async {
    _db.execute('PRAGMA optimize');
    _db.close();
  }

  // =====================
  // Events
  // =====================

  @override
  Future<void> saveEvent(Nip01Event event) async {
    _writeEvents([event], overwrite: true);
  }

  @override
  Future<bool> saveEventIfAbsent(Nip01Event event) async {
    return _writeEvents([event], overwrite: false) == 1;
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    _writeEvents(events, overwrite: true);
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    final rows = _db.select(
      'SELECT $eventColumns FROM events e WHERE e.id = ?',
      [id],
    );
    return rows.isEmpty ? null : _eventFromRow(rows.first);
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
    final where = eventFilter(
      ids: ids,
      pubKeys: pubKeys,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
    )..add(visibleSql('e', _now()));
    return _selectEvents(where, limit: limit);
  }

  @override
  Future<List<HiddenEvent>> loadHiddenEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    List<String>? coordinates,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
    Set<HiddenEventReason> reasons = kAllHiddenEventReasons,
  }) async {
    if (reasons.isEmpty) return [];
    final now = _now();
    final where = eventFilter(
      ids: ids,
      pubKeys: pubKeys,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
    );
    if (coordinates != null) {
      final conflictKeys = coordinates
          .map(EventCacheStateRecord.normalizeConflictKey)
          .nonNulls
          .toSet();
      if (conflictKeys.isEmpty) return [];
      where.add('e.conflict_key IN $jsonArray', [
        jsonEncode(conflictKeys.toList()),
      ]);
    }
    final reasonConditions = [
      if (reasons.contains(HiddenEventReason.expired)) expiredSql('e', now),
      if (reasons.contains(HiddenEventReason.deleted)) deletedSql('e'),
      if (reasons.contains(HiddenEventReason.superseded))
        supersededSql('e', now),
    ];
    where.add('(${reasonConditions.join(' OR ')})');

    final args = [...where.args];
    var sql =
        'SELECT $eventColumns, e.conflict_key, e.expiration, '
        '${deletedBySql('e')} AS deleted_by, '
        '${currentSql('e', now)} AS is_current '
        'FROM events e WHERE $where ORDER BY e.created_at DESC, e.id';
    if (limit != null && limit > 0) {
      sql += ' LIMIT ?';
      args.add(limit);
    }

    return _db.select(sql, args).map((row) {
      final event = _eventFromRow(row);
      final state = EventCacheStateRecord(
        eventId: event.id,
        pubKey: event.pubKey,
        kind: event.kind,
        createdAt: event.createdAt,
        coordinateKey: EventKindClassification.isAddressableKind(event.kind)
            ? row['conflict_key'] as String?
            : null,
        isCurrent: row['is_current'] == 1,
        expirationAt: row['expiration'] as int?,
        deletedByEventId: row['deleted_by'] as String?,
      );
      return HiddenEvent(
        event: event,
        state: state,
        reasons: EventVisibilityResolver.hiddenReasons(state, now),
      );
    }).toList();
  }

  @override
  Future<void> removeEvent(String id) async {
    _removeEventsWhere(SqlWhere()..add('e.id = ?', [id]));
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
    final where = eventFilter(
      ids: ids,
      pubKeys: pubKeys,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
    );
    if (where.isEmpty) return;
    _removeEventsWhere(where);
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    _removeEventsWhere(SqlWhere()..add('e.pub_key = ?', [pubKey]));
  }

  @override
  Future<void> removeAllEvents() async {
    _transaction(() {
      for (final table in [
        'event_tags',
        'deletion_targets',
        'events',
        ..._eventSidecarTables,
        'user_relay_lists',
      ]) {
        _db.execute('DELETE FROM $table');
      }
    });
  }

  @override
  Future<EvictionResult> evict(EvictionPolicy policy) async {
    final now = _now();
    return _transaction(() {
      _db.execute(
        'CREATE TEMP TABLE IF NOT EXISTS evict_plan '
        '(id TEXT NOT NULL PRIMARY KEY, category TEXT NOT NULL)',
      );
      _db.execute('DELETE FROM temp.evict_plan');

      // Categories are planned in EventEvictionPlanner order, INSERT OR IGNORE
      // keeps the first one an event gets.
      void plan(
        String category,
        String select, [
        List<Object?> args = const [],
      ]) {
        _db.execute(
          'INSERT OR IGNORE INTO temp.evict_plan (id, category) '
          'SELECT id, ? FROM ($select)',
          [category, ...args],
        );
      }

      plan(
        'locked',
        'SELECT e.id FROM events e WHERE e.id IN ('
            'SELECT event_id FROM event_delivery_records WHERE status != ? '
            'UNION SELECT event_id FROM relay_delivery_targets WHERE state != ?)',
        [EventDeliveryStatus.delivered.name, RelayDeliveryState.acked.name],
      );
      if (policy.sweepExpired) {
        plan(
          'expired',
          'SELECT e.id FROM events e WHERE ${expiredSql('e', now)}',
        );
      }
      if (policy.sweepDeleted) {
        plan(
          'deleted',
          'SELECT e.id FROM deletion_targets x JOIN events e '
              'ON e.id = x.event_id AND e.pub_key = x.pub_key WHERE e.kind != 5 '
              'UNION SELECT e.id FROM deletion_targets x JOIN events e '
              'ON e.conflict_key = x.conflict_key AND e.pub_key = x.pub_key '
              'AND e.created_at <= x.created_at WHERE e.kind != 5',
        );
      }
      if (policy.sweepSuperseded) {
        plan(
          'superseded',
          'SELECT e.id FROM events e WHERE e.conflict_key IS NOT NULL '
              'AND NOT ${currentSql('e', now)}',
        );
      }
      if (policy.sweepDeliveredEphemeral) {
        plan(
          'ephemeral',
          'SELECT e.id FROM events e WHERE e.kind BETWEEN 20000 AND 29999 '
              'AND e.id IN (SELECT event_id FROM event_delivery_records '
              'WHERE status = ?)',
          [EventDeliveryStatus.delivered.name],
        );
      }

      const unplanned = 'e.id NOT IN (SELECT id FROM temp.evict_plan)';
      const protectedSql =
          '(e.id IN $jsonArray OR e.pub_key IN $jsonArray '
          'OR e.kind IN $jsonArray OR (e.kind BETWEEN 30000 AND 39999 '
          'AND e.conflict_key IN $jsonArray))';
      final protectedArgs = [
        jsonEncode(policy.protectedEventIds.toList()),
        jsonEncode(policy.protectedPubKeys.toList()),
        jsonEncode(policy.protectedKinds.toList()),
        jsonEncode(policy.protectedCoordinates.toList()),
      ];
      final keptProtected =
          _db
                  .select(
                    'SELECT count(*) AS n FROM events e WHERE $unplanned '
                    'AND $protectedSql AND ${currentSql('e', now)}',
                    protectedArgs,
                  )
                  .first['n']
              as int;
      for (final MapEntry(key: kind, value: cap) in policy.kindCaps.entries) {
        if (cap < 0) continue;
        plan(
          'cap',
          'SELECT e.id FROM events e WHERE e.kind = ? AND $unplanned '
              'AND NOT $protectedSql AND ${currentSql('e', now)} '
              'ORDER BY e.created_at DESC, e.id LIMIT -1 OFFSET ?',
          [kind, ...protectedArgs, cap],
        );
      }

      final counts = {
        for (final row in _db.select(
          'SELECT category, count(*) AS n FROM temp.evict_plan GROUP BY category',
        ))
          row['category'] as String: row['n'] as int,
      };
      _removeEventsWhere(
        SqlWhere()..add(
          'e.id IN (SELECT id FROM temp.evict_plan WHERE category != ?)',
          ['locked'],
        ),
      );
      _db.execute('DELETE FROM temp.evict_plan');

      // Runs after the events are gone, so it only sees the delivery records
      // of kept events, as EventEvictionPlanner.planDeliverySweep expects.
      var removedCompletedDeliveries = 0;
      if (policy.sweepCompletedDeliveries) {
        removedCompletedDeliveries = _removeDeliveryRecordsWhere(
          'status = ? AND ? - COALESCE(completed_at, updated_at) >= ?',
          [
            EventDeliveryStatus.delivered.name,
            now,
            policy.completedDeliveryRetention.inSeconds,
          ],
        );
      }
      var removedTerminalFailedDeliveries = 0;
      if (policy.sweepTerminalFailedDeliveries) {
        removedTerminalFailedDeliveries =
            _removeDeliveryRecordsWhere('status = ? AND ? - updated_at >= ?', [
              EventDeliveryStatus.failed.name,
              now,
              policy.terminalFailedDeliveryRetention.inSeconds,
            ]);
      }

      final removedExpired = counts['expired'] ?? 0;
      final removedDeleted = counts['deleted'] ?? 0;
      final removedSuperseded = counts['superseded'] ?? 0;
      final removedDeliveredEphemeral = counts['ephemeral'] ?? 0;
      final removedByKindCap = counts['cap'] ?? 0;
      return EvictionResult(
        removedEvents:
            removedExpired +
            removedDeleted +
            removedSuperseded +
            removedDeliveredEphemeral +
            removedByKindCap,
        removedExpired: removedExpired,
        removedDeleted: removedDeleted,
        removedSuperseded: removedSuperseded,
        removedDeliveredEphemeral: removedDeliveredEphemeral,
        removedByKindCap: removedByKindCap,
        keptDueToDeliveryState: counts['locked'] ?? 0,
        keptProtected: keptProtected,
        removedCompletedDeliveries: removedCompletedDeliveries,
        removedTerminalFailedDeliveries: removedTerminalFailedDeliveries,
      );
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
  }) {
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

  int _writeEvents(List<Nip01Event> events, {required bool overwrite}) {
    if (events.isEmpty) return 0;
    return _transaction(() {
      final insertEvent = _db.prepare(
        'INSERT OR IGNORE INTO events (id, pub_key, kind, created_at, content, '
        'tags, sig, valid_sig, sources, conflict_key, expiration) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      );
      final deleteEvent = _db.prepare('DELETE FROM events WHERE id = ?');
      final insertTag = _db.prepare(
        'INSERT INTO event_tags (event_id, name, value) VALUES (?, ?, ?)',
      );
      final insertDeletionTarget = _db.prepare(
        'INSERT INTO deletion_targets '
        '(deletion_id, pub_key, created_at, event_id, conflict_key) '
        'VALUES (?, ?, ?, ?, ?)',
      );
      try {
        var written = 0;
        for (final event in events) {
          final row = _eventRow(event);
          insertEvent.execute(row);
          if (_db.updatedRows == 0) {
            if (!overwrite) continue;
            // cascades to the derived tag and deletion rows
            deleteEvent.execute([event.id]);
            insertEvent.execute(row);
          }
          written++;

          for (final tag in event.tags) {
            if (tag.isEmpty) continue;
            insertTag.execute([
              event.id,
              tag[0],
              tag.length > 1 ? tag[1].trim().toLowerCase() : null,
            ]);
          }
          if (event.kind != Deletion.kKind) continue;
          // the same normalization as EventCacheStateRecord._findDeletingEvent
          for (final tag in event.tags) {
            if (tag.length < 2) continue;
            if (tag[0] == 'e') {
              insertDeletionTarget.execute([
                event.id,
                event.pubKey,
                event.createdAt,
                tag[1].trim().toLowerCase(),
                null,
              ]);
            } else if (tag[0] == 'a') {
              final conflictKey = EventCacheStateRecord.normalizeConflictKey(
                tag[1],
              );
              if (conflictKey == null) continue;
              insertDeletionTarget.execute([
                event.id,
                event.pubKey,
                event.createdAt,
                null,
                conflictKey,
              ]);
            }
          }
        }
        return written;
      } finally {
        insertEvent.close();
        deleteEvent.close();
        insertTag.close();
        insertDeletionTarget.close();
      }
    });
  }

  List<Object?> _eventRow(Nip01Event event) {
    final expiration = event.getFirstTag('expiration');
    return [
      event.id,
      event.pubKey,
      event.kind,
      event.createdAt,
      event.content,
      jsonEncode(event.tags),
      event.sig,
      event.validSig,
      // ignore: deprecated_member_use
      jsonEncode(event.sources),
      EventCacheStateRecord.conflictKeyFor(event),
      expiration == null ? null : int.tryParse(expiration),
    ];
  }

  Nip01Event _eventFromRow(Row row) {
    final validSig = row['valid_sig'] as int?;
    return Nip01Event(
      id: row['id'] as String,
      pubKey: row['pub_key'] as String,
      kind: row['kind'] as int,
      createdAt: row['created_at'] as int,
      content: row['content'] as String,
      sig: row['sig'] as String?,
      validSig: validSig == null ? null : validSig == 1,
      tags: [
        for (final tag in jsonDecode(row['tags'] as String) as List)
          [for (final value in tag as List) value as String],
      ],
      sources: [
        for (final source in jsonDecode(row['sources'] as String) as List)
          source as String,
      ],
    );
  }

  List<Nip01Event> _selectEvents(SqlWhere where, {int? limit}) {
    final args = [...where.args];
    var sql =
        'SELECT $eventColumns FROM events e WHERE $where '
        'ORDER BY e.created_at DESC, e.id';
    if (limit != null && limit > 0) {
      sql += ' LIMIT ?';
      args.add(limit);
    }
    return _db.select(sql, args).map(_eventFromRow).toList();
  }

  /// The latest visible event of [kind] per author in [pubKeys].
  Map<String, Nip01Event> _loadLatestVisibleEvents(
    List<String> pubKeys,
    int kind,
  ) {
    if (pubKeys.isEmpty) return {};
    final where = eventFilter(pubKeys: pubKeys, kinds: [kind])
      ..add(visibleSql('e', _now()));
    final latest = <String, Nip01Event>{};
    for (final event in _selectEvents(where)) {
      latest.putIfAbsent(event.pubKey, () => event);
    }
    return latest;
  }

  /// Removes the events matching [where] (table aliased `e`) with their
  /// sidecars, and refreshes the relay list projections they fed.
  void _removeEventsWhere(SqlWhere where) {
    final ids = 'SELECT e.id FROM events e WHERE $where';
    _transaction(() {
      // Hidden events never feed the projection, which skips the superseded
      // and deleted versions an eviction removes in bulk.
      final relayListAuthors = _db
          .select(
            'SELECT DISTINCT e.pub_key FROM events e WHERE $where '
            'AND e.kind IN (${ContactList.kKind}, ${Nip65.kKind}) '
            'AND ${visibleSql('e', _now())}',
            where.args,
          )
          .map((row) => row['pub_key'] as String)
          .toList();
      for (final table in _eventSidecarTables) {
        _db.execute('DELETE FROM $table WHERE event_id IN ($ids)', where.args);
      }
      _db.execute('DELETE FROM events WHERE id IN ($ids)', where.args);
      relayListAuthors.forEach(_syncUserRelayListProjection);
    });
  }

  // =====================
  // Metadata
  // =====================

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    _writeEvents([metadata.toEvent()], overwrite: true);
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    _writeEvents([for (final m in metadatas) m.toEvent()], overwrite: true);
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    return (await loadMetadatas([pubKey])).single;
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    final latest = _loadLatestVisibleEvents(pubKeys, Metadata.kKind);
    final now = _now();
    return [
      for (final pubKey in pubKeys)
        latest[pubKey] == null
            ? null
            : (Metadata.fromEvent(latest[pubKey]!)..refreshedTimestamp = now),
    ];
  }

  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    final normalizedSearch = search.trim().toLowerCase();
    final where = eventFilter(kinds: [Metadata.kKind])
      ..add(visibleSql('e', _now()));
    // LIKE folds ASCII case only, so only an ASCII search can narrow rows
    // before the exact match below.
    if (normalizedSearch.isNotEmpty &&
        normalizedSearch.codeUnits.every((unit) => unit < 128)) {
      where.add(contentContains, [likeContains(normalizedSearch)]);
    }

    final statement = _db.prepare(
      'SELECT $eventColumns FROM events e WHERE $where '
      'ORDER BY e.created_at DESC, e.id',
    );
    try {
      final cursor = statement.selectCursor(where.args);
      final matches = <Metadata>[];
      while (matches.length < limit && cursor.moveNext()) {
        final metadata = Metadata.fromEvent(_eventFromRow(cursor.current));
        if (normalizedSearch.isEmpty ||
            metadata.matchesSearch(normalizedSearch) ||
            (metadata.about?.toLowerCase().contains(normalizedSearch) ??
                false) ||
            (metadata.cleanNip05?.contains(normalizedSearch) ?? false)) {
          matches.add(metadata);
        }
      }
      return matches;
    } finally {
      statement.close();
    }
  }

  @override
  Future<void> removeMetadata(String pubKey) {
    return removeEvents(pubKeys: [pubKey], kinds: [Metadata.kKind]);
  }

  @override
  Future<void> removeAllMetadatas() {
    return removeEvents(kinds: [Metadata.kKind]);
  }

  // =====================
  // Contact Lists
  // =====================

  @override
  Future<void> saveContactList(ContactList contactList) async {
    _writeEvents([contactList.toEvent()], overwrite: true);
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    _writeEvents([for (final c in contactLists) c.toEvent()], overwrite: true);
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    final event = _loadLatestVisibleEvents([pubKey], ContactList.kKind)[pubKey];
    return event == null ? null : ContactList.fromEvent(event);
  }

  @override
  Future<void> removeContactList(String pubKey) {
    return removeEvents(pubKeys: [pubKey], kinds: [ContactList.kKind]);
  }

  @override
  Future<void> removeAllContactLists() {
    return removeEvents(kinds: [ContactList.kKind]);
  }

  // =====================
  // User Relay Lists
  // =====================

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    _writeUserRelayLists([userRelayList]);
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    _writeUserRelayLists(userRelayLists);
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    final derived = _deriveUserRelayList(pubKey);
    if (derived != null) return derived;
    final rows = _db.select(
      'SELECT data FROM user_relay_lists WHERE pub_key = ?',
      [pubKey],
    );
    if (rows.isEmpty) return null;
    return UserRelayListExtension.fromJsonStorage(
      jsonDecode(rows.first['data'] as String) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    _db.execute('DELETE FROM user_relay_lists WHERE pub_key = ?', [pubKey]);
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    _db.execute('DELETE FROM user_relay_lists');
  }

  void _writeUserRelayLists(List<UserRelayList> userRelayLists) {
    _executeBatch(
      'INSERT OR REPLACE INTO user_relay_lists (pub_key, data) VALUES (?, ?)',
      [
        for (final list in userRelayLists)
          [list.pubKey, jsonEncode(list.toJsonForStorage())],
      ],
    );
  }

  /// Kind 10002 wins over the relays of a kind 3 content.
  UserRelayList? _deriveUserRelayList(String pubKey) {
    final where = eventFilter(
      pubKeys: [pubKey],
      kinds: [Nip65.kKind, ContactList.kKind],
    )..add(visibleSql('e', _now()));
    final events = _selectEvents(where);

    for (final event in events) {
      if (event.kind == Nip65.kKind) {
        return UserRelayList.fromNip65(Nip65.fromEvent(event));
      }
    }
    for (final event in events) {
      if (ContactList.relaysFromContent(event).isNotEmpty) {
        return UserRelayList.fromNip02EventContent(event);
      }
    }
    return null;
  }

  void _syncUserRelayListProjection(String pubKey) {
    final derived = _deriveUserRelayList(pubKey);
    if (derived == null) {
      _db.execute('DELETE FROM user_relay_lists WHERE pub_key = ?', [pubKey]);
    } else {
      _writeUserRelayLists([derived]);
    }
  }

  // =====================
  // Relay Sets
  // =====================

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    _db.execute('INSERT OR REPLACE INTO relay_sets (id, data) VALUES (?, ?)', [
      relaySet.id,
      jsonEncode(relaySet.toJsonForStorage()),
    ]);
  }

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    final rows = _db.select('SELECT data FROM relay_sets WHERE id = ?', [
      RelaySet.buildId(name, pubKey),
    ]);
    if (rows.isEmpty) return null;
    return RelaySetExtension.fromJsonStorage(
      jsonDecode(rows.first['data'] as String) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    _db.execute('DELETE FROM relay_sets WHERE id = ?', [
      RelaySet.buildId(name, pubKey),
    ]);
  }

  @override
  Future<void> removeAllRelaySets() async {
    _db.execute('DELETE FROM relay_sets');
  }

  // =====================
  // NIP-05
  // =====================

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    _writeNip05s([nip05]);
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    _writeNip05s(nip05s);
  }

  @override
  Future<Nip05?> loadNip05({String? pubKey, String? identifier}) async {
    final ResultSet rows;
    if (pubKey != null) {
      rows = _db.select('SELECT data FROM nip05s WHERE pub_key = ?', [pubKey]);
    } else if (identifier != null) {
      rows = _db.select('SELECT data FROM nip05s WHERE nip05 = ? LIMIT 1', [
        identifier,
      ]);
    } else {
      return null;
    }
    return rows.isEmpty ? null : _nip05FromData(rows.first['data'] as String);
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    final byPubKey = {
      for (final row in _db.select(
        'SELECT pub_key, data FROM nip05s WHERE pub_key IN $jsonArray',
        [jsonEncode(pubKeys)],
      ))
        row['pub_key'] as String: _nip05FromData(row['data'] as String),
    };
    return [for (final pubKey in pubKeys) byPubKey[pubKey]];
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    _db.execute('DELETE FROM nip05s WHERE pub_key = ?', [pubKey]);
  }

  @override
  Future<void> removeAllNip05s() async {
    _db.execute('DELETE FROM nip05s');
  }

  void _writeNip05s(List<Nip05> nip05s) {
    _executeBatch(
      'INSERT OR REPLACE INTO nip05s (pub_key, nip05, data) VALUES (?, ?, ?)',
      [
        for (final nip05 in nip05s)
          [nip05.pubKey, nip05.nip05, jsonEncode(nip05.toJsonForStorage())],
      ],
    );
  }

  Nip05 _nip05FromData(String data) {
    return Nip05Extension.fromJsonStorage(
      jsonDecode(data) as Map<String, dynamic>,
    );
  }

  // =====================
  // Filter Fetched Ranges
  // =====================

  @override
  Future<void> saveFilterFetchedRangeRecord(
    FilterFetchedRangeRecord record,
  ) async {
    _writeFilterFetchedRangeRecords([record]);
  }

  @override
  Future<void> saveFilterFetchedRangeRecords(
    List<FilterFetchedRangeRecord> records,
  ) async {
    _writeFilterFetchedRangeRecords(records);
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
    String filterHash,
  ) async {
    return _selectFilterFetchedRangeRecords('filter_hash = ?', [filterHash]);
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
    String filterHash,
    String relayUrl,
  ) async {
    return _selectFilterFetchedRangeRecords(
      'filter_hash = ? AND relay_url = ?',
      [filterHash, relayUrl],
    );
  }

  @override
  Future<List<FilterFetchedRangeRecord>>
  loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl) async {
    return _selectFilterFetchedRangeRecords('relay_url = ?', [relayUrl]);
  }

  @override
  Future<void> removeFilterFetchedRangeRecords(String filterHash) async {
    _db.execute('DELETE FROM filter_fetched_ranges WHERE filter_hash = ?', [
      filterHash,
    ]);
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
    String filterHash,
    String relayUrl,
  ) async {
    _db.execute(
      'DELETE FROM filter_fetched_ranges WHERE filter_hash = ? AND relay_url = ?',
      [filterHash, relayUrl],
    );
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl) async {
    _db.execute('DELETE FROM filter_fetched_ranges WHERE relay_url = ?', [
      relayUrl,
    ]);
  }

  @override
  Future<void> removeAllFilterFetchedRangeRecords() async {
    _db.execute('DELETE FROM filter_fetched_ranges');
  }

  void _writeFilterFetchedRangeRecords(List<FilterFetchedRangeRecord> records) {
    _executeBatch(
      'INSERT OR REPLACE INTO filter_fetched_ranges '
      '(key, filter_hash, relay_url, range_start, range_end) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        for (final record in records)
          [
            record.key,
            record.filterHash,
            record.relayUrl,
            record.rangeStart,
            record.rangeEnd,
          ],
      ],
    );
  }

  List<FilterFetchedRangeRecord> _selectFilterFetchedRangeRecords(
    String where,
    List<Object?> args,
  ) {
    return [
      for (final row in _db.select(
        'SELECT filter_hash, relay_url, range_start, range_end '
        'FROM filter_fetched_ranges WHERE $where',
        args,
      ))
        FilterFetchedRangeRecord(
          filterHash: row['filter_hash'] as String,
          relayUrl: row['relay_url'] as String,
          rangeStart: row['range_start'] as int,
          rangeEnd: row['range_end'] as int,
        ),
    ];
  }

  // =====================
  // Event Sources
  // =====================

  @override
  Future<void> addEventSource({
    required String eventId,
    required String relayUrl,
  }) async {
    _db.execute(
      'INSERT OR IGNORE INTO event_sources (event_id, relay_url) VALUES (?, ?)',
      [eventId, relayUrl],
    );
  }

  @override
  Future<void> addEventSources({
    required String eventId,
    required Iterable<String> relayUrls,
  }) async {
    _executeBatch(
      'INSERT OR IGNORE INTO event_sources (event_id, relay_url) VALUES (?, ?)',
      [
        for (final relayUrl in relayUrls) [eventId, relayUrl],
      ],
    );
  }

  @override
  Future<List<String>> loadEventSources(String eventId) async {
    return [
      for (final row in _db.select(
        'SELECT relay_url FROM event_sources WHERE event_id = ? '
        'ORDER BY relay_url',
        [eventId],
      ))
        row['relay_url'] as String,
    ];
  }

  @override
  Future<void> removeEventSources(String eventId) async {
    _db.execute('DELETE FROM event_sources WHERE event_id = ?', [eventId]);
  }

  // =====================
  // Event Delivery Records
  // =====================

  @override
  Future<void> saveEventDeliveryRecord(EventDeliveryRecord record) async {
    _writeEventDeliveryRecords([record]);
  }

  @override
  Future<void> saveEventDeliveryRecords(
    List<EventDeliveryRecord> records,
  ) async {
    _writeEventDeliveryRecords(records);
  }

  @override
  Future<EventDeliveryRecord?> loadEventDeliveryRecord(String eventId) async {
    final rows = _db.select(
      'SELECT record FROM event_delivery_records WHERE event_id = ?',
      [eventId],
    );
    return rows.isEmpty
        ? null
        : _eventDeliveryRecordFromJson(rows.first['record'] as String);
  }

  @override
  Future<List<EventDeliveryRecord>> loadEventDeliveryRecords({
    EventDeliveryStatus? status,
    int? limit,
  }) async {
    final where = SqlWhere();
    if (status != null) where.add('status = ?', [status.name]);
    final args = [...where.args];
    var sql = 'SELECT record FROM event_delivery_records WHERE $where';
    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
    }
    return [
      for (final row in _db.select(sql, args))
        _eventDeliveryRecordFromJson(row['record'] as String),
    ];
  }

  @override
  Future<void> removeEventDeliveryRecord(String eventId) async {
    _db.execute('DELETE FROM event_delivery_records WHERE event_id = ?', [
      eventId,
    ]);
  }

  @override
  Future<void> removeAllEventDeliveryRecords() async {
    _db.execute('DELETE FROM event_delivery_records');
  }

  void _writeEventDeliveryRecords(List<EventDeliveryRecord> records) {
    _executeBatch(
      'INSERT OR REPLACE INTO event_delivery_records '
      '(event_id, status, updated_at, completed_at, record) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        for (final record in records)
          [
            record.eventId,
            record.status.name,
            record.updatedAt,
            record.completedAt,
            jsonEncode(record.toJson()),
          ],
      ],
    );
  }

  EventDeliveryRecord _eventDeliveryRecordFromJson(String json) {
    return EventDeliveryRecord.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  /// Removes the delivery records matching [where] with their relay targets,
  /// returning how many records went.
  int _removeDeliveryRecordsWhere(String where, List<Object?> args) {
    _db.execute(
      'DELETE FROM relay_delivery_targets WHERE event_id IN '
      '(SELECT event_id FROM event_delivery_records WHERE $where)',
      args,
    );
    _db.execute('DELETE FROM event_delivery_records WHERE $where', args);
    return _db.updatedRows;
  }

  // =====================
  // Relay Delivery Targets
  // =====================

  @override
  Future<void> saveRelayDeliveryTarget(RelayDeliveryTarget target) async {
    _writeRelayDeliveryTargets([target]);
  }

  @override
  Future<void> saveRelayDeliveryTargets(
    List<RelayDeliveryTarget> targets,
  ) async {
    _writeRelayDeliveryTargets(targets);
  }

  @override
  Future<RelayDeliveryTarget?> loadRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    final rows = _db.select(
      'SELECT target FROM relay_delivery_targets '
      'WHERE event_id = ? AND relay_url = ?',
      [eventId, relayUrl],
    );
    return rows.isEmpty
        ? null
        : _relayDeliveryTargetFromJson(rows.first['target'] as String);
  }

  @override
  Future<List<RelayDeliveryTarget>> loadRelayDeliveryTargets({
    String? eventId,
    String? relayUrl,
    RelayDeliveryState? state,
    bool excludeAcked = false,
    int? limit,
  }) async {
    final where = SqlWhere();
    if (eventId != null) where.add('event_id = ?', [eventId]);
    if (relayUrl != null) where.add('relay_url = ?', [relayUrl]);
    if (state != null) where.add('state = ?', [state.name]);
    if (excludeAcked) where.add('state != ?', [RelayDeliveryState.acked.name]);
    final args = [...where.args];
    var sql =
        'SELECT target FROM relay_delivery_targets WHERE $where '
        'ORDER BY next_retry_at, event_id, relay_url';
    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
    }
    return [
      for (final row in _db.select(sql, args))
        _relayDeliveryTargetFromJson(row['target'] as String),
    ];
  }

  @override
  Future<void> removeRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    _db.execute(
      'DELETE FROM relay_delivery_targets WHERE event_id = ? AND relay_url = ?',
      [eventId, relayUrl],
    );
  }

  @override
  Future<void> removeRelayDeliveryTargets(String eventId) async {
    _db.execute('DELETE FROM relay_delivery_targets WHERE event_id = ?', [
      eventId,
    ]);
  }

  @override
  Future<void> removeAllRelayDeliveryTargets() async {
    _db.execute('DELETE FROM relay_delivery_targets');
  }

  void _writeRelayDeliveryTargets(List<RelayDeliveryTarget> targets) {
    _executeBatch(
      'INSERT OR REPLACE INTO relay_delivery_targets '
      '(event_id, relay_url, state, next_retry_at, target) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        for (final target in targets)
          [
            target.eventId,
            target.relayUrl,
            target.state.name,
            target.nextRetryAt,
            jsonEncode(target.toJson()),
          ],
      ],
    );
  }

  RelayDeliveryTarget _relayDeliveryTargetFromJson(String json) {
    return RelayDeliveryTarget.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  // =====================
  // Decrypted Payloads
  // =====================

  @override
  Future<void> saveDecryptedEventPayloadRecord(
    DecryptedEventPayloadRecord record,
  ) async {
    _writeDecryptedPayloads([record]);
  }

  @override
  Future<void> saveDecryptedEventPayloadRecords(
    List<DecryptedEventPayloadRecord> records,
  ) async {
    _writeDecryptedPayloads(records);
  }

  @override
  Future<DecryptedEventPayloadRecord?> loadDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  }) async {
    final rows = _db.select(
      'SELECT record FROM decrypted_payloads '
      'WHERE event_id = ? AND viewer_pub_key = ?',
      [eventId, viewerPubKey],
    );
    return rows.isEmpty
        ? null
        : _decryptedPayloadFromJson(rows.first['record'] as String);
  }

  @override
  Future<List<DecryptedEventPayloadRecord>> loadDecryptedEventPayloadRecords({
    String? eventId,
    String? viewerPubKey,
    DecryptedPayloadStatus? status,
    int? limit,
  }) async {
    final where = SqlWhere();
    if (eventId != null) where.add('event_id = ?', [eventId]);
    if (viewerPubKey != null) where.add('viewer_pub_key = ?', [viewerPubKey]);
    if (status != null) where.add('status = ?', [status.name]);
    final args = [...where.args];
    var sql =
        'SELECT record FROM decrypted_payloads WHERE $where '
        'ORDER BY updated_at DESC';
    if (limit != null && limit > 0) {
      sql += ' LIMIT ?';
      args.add(limit);
    }
    return [
      for (final row in _db.select(sql, args))
        _decryptedPayloadFromJson(row['record'] as String),
    ];
  }

  @override
  Future<void> removeDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  }) async {
    _db.execute(
      'DELETE FROM decrypted_payloads WHERE event_id = ? AND viewer_pub_key = ?',
      [eventId, viewerPubKey],
    );
  }

  @override
  Future<void> removeDecryptedEventPayloadRecords(String eventId) async {
    _db.execute('DELETE FROM decrypted_payloads WHERE event_id = ?', [eventId]);
  }

  @override
  Future<void> removeAllDecryptedEventPayloadRecords() async {
    _db.execute('DELETE FROM decrypted_payloads');
  }

  void _writeDecryptedPayloads(List<DecryptedEventPayloadRecord> records) {
    _executeBatch(
      'INSERT OR REPLACE INTO decrypted_payloads '
      '(event_id, viewer_pub_key, status, updated_at, record) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        for (final record in records)
          [
            record.eventId,
            record.viewerPubKey,
            record.status.name,
            record.updatedAt,
            jsonEncode(record.toJson()),
          ],
      ],
    );
  }

  DecryptedEventPayloadRecord _decryptedPayloadFromJson(String json) {
    return DecryptedEventPayloadRecord.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  // =====================
  // Cashu
  // =====================

  @override
  Future<void> saveKeyset(CahsuKeyset keyset) async {
    _db.execute(
      'INSERT OR REPLACE INTO cashu_keysets (id, mint_url, data) '
      'VALUES (?, ?, ?)',
      [keyset.id, keyset.mintUrl, jsonEncode(keyset.toJsonForStorage())],
    );
  }

  @override
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl}) async {
    final where = SqlWhere();
    if (mintUrl != null) where.add('mint_url = ?', [mintUrl]);
    return [
      for (final row in _db.select(
        'SELECT data FROM cashu_keysets WHERE $where',
        where.args,
      ))
        CahsuKeysetExtension.fromJsonStorage(
          jsonDecode(row['data'] as String) as Map<String, dynamic>,
        ),
    ];
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    _executeBatch(
      'INSERT OR REPLACE INTO cashu_proofs '
      '(y, mint_url, keyset_id, state, amount, secret, unblinded_sig) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        for (final proof in proofs)
          [
            proof.Y,
            mintUrl,
            proof.keysetId,
            proof.state.value,
            proof.amount,
            proof.secret,
            proof.unblindedSig,
          ],
      ],
    );
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  }) async {
    final where = SqlWhere()..add('state = ?', [state.value]);
    if (mintUrl != null) where.add('mint_url = ?', [mintUrl]);
    if (keysetId != null) where.add('keyset_id = ?', [keysetId]);
    return [
      for (final row in _db.select(
        'SELECT keyset_id, amount, secret, unblinded_sig, state '
        'FROM cashu_proofs WHERE $where',
        where.args,
      ))
        CashuProof(
          keysetId: row['keyset_id'] as String,
          amount: row['amount'] as int,
          secret: row['secret'] as String,
          unblindedSig: row['unblinded_sig'] as String,
          state: CashuProofState.fromValue(row['state'] as String),
        ),
    ];
  }

  @override
  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    _db.execute(
      'DELETE FROM cashu_proofs WHERE mint_url = ? AND y IN $jsonArray',
      [
        mintUrl,
        jsonEncode([for (final proof in proofs) proof.Y]),
      ],
    );
  }

  @override
  Future<void> saveMintInfo({required CashuMintInfo mintInfo}) async {
    _db.execute(
      'INSERT OR REPLACE INTO cashu_mint_infos (id, data) VALUES (?, ?)',
      [
        mintInfo.urls.isNotEmpty ? mintInfo.urls.first : '',
        jsonEncode(mintInfo.toJsonForStorage()),
      ],
    );
  }

  @override
  Future<void> removeMintInfo({required String mintUrl}) async {
    _db.execute('DELETE FROM cashu_mint_infos WHERE id = ?', [mintUrl]);
  }

  @override
  Future<List<CashuMintInfo>?> getMintInfos({List<String>? mintUrls}) async {
    final where = SqlWhere();
    if (mintUrls != null && mintUrls.isNotEmpty) {
      where.add('id IN $jsonArray', [jsonEncode(mintUrls)]);
    }
    final rows = _db.select(
      'SELECT data FROM cashu_mint_infos WHERE $where',
      where.args,
    );
    if (rows.isEmpty) return null;
    return [
      for (final row in rows)
        CashuMintInfoExtension.fromJsonStorage(
          jsonDecode(row['data'] as String) as Map<String, dynamic>,
        ),
    ];
  }

  @override
  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  }) async {
    final rows = _db.select(
      'SELECT counter FROM cashu_secret_counters '
      'WHERE mint_url = ? AND keyset_id = ?',
      [mintUrl, keysetId],
    );
    return rows.isEmpty ? 0 : rows.first['counter'] as int;
  }

  @override
  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  }) async {
    _db.execute(
      'INSERT OR REPLACE INTO cashu_secret_counters '
      '(mint_url, keyset_id, counter) VALUES (?, ?, ?)',
      [mintUrl, keysetId, counter],
    );
  }

  // =====================
  // Wallets
  // =====================

  @override
  Future<void> storeWallet(Wallet wallet) async {
    _db.execute(
      'INSERT OR REPLACE INTO wallets '
      '(id, name, type, supported_units, metadata) VALUES (?, ?, ?, ?, ?)',
      [
        wallet.id,
        wallet.name,
        wallet.type.name,
        jsonEncode(wallet.supportedUnits.toList()),
        jsonEncode(wallet.toMetadata()),
      ],
    );
  }

  @override
  Future<void> removeWallet(String id) async {
    _db.execute('DELETE FROM wallets WHERE id = ?', [id]);
    if (_defaultWalletIdForReceiving == id) setDefaultWalletForReceiving(null);
    if (_defaultWalletIdForSending == id) setDefaultWalletForSending(null);
  }

  @override
  Future<List<Wallet>> getWallets({List<String>? ids}) async {
    final where = SqlWhere();
    if (ids != null && ids.isNotEmpty) {
      where.add('id IN $jsonArray', [jsonEncode(ids)]);
    }
    return [
      for (final row in _db.select(
        'SELECT id, name, type, supported_units, metadata FROM wallets '
        'WHERE $where',
        where.args,
      ))
        WalletFactory.fromStorage(
          id: row['id'] as String,
          name: row['name'] as String,
          type: _walletType(row['type'] as String),
          supportedUnits: {
            for (final unit
                in jsonDecode(row['supported_units'] as String) as List)
              unit as String,
          },
          metadata:
              jsonDecode(row['metadata'] as String) as Map<String, dynamic>,
        ),
    ];
  }

  @override
  String? getDefaultWalletIdForReceiving() => _defaultWalletIdForReceiving;

  @override
  String? getDefaultWalletIdForSending() => _defaultWalletIdForSending;

  @override
  void setDefaultWalletForReceiving(String? walletId) {
    _defaultWalletIdForReceiving = walletId;
    _storeKeyValue(_defaultWalletForReceivingKey, walletId);
  }

  @override
  void setDefaultWalletForSending(String? walletId) {
    _defaultWalletIdForSending = walletId;
    _storeKeyValue(_defaultWalletForSendingKey, walletId);
  }

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) async {
    _executeBatch(
      'INSERT OR REPLACE INTO wallet_transactions (id, wallet_id, '
      'change_amount, unit, type, state, completion_msg, transaction_date, '
      'initiated_date, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        for (final transaction in transactions)
          [
            transaction.id,
            transaction.walletId,
            transaction.changeAmount,
            transaction.unit,
            transaction.walletType.name,
            transaction.state.value,
            transaction.completionMsg,
            transaction.transactionDate,
            transaction.initiatedDate,
            jsonEncode(transaction.metadata),
          ],
      ],
    );
  }

  @override
  Future<void> removeTransactions(List<String>? transactionIds) async {
    if (transactionIds == null || transactionIds.isEmpty) {
      _db.execute('DELETE FROM wallet_transactions');
      return;
    }
    _db.execute('DELETE FROM wallet_transactions WHERE id IN $jsonArray', [
      jsonEncode(transactionIds),
    ]);
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) async {
    final where = SqlWhere();
    if (walletId != null) where.add('wallet_id = ?', [walletId]);
    if (unit != null) where.add('unit = ?', [unit]);
    if (walletType != null) where.add('type = ?', [walletType.name]);
    final args = [...where.args];
    var sql =
        'SELECT * FROM wallet_transactions WHERE $where '
        'ORDER BY initiated_date DESC';
    if (limit != null && limit > 0) {
      sql += ' LIMIT ? OFFSET ?';
      args.addAll([limit, offset != null && offset > 0 ? offset : 0]);
    }
    return [
      for (final row in _db.select(sql, args))
        WalletTransaction.toTransactionType(
          id: row['id'] as String,
          walletId: row['wallet_id'] as String,
          changeAmount: row['change_amount'] as int,
          unit: row['unit'] as String,
          walletType: _walletType(row['type'] as String),
          state: WalletTransactionState.fromValue(row['state'] as String),
          metadata:
              jsonDecode(row['metadata'] as String) as Map<String, dynamic>,
          completionMsg: row['completion_msg'] as String?,
          transactionDate: row['transaction_date'] as int?,
          initiatedDate: row['initiated_date'] as int?,
        ),
    ];
  }

  WalletType _walletType(String name) {
    return WalletType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => WalletType.CASHU,
    );
  }

  String? _getKeyValue(String key) {
    final rows = _db.select('SELECT value FROM key_values WHERE key = ?', [
      key,
    ]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  void _storeKeyValue(String key, String? value) {
    _db.execute(
      'INSERT OR REPLACE INTO key_values (key, value) VALUES (?, ?)',
      [key, value],
    );
  }

  // =====================
  // Clear All
  // =====================

  @override
  Future<void> clearAll() async {
    _transaction(() {
      for (final table in [
        'event_tags',
        'deletion_targets',
        'events',
        ..._eventSidecarTables,
        'user_relay_lists',
        'relay_sets',
        'nip05s',
        'filter_fetched_ranges',
        'cashu_keysets',
        'cashu_proofs',
        'cashu_mint_infos',
        'cashu_secret_counters',
        'wallets',
        'wallet_transactions',
        'key_values',
      ]) {
        _db.execute('DELETE FROM $table');
      }
    });
    _defaultWalletIdForReceiving = null;
    _defaultWalletIdForSending = null;
  }

  // =====================
  // Helpers
  // =====================

  int _now() => Nip01Event.secondsSinceEpoch();

  /// Runs [action] in a transaction, or inside the one already open.
  T _transaction<T>(T Function() action) {
    if (!_db.autocommit) return action();
    _db.execute('BEGIN IMMEDIATE');
    try {
      final result = action();
      _db.execute('COMMIT');
      return result;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void _executeBatch(String sql, List<List<Object?>> rows) {
    if (rows.isEmpty) return;
    _transaction(() {
      final statement = _db.prepare(sql);
      try {
        for (final row in rows) {
          statement.execute(row);
        }
      } finally {
        statement.close();
      }
    });
  }
}
