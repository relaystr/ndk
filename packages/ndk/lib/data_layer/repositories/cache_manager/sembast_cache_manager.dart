import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:sembast/sembast.dart' as sembast;
import '../../../shared/nips/nip01/event_kind_classification.dart';
import 'ndk_extensions.dart';

// Platform-specific imports
import 'sembast_cache_manager_platform.dart';

class SembastCacheManager extends CacheManager {
  /// Creates a new [SembastCacheManager] instance.
  ///
  /// Platform-specific behavior:
  /// - **Web platform**: [databasePath] is ignored. The database is stored in
  ///   IndexedDB using [databaseName] as the database name.
  /// - **Native platforms** (Android, iOS, macOS, Linux, Windows): [databasePath]
  ///   is required. The database file is created at `{databasePath}/{databaseName}.db`.
  ///
  /// Parameters:
  /// - [databasePath]: Required on native platforms, ignored on web.
  /// - [databaseName]: Name of the database. Defaults to "sembast_cache_manager".
  ///
  /// Throws [ArgumentError] on native platforms if [databasePath] is null or empty.
  static Future<SembastCacheManager> create({
    String? databasePath,
    String databaseName = "sembast_cache_manager",
  }) async {
    final database = await openDatabase(
      databasePath: databasePath,
      databaseName: databaseName,
    );

    return SembastCacheManager(database);
  }

  final sembast.Database _database;

  late final sembast.StoreRef<String, Map<String, Object?>> _eventsStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _eventSourceStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _eventDeliveryStore;
  late final sembast.StoreRef<String, Map<String, Object?>>
      _relayDeliveryTargetStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _metadataStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _contactListStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _relayListStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _nip05Store;
  late final sembast.StoreRef<String, Map<String, Object?>> _relaySetStore;
  late final sembast.StoreRef<String, Map<String, Object?>>
      _filterFetchedRangeStore;

  late final sembast.StoreRef<String, Map<String, Object?>> _keysetStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _proofStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _mintInfoStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _secretCounterStore;

  SembastCacheManager(this._database) {
    _eventsStore = sembast.stringMapStoreFactory.store('events');
    _eventSourceStore = sembast.stringMapStoreFactory.store('event_sources');
    _eventDeliveryStore =
        sembast.stringMapStoreFactory.store('event_delivery_records');
    _relayDeliveryTargetStore =
        sembast.stringMapStoreFactory.store('relay_delivery_targets');
    _metadataStore = sembast.stringMapStoreFactory.store('metadata');
    _contactListStore = sembast.stringMapStoreFactory.store('contact_lists');
    _relayListStore = sembast.stringMapStoreFactory.store('relay_lists');
    _nip05Store = sembast.stringMapStoreFactory.store('nip05');
    _relaySetStore = sembast.stringMapStoreFactory.store('relay_sets');
    _keysetStore = sembast.stringMapStoreFactory.store('keysets');
    _proofStore = sembast.stringMapStoreFactory.store('proofs');
    _mintInfoStore = sembast.stringMapStoreFactory.store('mint_infos');
    _secretCounterStore =
        sembast.stringMapStoreFactory.store('secret_counters');
    _filterFetchedRangeStore =
        sembast.stringMapStoreFactory.store('filter_fetched_ranges');
  }

  @override
  Future<void> close() async {
    await _database.close();
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    final data = await _contactListStore.record(pubKey).get(_database);
    if (data == null) return null;
    return ContactListExtension.fromJsonStorage(data);
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    final data = await _eventsStore.record(id).get(_database);
    if (data == null) return null;
    return Nip01EventExtension.fromJsonStorage(data);
  }

  @override
  Future<void> addEventSource({
    required String eventId,
    required String relayUrl,
  }) async {
    await addEventSources(eventId: eventId, relayUrls: [relayUrl]);
  }

  @override
  Future<void> addEventSources({
    required String eventId,
    required Iterable<String> relayUrls,
  }) async {
    for (final relayUrl in relayUrls) {
      await _eventSourceStore.record(_eventSourceKey(eventId, relayUrl)).put(
        _database,
        {
          'eventId': eventId,
          'relayUrl': relayUrl,
        },
      );
    }
  }

  @override
  Future<List<String>> loadEventSources(String eventId) async {
    final records = await _eventSourceStore.find(
      _database,
      finder: sembast.Finder(
        filter: sembast.Filter.equals('eventId', eventId),
      ),
    );

    final sources = records
        .map((record) => record.value['relayUrl'] as String)
        .toList()
      ..sort();
    return sources;
  }

  @override
  Future<void> removeEventSources(String eventId) async {
    await _eventSourceStore.delete(
      _database,
      finder: sembast.Finder(
        filter: sembast.Filter.equals('eventId', eventId),
      ),
    );
  }

  @override
  Future<void> saveEventDeliveryRecord(EventDeliveryRecord record) async {
    await _eventDeliveryStore
        .record(record.eventId)
        .put(_database, record.toJson().cast<String, Object?>());
  }

  @override
  Future<void> saveEventDeliveryRecords(
      List<EventDeliveryRecord> records) async {
    final keys = records.map((record) => record.eventId).toList();
    final values = records
        .map((record) => record.toJson().cast<String, Object?>())
        .toList();
    await _eventDeliveryStore.records(keys).put(_database, values);
  }

  @override
  Future<EventDeliveryRecord?> loadEventDeliveryRecord(String eventId) async {
    final data = await _eventDeliveryStore.record(eventId).get(_database);
    if (data == null) return null;
    return EventDeliveryRecord.fromJson(data);
  }

  @override
  Future<List<EventDeliveryRecord>> loadEventDeliveryRecords({
    EventDeliveryStatus? status,
    int? limit,
  }) async {
    final finder = sembast.Finder(
      filter:
          status != null ? sembast.Filter.equals('status', status.name) : null,
      sortOrders: [sembast.SortOrder('createdAt')],
      limit: limit,
    );
    final records = await _eventDeliveryStore.find(_database, finder: finder);
    return records
        .map((record) => EventDeliveryRecord.fromJson(record.value))
        .toList();
  }

  @override
  Future<void> removeEventDeliveryRecord(String eventId) async {
    await _eventDeliveryStore.record(eventId).delete(_database);
  }

  @override
  Future<void> removeAllEventDeliveryRecords() async {
    await _eventDeliveryStore.delete(_database);
  }

  @override
  Future<void> saveRelayDeliveryTarget(RelayDeliveryTargetRecord record) async {
    await _relayDeliveryTargetStore
        .record(record.key)
        .put(_database, record.toJson().cast<String, Object?>());
  }

  @override
  Future<void> saveRelayDeliveryTargets(
      List<RelayDeliveryTargetRecord> records) async {
    final keys = records.map((record) => record.key).toList();
    final values = records
        .map((record) => record.toJson().cast<String, Object?>())
        .toList();
    await _relayDeliveryTargetStore.records(keys).put(_database, values);
  }

  @override
  Future<RelayDeliveryTargetRecord?> loadRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    final data = await _relayDeliveryTargetStore
        .record(_eventSourceKey(eventId, relayUrl))
        .get(_database);
    if (data == null) return null;
    return RelayDeliveryTargetRecord.fromJson(data);
  }

  @override
  Future<List<RelayDeliveryTargetRecord>> loadRelayDeliveryTargets({
    String? eventId,
    String? relayUrl,
    RelayDeliveryState? state,
    bool excludeAcked = false,
    int? limit,
  }) async {
    final filters = <sembast.Filter>[];
    if (eventId != null) {
      filters.add(sembast.Filter.equals('eventId', eventId));
    }
    if (relayUrl != null) {
      filters.add(sembast.Filter.equals('relayUrl', relayUrl));
    }
    if (state != null) {
      filters.add(sembast.Filter.equals('state', state.name));
    }
    if (excludeAcked) {
      filters.add(
          sembast.Filter.notEquals('state', RelayDeliveryState.acked.name));
    }

    final finder = sembast.Finder(
      filter: filters.isNotEmpty ? sembast.Filter.and(filters) : null,
      sortOrders: [
        sembast.SortOrder('nextRetryAt'),
        sembast.SortOrder('eventId'),
        sembast.SortOrder('relayUrl'),
      ],
      limit: limit,
    );
    final records =
        await _relayDeliveryTargetStore.find(_database, finder: finder);
    return records
        .map((record) => RelayDeliveryTargetRecord.fromJson(record.value))
        .toList();
  }

  @override
  Future<void> removeRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    await _relayDeliveryTargetStore
        .record(_eventSourceKey(eventId, relayUrl))
        .delete(_database);
  }

  @override
  Future<void> removeRelayDeliveryTargets(String eventId) async {
    await _relayDeliveryTargetStore.delete(
      _database,
      finder: sembast.Finder(
        filter: sembast.Filter.equals('eventId', eventId),
      ),
    );
  }

  @override
  Future<void> removeAllRelayDeliveryTargets() async {
    await _relayDeliveryTargetStore.delete(_database);
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
    return _loadEventsInternal(
      ids: ids,
      pubKeys: pubKeys,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
      limit: limit,
      applyVisibilityRules: true,
    );
  }

  Future<List<Nip01Event>> _loadEventsInternal({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
    required bool applyVisibilityRules,
  }) async {
    // Build filter conditions
    final filters = <sembast.Filter>[];

    // Filter by event IDs
    if (ids != null && ids.isNotEmpty) {
      filters.add(sembast.Filter.inList('id', ids));
    }

    // Filter by authors (pubkeys)
    if (pubKeys != null && pubKeys.isNotEmpty) {
      filters.add(sembast.Filter.inList('pubkey', pubKeys));
    }

    // Filter by kinds
    if (kinds != null && kinds.isNotEmpty) {
      filters.add(sembast.Filter.inList('kind', kinds));
    }

    // Filter by time range
    if (since != null) {
      filters.add(sembast.Filter.greaterThanOrEquals('created_at', since));
    }

    if (until != null) {
      filters.add(sembast.Filter.lessThanOrEquals('created_at', until));
    }

    // Filter by content search
    if (search != null && search.isNotEmpty) {
      filters.add(sembast.Filter.matches('content', search));
    }

    final finder = sembast.Finder(
      filter: filters.isNotEmpty ? sembast.Filter.and(filters) : null,
      limit: limit,
      sortOrders: [sembast.SortOrder('created_at', false)],
    );

    final records = await _eventsStore.find(_database, finder: finder);
    final events = records
        .map((record) => Nip01EventExtension.fromJsonStorage(record.value))
        .toList();

    final visibleEvents = applyVisibilityRules
        ? await _applyEventVisibilityRules(events)
        : events;

    // Filter by tags if specified (done in memory since Sembast doesn't support complex tag filtering)
    if (tags != null && tags.isNotEmpty) {
      return visibleEvents.where((event) {
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

    return visibleEvents;
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    final data = await _metadataStore.record(pubKey).get(_database);
    if (data == null) return null;
    return MetadataExtension.fromJsonStorage(data);
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    final snapshots = await _metadataStore.records(pubKeys).get(_database);
    return snapshots.map((data) {
      if (data == null) return null;
      return MetadataExtension.fromJsonStorage(data);
    }).toList();
  }

  @override
  Future<Nip05?> loadNip05({String? pubKey, String? identifier}) async {
    if (pubKey != null) {
      final data = await _nip05Store.record(pubKey).get(_database);
      if (data == null) return null;
      return Nip05Extension.fromJsonStorage(data);
    }
    if (identifier != null) {
      final finder = sembast.Finder(
        filter: sembast.Filter.equals('nip05', identifier),
      );
      final record = await _nip05Store.findFirst(_database, finder: finder);
      if (record == null) return null;
      return Nip05Extension.fromJsonStorage(record.value);
    }
    return null;
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    final snapshots = await _nip05Store.records(pubKeys).get(_database);
    return snapshots.map((data) {
      if (data == null) return null;
      return Nip05Extension.fromJsonStorage(data);
    }).toList();
  }

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    final key = '${pubKey}_$name';
    final data = await _relaySetStore.record(key).get(_database);
    if (data == null) return null;
    return RelaySetExtension.fromJsonStorage(data);
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    final data = await _relayListStore.record(pubKey).get(_database);
    if (data == null) return null;
    return UserRelayListExtension.fromJsonStorage(data);
  }

  @override
  Future<void> removeAllContactLists() async {
    await _contactListStore.delete(_database);
  }

  @override
  Future<void> removeAllEvents() async {
    await _eventsStore.delete(_database);
    await _eventSourceStore.delete(_database);
    await _eventDeliveryStore.delete(_database);
    await _relayDeliveryTargetStore.delete(_database);
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    final events = await _eventsStore.find(
      _database,
      finder: sembast.Finder(
        filter: sembast.Filter.equals('pubkey', pubKey),
      ),
    );

    final finder = sembast.Finder(
      filter: sembast.Filter.equals('pubkey', pubKey),
    );
    await _eventsStore.delete(_database, finder: finder);
    for (final record in events) {
      final eventId = record.key;
      await removeEventSources(eventId);
      await removeEventDeliveryRecord(eventId);
      await removeRelayDeliveryTargets(eventId);
    }
  }

  @override
  Future<void> removeAllMetadatas() async {
    await _metadataStore.delete(_database);
  }

  @override
  Future<void> removeAllNip05s() async {
    await _nip05Store.delete(_database);
  }

  @override
  Future<void> removeAllRelaySets() async {
    await _relaySetStore.delete(_database);
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    await _relayListStore.delete(_database);
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    await _contactListStore.record(pubKey).delete(_database);
  }

  @override
  Future<void> removeEvent(String id) async {
    await _eventsStore.record(id).delete(_database);
    await removeEventSources(id);
    await removeEventDeliveryRecord(id);
    await removeRelayDeliveryTargets(id);
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

    // Build filter conditions
    final filters = <sembast.Filter>[];

    if (ids != null && ids.isNotEmpty) {
      filters.add(sembast.Filter.inList('id', ids));
    }
    if (pubKeys != null && pubKeys.isNotEmpty) {
      filters.add(sembast.Filter.inList('pubkey', pubKeys));
    }
    if (kinds != null && kinds.isNotEmpty) {
      filters.add(sembast.Filter.inList('kind', kinds));
    }
    if (since != null) {
      filters.add(sembast.Filter.greaterThanOrEquals('created_at', since));
    }
    if (until != null) {
      filters.add(sembast.Filter.lessThanOrEquals('created_at', until));
    }

    // If tags are specified, we need to load events first and filter in memory
    if (tags != null && tags.isNotEmpty) {
      final events = await _loadEventsInternal(
        ids: ids,
        pubKeys: pubKeys,
        kinds: kinds,
        tags: null,
        since: since,
        until: until,
        applyVisibilityRules: false,
      );

      // Filter by tags in memory
      final matchingEvents = events.where((event) {
        return tags.entries.every((tagEntry) {
          var tagName = tagEntry.key;
          final tagValues = tagEntry.value;

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

      // Delete matching events by ID
      await _eventsStore
          .records(matchingEvents.map((e) => e.id).toList())
          .delete(_database);
      for (final event in matchingEvents) {
        await removeEventSources(event.id);
        await removeEventDeliveryRecord(event.id);
        await removeRelayDeliveryTargets(event.id);
      }
    } else {
      // No tags filter, delete directly with finder
      final matchingEvents = await _loadEventsInternal(
        ids: ids,
        pubKeys: pubKeys,
        kinds: kinds,
        tags: tags,
        since: since,
        until: until,
        applyVisibilityRules: false,
      );
      final finder = sembast.Finder(
        filter: filters.isNotEmpty ? sembast.Filter.and(filters) : null,
      );
      await _eventsStore.delete(_database, finder: finder);
      for (final event in matchingEvents) {
        await removeEventSources(event.id);
        await removeEventDeliveryRecord(event.id);
        await removeRelayDeliveryTargets(event.id);
      }
    }
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    await _metadataStore.record(pubKey).delete(_database);
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    await _nip05Store.record(pubKey).delete(_database);
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    final key = '${pubKey}_$name';
    await _relaySetStore.record(key).delete(_database);
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    await _relayListStore.record(pubKey).delete(_database);
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await _contactListStore
        .record(contactList.pubKey)
        .put(_database, contactList.toJsonForStorage());
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    final keys = contactLists.map((c) => c.pubKey).toList();
    final values = contactLists.map((c) => c.toJsonForStorage()).toList();
    await _contactListStore.records(keys).put(_database, values);
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    await _eventsStore
        .record(event.id)
        .put(_database, event.toJsonForStorage());
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    final keys = events.map((e) => e.id).toList();
    final values = events.map((e) => e.toJsonForStorage()).toList();
    await _eventsStore.records(keys).put(_database, values);
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await _metadataStore
        .record(metadata.pubKey)
        .put(_database, metadata.toJsonForStorage());
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    final keys = metadatas.map((m) => m.pubKey).toList();
    final values = metadatas.map((m) => m.toJsonForStorage()).toList();
    await _metadataStore.records(keys).put(_database, values);
  }

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    await _nip05Store
        .record(nip05.pubKey)
        .put(_database, nip05.toJsonForStorage());
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    final keys = nip05s.map((n) => n.pubKey).toList();
    final values = nip05s.map((n) => n.toJsonForStorage()).toList();
    await _nip05Store.records(keys).put(_database, values);
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    final key = '${relaySet.pubKey}_${relaySet.name}';
    await _relaySetStore
        .record(key)
        .put(_database, relaySet.toJsonForStorage());
  }

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    await _relayListStore
        .record(userRelayList.pubKey)
        .put(_database, userRelayList.toJsonForStorage());
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    final keys = userRelayLists.map((u) => u.pubKey).toList();
    final values = userRelayLists.map((u) => u.toJsonForStorage()).toList();
    await _relayListStore.records(keys).put(_database, values);
  }

  Future<List<Nip01Event>> _applyEventVisibilityRules(
      List<Nip01Event> events) async {
    final visible = <Nip01Event>[];
    final replaceableWinners = <String, Nip01Event>{};
    final now = Nip01Event.secondsSinceEpoch();
    final deletionEvents = await _loadDeletionEvents();

    for (final event in events) {
      if (_isExpired(event, now)) continue;
      if (_isDeletedByAuthor(event, deletionEvents)) continue;

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

  bool _isDeletedByAuthor(Nip01Event target, List<Nip01Event> deletionEvents) {
    if (target.kind == 5) return false;

    for (final event in deletionEvents) {
      if (event.kind != 5) continue;
      if (event.pubKey != target.pubKey) continue;
      if (event.getTags('e').contains(target.id.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  Future<List<Nip01Event>> _loadDeletionEvents() async {
    final records = await _eventsStore.find(
      _database,
      finder: sembast.Finder(
        filter: sembast.Filter.equals('kind', 5),
      ),
    );

    return records
        .map((record) => Nip01EventExtension.fromJsonStorage(record.value))
        .toList();
  }

  bool _isExpired(Nip01Event event, int now) {
    final expirationValue = event.getFirstTag('expiration');
    if (expirationValue == null) return false;
    final expiration = int.tryParse(expirationValue);
    if (expiration == null) return false;
    return expiration <= now;
  }

  String? _coordinateKey(Nip01Event event) {
    if (!_isReplaceableKind(event.kind)) return null;
    final dTag = event.getDtag() ?? '';
    return '${event.kind}:${event.pubKey}:$dTag';
  }

  bool _isReplaceableKind(int kind) {
    return EventKindClassification.isReplaceableKind(kind);
  }

  bool _isMoreRecentReplaceable(Nip01Event candidate, Nip01Event current) {
    if (candidate.createdAt != current.createdAt) {
      return candidate.createdAt > current.createdAt;
    }

    return candidate.id.compareTo(current.id) < 0;
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
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    sembast.Filter? filter;
    if (search.isNotEmpty) {
      final pattern = RegExp.escape(search);
      filter = sembast.Filter.or([
        sembast.Filter.matchesRegExp(
            'name', RegExp(pattern, caseSensitive: false)),
        sembast.Filter.matchesRegExp(
            'displayName', RegExp(pattern, caseSensitive: false)),
        sembast.Filter.matchesRegExp(
            'about', RegExp(pattern, caseSensitive: false)),
        sembast.Filter.matchesRegExp(
            'nip05', RegExp(pattern, caseSensitive: false)),
      ]);
    }

    final finder = sembast.Finder(
      filter: filter,
      limit: limit,
      sortOrders: [sembast.SortOrder('updatedAt', false)],
    );

    final records = await _metadataStore.find(_database, finder: finder);
    return records
        .map((record) => MetadataExtension.fromJsonStorage(record.value))
        .toList();
  }

  // =====================
  // Filter Fetched Ranges
  // =====================

  @override
  Future<void> saveFilterFetchedRangeRecord(
      FilterFetchedRangeRecord record) async {
    await _filterFetchedRangeStore
        .record(record.key)
        .put(_database, record.toJson());
  }

  @override
  Future<void> saveFilterFetchedRangeRecords(
      List<FilterFetchedRangeRecord> records) async {
    final keys = records.map((r) => r.key).toList();
    final values = records.map((r) => r.toJson()).toList();
    await _filterFetchedRangeStore.records(keys).put(_database, values);
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
      String filterHash) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('filterHash', filterHash),
    );
    final records =
        await _filterFetchedRangeStore.find(_database, finder: finder);
    return records
        .map((r) => FilterFetchedRangeRecord.fromJson(r.value))
        .toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
      String filterHash, String relayUrl) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.and([
        sembast.Filter.equals('filterHash', filterHash),
        sembast.Filter.equals('relayUrl', relayUrl),
      ]),
    );
    final records =
        await _filterFetchedRangeStore.find(_database, finder: finder);
    return records
        .map((r) => FilterFetchedRangeRecord.fromJson(r.value))
        .toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>>
      loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('relayUrl', relayUrl),
    );
    final records =
        await _filterFetchedRangeStore.find(_database, finder: finder);
    return records
        .map((r) => FilterFetchedRangeRecord.fromJson(r.value))
        .toList();
  }

  @override
  Future<void> removeFilterFetchedRangeRecords(String filterHash) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('filterHash', filterHash),
    );
    await _filterFetchedRangeStore.delete(_database, finder: finder);
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
      String filterHash, String relayUrl) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.and([
        sembast.Filter.equals('filterHash', filterHash),
        sembast.Filter.equals('relayUrl', relayUrl),
      ]),
    );
    await _filterFetchedRangeStore.delete(_database, finder: finder);
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('relayUrl', relayUrl),
    );
    await _filterFetchedRangeStore.delete(_database, finder: finder);
  }

  @override
  Future<void> removeAllFilterFetchedRangeRecords() async {
    await _filterFetchedRangeStore.delete(_database);
  }

  // =====================
  // cashu / wallets
  // =====================

  @override
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl}) async {
    if (mintUrl == null || mintUrl.isEmpty) {
      // Return all keysets if no mintUrl
      final records = await _keysetStore.find(_database);
      return records
          .map((record) => CahsuKeysetExtension.fromJsonStorage(record.value))
          .toList();
    }

    final finder = sembast.Finder(
      filter: sembast.Filter.equals('mintUrl', mintUrl),
    );

    final records = await _keysetStore.find(_database, finder: finder);
    return records
        .map((record) => CahsuKeysetExtension.fromJsonStorage(record.value))
        .toList();
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  }) async {
    final filters = <sembast.Filter>[];

    // Filter by state
    filters.add(sembast.Filter.equals('state', state.toString()));

    // Filter by keysetId if provided
    if (keysetId != null && keysetId.isNotEmpty) {
      filters.add(sembast.Filter.equals('keysetId', keysetId));
    }

    // Filter by mintUrl if provided
    if (mintUrl != null && mintUrl.isNotEmpty) {
      // Get all keysets for the mintUrl
      final keysets = await getKeysets(mintUrl: mintUrl);
      if (keysets.isNotEmpty) {
        // Only filter if keysets exist
        final keysetIds = keysets.map((k) => k.id).toList();
        filters.add(sembast.Filter.inList('keysetId', keysetIds));
      }
      // If no keysets found, continue without this filter
      // This allows getting proofs even if keyset isn't stored yet
    }

    final finder = sembast.Finder(
      filter: sembast.Filter.and(filters),
      sortOrders: [sembast.SortOrder('amount')],
    );

    final records = await _proofStore.find(_database, finder: finder);
    return records
        .map((record) => CashuProofExtension.fromJsonStorage(record.value))
        .toList();
  }

  @override
  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    final proofSecrets = proofs.map((p) => p.secret).toList();
    final finder = sembast.Finder(
      filter: sembast.Filter.inList('secret', proofSecrets),
    );

    await _proofStore.delete(_database, finder: finder);
  }

  @override
  Future<void> saveKeyset(CahsuKeyset keyset) async {
    await _keysetStore
        .record(keyset.id)
        .put(_database, keyset.toJsonForStorage());
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    await _database.transaction((txn) async {
      // Remove existing proofs by secret (upsert logic)
      final secretsToCheck = proofs.map((p) => p.secret).toList();
      final finder = sembast.Finder(
        filter: sembast.Filter.inList('secret', secretsToCheck),
      );
      await _proofStore.delete(txn, finder: finder);

      // Insert new proofs
      for (final proof in proofs) {
        await _proofStore
            .record(proof.secret)
            .put(txn, proof.toJsonForStorage());
      }
    });
  }

  @override
  Future<List<CashuMintInfo>?> getMintInfos({List<String>? mintUrls}) async {
    if (mintUrls == null || mintUrls.isEmpty) {
      // Return all mint infos
      final records = await _mintInfoStore.find(_database);
      return records
          .map((record) => CashuMintInfoExtension.fromJsonStorage(record.value))
          .toList();
    }

    // For Sembast, we need to filter in memory since we can't do complex array operations
    final allRecords = await _mintInfoStore.find(_database);
    final allMintInfos = allRecords
        .map((record) => CashuMintInfoExtension.fromJsonStorage(record.value))
        .toList();

    // Filter by URLs
    return allMintInfos.where((mintInfo) {
      return mintUrls.any((url) => mintInfo.urls.contains(url));
    }).toList();
  }

  @override
  Future<void> saveMintInfo({required CashuMintInfo mintInfo}) async {
    // Use the first URL as the key for upsert logic
    final key = mintInfo.urls.first;

    // Remove existing mint info with the same URL
    final allRecords = await _mintInfoStore.find(_database);
    for (final record in allRecords) {
      final existingMintInfo =
          CashuMintInfoExtension.fromJsonStorage(record.value);
      if (existingMintInfo.urls.contains(mintInfo.urls.first)) {
        await _mintInfoStore.record(record.key).delete(_database);
      }
    }

    // Insert new mint info
    await _mintInfoStore
        .record(key)
        .put(_database, mintInfo.toJsonForStorage());
  }

  @override
  Future<void> removeMintInfo({
    required String mintUrl,
  }) async {
    // Find and delete all records that contain this mintUrl
    final allRecords = await _mintInfoStore.find(_database);
    for (final record in allRecords) {
      final existingMintInfo =
          CashuMintInfoExtension.fromJsonStorage(record.value);
      if (existingMintInfo.urls
          .any((url) => existingMintInfo.isMintUrl(mintUrl))) {
        await _mintInfoStore.record(record.key).delete(_database);
      }
    }
  }

  @override
  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  }) async {
    final key = '${mintUrl}_$keysetId';
    final data = await _secretCounterStore.record(key).get(_database);
    if (data == null) return 0;
    return data['counter'] as int? ?? 0;
  }

  @override
  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  }) async {
    final key = '${mintUrl}_$keysetId';
    await _secretCounterStore.record(key).put(_database, {
      'mintUrl': mintUrl,
      'keysetId': keysetId,
      'counter': counter,
    });
  }

  @override
  Future<void> clearAll() async {
    await Future.wait([
      _eventsStore.delete(_database),
      _eventSourceStore.delete(_database),
      _eventDeliveryStore.delete(_database),
      _relayDeliveryTargetStore.delete(_database),
      _metadataStore.delete(_database),
      _contactListStore.delete(_database),
      _relayListStore.delete(_database),
      _nip05Store.delete(_database),
      _relaySetStore.delete(_database),
      _filterFetchedRangeStore.delete(_database),
      _keysetStore.delete(_database),
      _proofStore.delete(_database),
      _mintInfoStore.delete(_database),
      _secretCounterStore.delete(_database),
    ]);
  }

  String _eventSourceKey(String eventId, String relayUrl) {
    return '$eventId|$relayUrl';
  }
}
