import 'dart:async';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/shared/nips/nip01/event_kind_classification.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import 'package:ndk_objectbox/data_layer/db/object_box/schema/db_nip_05.dart';

import '../../../objectbox.g.dart';
import 'db_init_object_box.dart';
import 'schema/db_cashu_keyset.dart';
import 'schema/db_cashu_mint_info.dart';
import 'schema/db_cashu_proof.dart';
import 'schema/db_cashu_secret_counter.dart';
import 'schema/db_filter_fetched_range_record.dart';
import 'schema/db_key_value.dart';
import 'schema/db_nip_01_event.dart';
import 'schema/db_relay_set.dart';
import 'schema/db_user_relay_list.dart';
import 'schema/db_wallet.dart';
import 'schema/db_wallet_transaction.dart';

class DbObjectBox extends WalletsRepo implements CacheManager {
  static const String _defaultWalletForReceivingKey =
      'default_wallet_for_receiving';
  static const String _defaultWalletForSendingKey =
      'default_wallet_for_sending';

  final Completer _initCompleter = Completer();
  Future get dbRdy => _initCompleter.future;
  late ObjectBoxInit _objectBox;
  final Map<String, Set<String>> _eventSources = {};
  final Map<String, EventDeliveryRecord> _eventDeliveryRecords = {};
  final Map<String, RelayDeliveryTarget> _relayDeliveryTargets = {};
  final Map<String, DecryptedEventPayloadRecord> _decryptedEventPayloadRecords =
      {};

  /// crates objectbox db instace
  /// [attach] to attach to already open instance (e.g. for isolates)
  /// [directory] optional custom directory for the database (useful for testing)
  DbObjectBox({bool attach = false, String? directory}) {
    _init(attach, directory);
  }

  Future _init(bool attach, String? directory) async {
    final ObjectBoxInit objectbox;
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
    final event = await _loadLatestVisibleEvent(
      pubKey: pubKey,
      kind: ContactList.kKind,
    );
    if (event == null) return null;
    return ContactList.fromEvent(event);
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
    final sources = _eventSources.putIfAbsent(eventId, () => <String>{});
    sources.addAll(relayUrls);
  }

  @override
  Future<List<String>> loadEventSources(String eventId) async {
    final sources = (_eventSources[eventId] ?? <String>{}).toList()..sort();
    return sources;
  }

  @override
  Future<void> removeEventSources(String eventId) async {
    _eventSources.remove(eventId);
  }

  @override
  Future<void> saveEventDeliveryRecord(EventDeliveryRecord record) async {
    _eventDeliveryRecords[record.eventId] = record;
  }

  @override
  Future<void> saveEventDeliveryRecords(
      List<EventDeliveryRecord> records) async {
    for (final record in records) {
      _eventDeliveryRecords[record.eventId] = record;
    }
  }

  @override
  Future<EventDeliveryRecord?> loadEventDeliveryRecord(String eventId) async {
    return _eventDeliveryRecords[eventId];
  }

  @override
  Future<List<EventDeliveryRecord>> loadEventDeliveryRecords({
    EventDeliveryStatus? status,
    int? limit,
  }) async {
    var records = _eventDeliveryRecords.values.where((record) {
      return status == null || record.status == status;
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (limit != null && limit < records.length) {
      records = records.take(limit).toList();
    }

    return records;
  }

  @override
  Future<void> removeEventDeliveryRecord(String eventId) async {
    _eventDeliveryRecords.remove(eventId);
  }

  @override
  Future<void> removeAllEventDeliveryRecords() async {
    _eventDeliveryRecords.clear();
  }

  @override
  Future<void> saveRelayDeliveryTarget(RelayDeliveryTarget target) async {
    _relayDeliveryTargets[target.key] = target;
  }

  @override
  Future<void> saveRelayDeliveryTargets(
      List<RelayDeliveryTarget> targets) async {
    for (final target in targets) {
      _relayDeliveryTargets[target.key] = target;
    }
  }

  @override
  Future<RelayDeliveryTarget?> loadRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    return _relayDeliveryTargets['$eventId|$relayUrl'];
  }

  @override
  Future<List<RelayDeliveryTarget>> loadRelayDeliveryTargets({
    String? eventId,
    String? relayUrl,
    RelayDeliveryState? state,
    bool excludeAcked = false,
    int? limit,
  }) async {
    var targets = _relayDeliveryTargets.values.where((target) {
      if (eventId != null && target.eventId != eventId) {
        return false;
      }
      if (relayUrl != null && target.relayUrl != relayUrl) {
        return false;
      }
      if (state != null && target.state != state) {
        return false;
      }
      if (excludeAcked && target.state == RelayDeliveryState.acked) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final retryA = a.nextRetryAt ?? 0;
        final retryB = b.nextRetryAt ?? 0;
        if (retryA != retryB) {
          return retryA.compareTo(retryB);
        }
        return a.key.compareTo(b.key);
      });

    if (limit != null && limit < targets.length) {
      targets = targets.take(limit).toList();
    }

    return targets;
  }

  @override
  Future<void> removeRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    _relayDeliveryTargets.remove('$eventId|$relayUrl');
  }

  @override
  Future<void> removeRelayDeliveryTargets(String eventId) async {
    _relayDeliveryTargets.removeWhere((key, _) => key.startsWith('$eventId|'));
  }

  @override
  Future<void> removeAllRelayDeliveryTargets() async {
    _relayDeliveryTargets.clear();
  }

  @override
  Future<void> saveDecryptedEventPayloadRecord(
      DecryptedEventPayloadRecord record) async {
    _decryptedEventPayloadRecords[record.key] = record;
  }

  @override
  Future<void> saveDecryptedEventPayloadRecords(
      List<DecryptedEventPayloadRecord> records) async {
    for (final record in records) {
      _decryptedEventPayloadRecords[record.key] = record;
    }
  }

  @override
  Future<DecryptedEventPayloadRecord?> loadDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  }) async {
    return _decryptedEventPayloadRecords['$eventId|$viewerPubKey'];
  }

  @override
  Future<List<DecryptedEventPayloadRecord>> loadDecryptedEventPayloadRecords({
    String? eventId,
    String? viewerPubKey,
    DecryptedPayloadStatus? status,
    int? limit,
  }) async {
    var records = _decryptedEventPayloadRecords.values.where((record) {
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
    }).toList();

    records.sort((a, b) => a.createdAt.compareTo(b.createdAt));

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
    _decryptedEventPayloadRecords.remove('$eventId|$viewerPubKey');
  }

  @override
  Future<void> removeDecryptedEventPayloadRecords(String eventId) async {
    final prefix = '$eventId|';
    _decryptedEventPayloadRecords.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> removeAllDecryptedEventPayloadRecords() async {
    _decryptedEventPayloadRecords.clear();
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

    // Add pubKeys filter
    if (pubKeys != null && pubKeys.isNotEmpty) {
      Condition<DbNip01Event> pubKeysCondition =
          DbNip01Event_.pubKey.oneOf(pubKeys);
      condition = (condition == null)
          ? pubKeysCondition
          : condition.and(pubKeysCondition);
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

    if (tags != null && tags.isNotEmpty) {
      final matchingEventIds = _findEventIdsByTags(eventBox, tags);
      if (matchingEventIds.isEmpty) {
        return [];
      }

      final tagCondition = DbNip01Event_.dbId.oneOf(matchingEventIds.toList());
      condition =
          (condition == null) ? tagCondition : condition.and(tagCondition);
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
    final results = query.find();

    final deletions = eventBox
        .query(DbNip01Event_.kind.equals(5))
        .build()
        .find()
        .map((dbEvent) => dbEvent.toNdk())
        .toList();

    var events = _applyEventVisibilityRules(
        results.map((dbEvent) => dbEvent.toNdk()).toList(), deletions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && limit > 0 && events.length > limit) {
      events = events.take(limit).toList();
    }

    return events;
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    await dbRdy;
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
    await dbRdy;
    return Future.wait(pubKeys.map(loadMetadata));
  }

  @override
  Future<void> removeAllContactLists() async {
    await dbRdy;
    await removeEvents(kinds: [ContactList.kKind]);
  }

  @override
  Future<void> removeAllEvents() async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.removeAll();
    _eventSources.clear();
    _eventDeliveryRecords.clear();
    _relayDeliveryTargets.clear();
    _decryptedEventPayloadRecords.clear();
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final events =
        eventBox.query(DbNip01Event_.pubKey.equals(pubKey)).build().find();
    final eventIds = events.map((e) => e.nostrId).toList();
    eventBox.removeMany(events.map((e) => e.dbId).toList());
    for (final eventId in eventIds) {
      _eventSources.remove(eventId);
      _eventDeliveryRecords.remove(eventId);
      _relayDeliveryTargets
          .removeWhere((key, _) => key.startsWith('$eventId|'));
      _decryptedEventPayloadRecords
          .removeWhere((key, _) => key.startsWith('$eventId|'));
    }
  }

  @override
  Future<void> removeAllMetadatas() async {
    await dbRdy;
    await removeEvents(kinds: [Metadata.kKind]);
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await dbRdy;
    await saveEvent(contactList.toEvent());
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    await dbRdy;
    await saveEvents(contactLists.map((cl) => cl.toEvent()).toList());
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
    await saveEvent(metadata.toEvent());
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await dbRdy;
    await saveEvents(metadatas.map((metadata) => metadata.toEvent()).toList());
  }

  @override
  Future<Nip05?> loadNip05({String? pubKey, String? identifier}) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();

    Condition<DbNip05>? condition;
    if (pubKey != null) {
      condition = DbNip05_.pubKey.equals(pubKey);
    } else if (identifier != null) {
      condition = DbNip05_.nip05.equals(identifier);
    } else {
      return null;
    }

    final existing = box
        .query(condition)
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
    final fromEvents = await _deriveUserRelayListFromEvents(pubKey);
    if (fromEvents != null) {
      return fromEvents;
    }

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
    await removeEvents(pubKeys: [pubKey], kinds: [ContactList.kKind]);
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
    _eventSources.remove(id);
    _eventDeliveryRecords.remove(id);
    _relayDeliveryTargets.removeWhere((key, _) => key.startsWith('$id|'));
    _decryptedEventPayloadRecords.removeWhere((key, _) => key.startsWith('$id|'));
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
    await dbRdy;

    // If all parameters are empty, return early (don't delete everything)
    if ((ids == null || ids.isEmpty) &&
        (pubKeys == null || pubKeys.isEmpty) &&
        (kinds == null || kinds.isEmpty) &&
        (tags == null || tags.isEmpty) &&
        since == null &&
        until == null) {
      return;
    }

    final eventBox = _objectBox.store.box<DbNip01Event>();

    // Build conditions list
    final conditions = <Condition<DbNip01Event>>[];

    if (ids != null && ids.isNotEmpty) {
      conditions.add(DbNip01Event_.nostrId.oneOf(ids));
    }
    if (pubKeys != null && pubKeys.isNotEmpty) {
      conditions.add(DbNip01Event_.pubKey.oneOf(pubKeys));
    }
    if (kinds != null && kinds.isNotEmpty) {
      conditions.add(DbNip01Event_.kind.oneOf(kinds));
    }
    if (since != null) {
      conditions.add(DbNip01Event_.createdAt.greaterOrEqual(since));
    }
    if (until != null) {
      conditions.add(DbNip01Event_.createdAt.lessOrEqual(until));
    }

    if (tags != null && tags.isNotEmpty) {
      final matchingEventIds = _findEventIdsByTags(eventBox, tags);
      if (matchingEventIds.isEmpty) {
        return;
      }
      conditions.add(DbNip01Event_.dbId.oneOf(matchingEventIds.toList()));
    }

    // Build and execute the query
    final query = conditions.isEmpty
        ? eventBox.query().build()
        : eventBox.query(conditions.reduce((a, b) => a.and(b))).build();
    final results = query.find();

    // Remove matching events
    final removedEventIds = results.map((e) => e.nostrId).toList();
    eventBox.removeMany(results.map((e) => e.dbId).toList());
    for (final eventId in removedEventIds) {
      _eventSources.remove(eventId);
      _eventDeliveryRecords.remove(eventId);
      _relayDeliveryTargets
          .removeWhere((key, _) => key.startsWith('$eventId|'));
      _decryptedEventPayloadRecords
          .removeWhere((key, _) => key.startsWith('$eventId|'));
    }
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

  /// Find event DB IDs matching all given tag filters.
  /// [tags] is a map of tag key -> list of acceptable values.
  /// Returns the intersection of matching event IDs across all tag keys.
  ///
  /// Usage (on the calling side):
  /// ```
  /// final eventBox = store.box<DbNip01Event>();
  /// final ids = DbNip01Event.findEventIdsByTags(eventBox, {"p": ["abc"], "t": ["nostr"]});
  /// ```
  static Set<int> _findEventIdsByTags(
    Box<DbNip01Event> eventBox,
    Map<String, List<String>> tags,
  ) {
    Set<int>? matchingEventIds;

    for (final entry in tags.entries) {
      final key = entry.key.trim().toLowerCase();
      final values = entry.value
          .map((v) => v.trim().toLowerCase())
          .where((v) => v.isNotEmpty)
          .toList();

      if (key.isEmpty || values.isEmpty) {
        return <int>{};
      }

      final indexValues = [for (final v in values) '$key:$v'];

      Condition<DbNip01Event>? condition;
      for (final v in indexValues) {
        final c = DbNip01Event_.tagsIndex.containsElement(v);
        condition = condition == null ? c : condition.or(c);
      }
      final query = eventBox.query(condition!).build();
      final eventIdsForTag = query.findIds().toSet();
      query.close();

      if (matchingEventIds == null) {
        matchingEventIds = eventIdsForTag;
      } else {
        matchingEventIds = matchingEventIds.intersection(eventIdsForTag);
      }

      if (matchingEventIds.isEmpty) {
        return <int>{};
      }
    }

    return matchingEventIds ?? <int>{};
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    await dbRdy;
    await removeEvents(pubKeys: [pubKey], kinds: [Metadata.kKind]);
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
    final events = await loadEvents(kinds: [Metadata.kKind]);
    final normalizedSearch = search.trim().toLowerCase();
    final matches =
        events.map((event) => Metadata.fromEvent(event)).where((metadata) {
      if (normalizedSearch.isEmpty) return true;
      return metadata.matchesSearch(normalizedSearch) ||
          (metadata.about?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (metadata.cleanNip05?.contains(normalizedSearch) ?? false);
    }).toList()
          ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    return matches.take(limit);
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

  // =====================
  // Filter Fetched Ranges
  // =====================

  @override
  Future<void> saveFilterFetchedRangeRecord(
      FilterFetchedRangeRecord record) async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    box.put(DbFilterFetchedRangeRecord.fromNdk(record));
  }

  @override
  Future<void> saveFilterFetchedRangeRecords(
      List<FilterFetchedRangeRecord> records) async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    box.putMany(
        records.map((r) => DbFilterFetchedRangeRecord.fromNdk(r)).toList());
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
      String filterHash) async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    final results = box
        .query(DbFilterFetchedRangeRecord_.filterHash.equals(filterHash))
        .build()
        .find();
    return results.map((r) => r.toNdk()).toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
      String filterHash, String relayUrl) async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    final results = box
        .query(DbFilterFetchedRangeRecord_.filterHash
            .equals(filterHash)
            .and(DbFilterFetchedRangeRecord_.relayUrl.equals(relayUrl)))
        .build()
        .find();
    return results.map((r) => r.toNdk()).toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>>
      loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl) async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    final results = box
        .query(DbFilterFetchedRangeRecord_.relayUrl.equals(relayUrl))
        .build()
        .find();
    return results.map((r) => r.toNdk()).toList();
  }

  @override
  Future<void> removeFilterFetchedRangeRecords(String filterHash) async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    final existing = box
        .query(DbFilterFetchedRangeRecord_.filterHash.equals(filterHash))
        .build()
        .find();
    if (existing.isNotEmpty) {
      box.removeMany(existing.map((e) => e.dbId).toList());
    }
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
      String filterHash, String relayUrl) async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    final existing = box
        .query(DbFilterFetchedRangeRecord_.filterHash
            .equals(filterHash)
            .and(DbFilterFetchedRangeRecord_.relayUrl.equals(relayUrl)))
        .build()
        .find();
    if (existing.isNotEmpty) {
      box.removeMany(existing.map((e) => e.dbId).toList());
    }
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl) async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    final existing = box
        .query(DbFilterFetchedRangeRecord_.relayUrl.equals(relayUrl))
        .build()
        .find();
    if (existing.isNotEmpty) {
      box.removeMany(existing.map((e) => e.dbId).toList());
    }
  }

  @override
  Future<void> removeAllFilterFetchedRangeRecords() async {
    await dbRdy;
    final box = _objectBox.store.box<DbFilterFetchedRangeRecord>();
    box.removeAll();
  }

  @override
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl}) async {
    await dbRdy;
    if (mintUrl == null || mintUrl.isEmpty) {
      // return all keysets if no mintUrl
      return _objectBox.store
          .box<DbWalletCahsuKeyset>()
          .getAll()
          .map((dbKeyset) => dbKeyset.toNdk())
          .toList();
    }

    return _objectBox.store
        .box<DbWalletCahsuKeyset>()
        .query(DbWalletCahsuKeyset_.mintUrl.equals(mintUrl))
        .build()
        .find()
        .map((dbKeyset) => dbKeyset.toNdk())
        .toList();
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  }) async {
    /// returns all proofs if no filters are applied
    await dbRdy;

    final proofBox = _objectBox.store.box<DbWalletCashuProof>();

    // Build conditions
    Condition<DbWalletCashuProof> condition;

    /// filter spend state

    condition = DbWalletCashuProof_.state.equals(state.toString());

    /// specify keysetId
    if (keysetId != null && keysetId.isNotEmpty) {
      final keysetCondition = DbWalletCashuProof_.keysetId.equals(keysetId);
      condition = condition.and(keysetCondition);
    }

    if (mintUrl != null && mintUrl.isNotEmpty) {
      /// get all keysets for the mintUrl
      /// and filter proofs by keysetId
      ///
      final keysets = await getKeysets(mintUrl: mintUrl);
      if (keysets.isNotEmpty) {
        final keysetIds = keysets.map((k) => k.id).toList();
        final mintUrlCondition = DbWalletCashuProof_.keysetId.oneOf(keysetIds);

        condition = condition.and(mintUrlCondition);
      } else {
        // If no keysets found for the mintUrl, return empty list
        return [];
      }
    }

    QueryBuilder<DbWalletCashuProof> queryBuilder;

    queryBuilder = proofBox.query(condition);

    // Apply sorting
    queryBuilder.order(DbWalletCashuProof_.amount);

    // Build and execute the query
    final query = queryBuilder.build();

    final results = query.find();
    return results.map((dbProof) => dbProof.toNdk()).toList();
  }

  @override
  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    await dbRdy;
    final proofBox = _objectBox.store.box<DbWalletCashuProof>();

    // find all proofs, ignoring mintUrl
    final proofSecrets = proofs.map((p) => p.secret).toList();
    final existingProofs = proofBox
        .query(DbWalletCashuProof_.secret.oneOf(proofSecrets))
        .build()
        .find();

    // remove them
    if (existingProofs.isNotEmpty) {
      proofBox.removeMany(existingProofs.map((p) => p.dbId).toList());
    }
  }

  @override
  Future<void> saveKeyset(CahsuKeyset keyset) async {
    _objectBox.store.box<DbWalletCahsuKeyset>().put(
          DbWalletCahsuKeyset.fromNdk(keyset),
        );
    return Future.value();
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    await dbRdy;

    /// upsert logic:

    final store = _objectBox.store;
    store.runInTransaction(TxMode.write, () {
      final box = store.box<DbWalletCashuProof>();

      final dbTokens =
          proofs.map((t) => DbWalletCashuProof.fromNdk(t)).toList();

      // find existing proofs by secret
      final secretsToCheck = dbTokens.map((t) => t.secret).toList();
      final query =
          box.query(DbWalletCashuProof_.secret.oneOf(secretsToCheck)).build();

      try {
        final existing = query.find();

        if (existing.isNotEmpty) {
          box.removeMany(existing.map((t) => t.dbId).toList());
        }

        // insert
        box.putMany(dbTokens);
      } finally {
        query.close();
      }
    });
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) async {
    await dbRdy;

    final transactionBox = _objectBox.store.box<DbWalletTransaction>();

    Condition<DbWalletTransaction>? condition;
    if (walletId != null && walletId.isNotEmpty) {
      condition = DbWalletTransaction_.walletId.equals(walletId);
    }
    if (unit != null && unit.isNotEmpty) {
      final unitCondition = DbWalletTransaction_.unit.equals(unit);
      condition =
          (condition == null) ? unitCondition : condition.and(unitCondition);
    }
    if (walletType != null) {
      final typeCondition =
          DbWalletTransaction_.walletType.equals(walletType.toString());
      condition =
          (condition == null) ? typeCondition : condition.and(typeCondition);
    }
    QueryBuilder<DbWalletTransaction> queryBuilder;
    if (condition != null) {
      queryBuilder = transactionBox.query(condition);
    } else {
      queryBuilder = transactionBox.query();
    }

    // sort
    queryBuilder.order(DbWalletTransaction_.transactionDate,
        flags: Order.descending);

    final query = queryBuilder.build();
    // limit
    if (limit != null) {
      query..limit = limit;
    }

    // offset
    if (offset != null) {
      query..offset = offset;
    }

    final results = query.find();
    return results.map((dbTransaction) => dbTransaction.toNdk()).toList();
  }

  Future<void> saveTransactions(List<WalletTransaction> transactions) async {
    await dbRdy;

    final store = _objectBox.store;

    store.runInTransaction(TxMode.write, () {
      final box = store.box<DbWalletTransaction>();
      final dbTransactions =
          transactions.map((t) => DbWalletTransaction.fromNdk(t)).toList();

      // find existing transactions by id
      final idsToCheck = dbTransactions.map((t) => t.id).toList();

      final query =
          box.query(DbWalletTransaction_.id.oneOf(idsToCheck)).build();

      try {
        final existing = query.find();

        if (existing.isNotEmpty) {
          box.removeMany(existing.map((t) => t.dbId).toList());
        }

        // insert
        box.putMany(dbTransactions);
      } finally {
        query.close();
      }
    });
  }

  @override
  Future<void> removeTransactions(List<String>? transactionIds) async {
    await dbRdy;
    final transactionBox = _objectBox.store.box<DbWalletTransaction>();

    if (transactionIds == null || transactionIds.isEmpty) {
      await transactionBox.removeAllAsync();
      return;
    }

    final query = transactionBox
        .query(DbWalletTransaction_.id.oneOf(transactionIds))
        .build();

    try {
      final transactionsToRemove = query.find();
      if (transactionsToRemove.isNotEmpty) {
        transactionBox
            .removeMany(transactionsToRemove.map((t) => t.dbId).toList());
      }
    } finally {
      query.close();
    }
  }

  @override
  Future<List<Wallet>> getWallets({List<String>? ids}) async {
    await dbRdy;

    return Future.value(
      _objectBox.store.box<DbWallet>().getAll().map((dbWallet) {
        return dbWallet.toNdk();
      }).where((wallet) {
        if (ids == null || ids.isEmpty) {
          return true; // return all wallets
        }
        return ids.contains(wallet.id);
      }).toList(),
    );
  }

  @override
  Future<void> removeWallet(String walletId) async {
    await dbRdy;
    // find wallet by id
    final walletBox = _objectBox.store.box<DbWallet>();
    final existingWallet = await walletBox
        .query(DbWallet_.id.equals(walletId))
        .build()
        .findFirst();
    if (existingWallet != null) {
      await walletBox.remove(existingWallet.dbId);
    }
    return Future.value();
  }

  @override
  Future<void> storeWallet(Wallet wallet) async {
    await dbRdy;
    await _objectBox.store.box<DbWallet>().put(DbWallet.fromNdk(wallet));
    return Future.value();
  }

  @override
  Future<List<CashuMintInfo>?> getMintInfos({List<String>? mintUrls}) async {
    await dbRdy;

    final box = _objectBox.store.box<DbCashuMintInfo>();

    // return all if no filters provided
    if (mintUrls == null || mintUrls.isEmpty) {
      return box.getAll().map((e) => e.toNdk()).toList();
    }

    // build OR condition
    Condition<DbCashuMintInfo>? cond;
    for (final url in mintUrls) {
      final c = DbCashuMintInfo_.urls.containsElement(url);
      cond = (cond == null) ? c : (cond | c);
    }

    final query = box.query(cond).build();
    try {
      return query.find().map((e) => e.toNdk()).toList();
    } finally {
      query.close();
    }
  }

  @override
  Future<void> saveMintInfo({required CashuMintInfo mintInfo}) async {
    await dbRdy;

    final box = _objectBox.store.box<DbCashuMintInfo>();

    /// upsert logic:
    final existingMintInfo = box
        .query(DbCashuMintInfo_.urls.containsElement(mintInfo.urls.first))
        .build()
        .findFirst();

    if (existingMintInfo != null) {
      box.remove(existingMintInfo.dbId);
    }

    box.put(DbCashuMintInfo.fromNdk(mintInfo));
  }

  @override
  Future<void> removeMintInfo({required String mintUrl}) async {
    await dbRdy;

    final box = _objectBox.store.box<DbCashuMintInfo>();

    // Find all mint infos that contain this URL
    final mintInfosToRemove = box
        .query(DbCashuMintInfo_.urls.containsElement(mintUrl))
        .build()
        .find();

    // Remove all matching entries
    for (final mintInfo in mintInfosToRemove) {
      box.remove(mintInfo.dbId);
    }
  }

  @override
  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  }) async {
    await dbRdy;
    final box = _objectBox.store.box<DbCashuSecretCounter>();
    final existing = box
        .query(DbCashuSecretCounter_.mintUrl
            .equals(mintUrl)
            .and(DbCashuSecretCounter_.keysetId.equals(keysetId)))
        .build()
        .findFirst();
    if (existing == null) {
      return 0;
    }
    return existing.counter;
  }

  @override
  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  }) async {
    await dbRdy;
    final box = _objectBox.store.box<DbCashuSecretCounter>();
    final existing = box
        .query(DbCashuSecretCounter_.mintUrl
            .equals(mintUrl)
            .and(DbCashuSecretCounter_.keysetId.equals(keysetId)))
        .build()
        .findFirst();
    if (existing != null) {
      box.remove(existing.dbId);
    }
    box.put(DbCashuSecretCounter(
      mintUrl: mintUrl,
      keysetId: keysetId,
      counter: counter,
    ));
    return Future.value();
  }

  Future<void> clearAll() async {
    await dbRdy;
    await _objectBox.store.runInTransactionAsync(
      TxMode.write,
      (Store store, _) {
        store.box<DbNip01Event>().removeAll();
        store.box<DbUserRelayList>().removeAll();
        store.box<DbRelaySet>().removeAll();
        store.box<DbNip05>().removeAll();
        store.box<DbFilterFetchedRangeRecord>().removeAll();
        store.box<DbKeyValue>().removeAll();
        store.box<DbCashuMintInfo>().removeAll();
        store.box<DbWalletCahsuKeyset>().removeAll();
        store.box<DbWalletCashuProof>().removeAll();
        store.box<DbWalletTransaction>().removeAll();
      },
      null,
    );
    _eventSources.clear();
    _eventDeliveryRecords.clear();
    _relayDeliveryTargets.clear();
    _decryptedEventPayloadRecords.clear();
  }

  @override
  String? getDefaultWalletIdForReceiving() {
    if (!_initCompleter.isCompleted) {
      return null;
    }
    final box = _objectBox.store.box<DbKeyValue>();
    final existing = _findKeyValue(box, _defaultWalletForReceivingKey);
    return existing?.value;
  }

  @override
  String? getDefaultWalletIdForSending() {
    if (!_initCompleter.isCompleted) {
      return null;
    }
    final box = _objectBox.store.box<DbKeyValue>();
    final existing = _findKeyValue(box, _defaultWalletForSendingKey);
    return existing?.value;
  }

  @override
  void setDefaultWalletForReceiving(String? walletId) {
    if (!_initCompleter.isCompleted) {
      return;
    }
    final box = _objectBox.store.box<DbKeyValue>();
    final existing = _findKeyValue(box, _defaultWalletForReceivingKey);
    if (existing != null) {
      box.remove(existing.dbId);
    }
    box.put(DbKeyValue(key: _defaultWalletForReceivingKey, value: walletId));
  }

  @override
  void setDefaultWalletForSending(String? walletId) {
    if (!_initCompleter.isCompleted) {
      return;
    }
    final box = _objectBox.store.box<DbKeyValue>();
    final existing = _findKeyValue(box, _defaultWalletForSendingKey);
    if (existing != null) {
      box.remove(existing.dbId);
    }
    box.put(DbKeyValue(key: _defaultWalletForSendingKey, value: walletId));
  }

  DbKeyValue? _findKeyValue(Box<DbKeyValue> box, String key) {
    for (final entry in box.getAll()) {
      if (entry.key == key) {
        return entry;
      }
    }
    return null;
  }
}
