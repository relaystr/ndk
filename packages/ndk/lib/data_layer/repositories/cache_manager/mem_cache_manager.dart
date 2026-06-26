import 'dart:core';

import '../../../domain_layer/entities/cashu/cashu_keyset.dart';
import '../../../domain_layer/entities/cashu/cashu_mint_info.dart';
import '../../../domain_layer/entities/cashu/cashu_proof.dart';
import '../../../domain_layer/entities/cache_eviction.dart';
import '../../../domain_layer/entities/contact_list.dart';
import '../../../domain_layer/entities/event_cache_records.dart';
import '../../../domain_layer/entities/filter_fetched_ranges.dart';
import '../../../domain_layer/entities/metadata.dart';
import '../../../domain_layer/entities/nip_65.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/nip_05.dart';
import '../../../domain_layer/entities/relay_set.dart';
import '../../../domain_layer/entities/user_relay_list.dart';
import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/repositories/cache_manager.dart';
import '../../../shared/nips/nip01/event_kind_classification.dart';
import '../../../shared/nips/nip01/event_eviction_planner.dart';

/// In memory database implementation
/// benefits: very fast
/// drawbacks: does not persist
class MemCacheManager implements CacheManager {
  /// In memory storage
  Map<String, UserRelayList> userRelayLists = {};

  /// In memory storage
  Map<String, RelaySet> relaySets = {};

  /// In memory storage indexed by pubKey
  Map<String, Nip05> nip05s = {};

  /// In memory storage indexed by nip05 identifier
  Map<String, Nip05> nip05sByIdentifier = {};

  /// In memory storage
  Map<String, Nip01Event> events = {};

  /// In memory provenance storage keyed by "$eventId|$relayUrl"
  Map<String, String> eventSources = {};

  /// In memory event delivery storage keyed by eventId
  Map<String, EventDeliveryRecord> eventDeliveryRecords = {};

  /// In memory relay delivery target storage keyed by "$eventId|$relayUrl"
  Map<String, RelayDeliveryTarget> relayDeliveryTargets = {};

  /// In memory decrypted payload sidecar storage keyed by "$eventId|$viewerPubKey"
  Map<String, DecryptedEventPayloadRecord> decryptedEventPayloadRecords = {};

  /// String for mint Url
  Map<String, Set<CahsuKeyset>> cashuKeysets = {};

  /// String for mint Url
  Map<String, Set<CashuProof>> cashuProofs = {};

  Set<Wallet> wallets = {};

  Set<CashuMintInfo> cashuMintInfos = {};

  /// In memory storage for cashu secret counters
  /// Key is a combination of mintUrl and keysetId
  /// value is the counter
  final Map<String, int> _cashuSecretCounters = {};

  /// In memory storage for filter fetched range records
  /// Key is filterHash:relayUrl:rangeStart
  Map<String, FilterFetchedRangeRecord> filterFetchedRangeRecords = {};

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    userRelayLists[userRelayList.pubKey] = userRelayList;
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    final existing = userRelayLists[pubKey];
    if (existing != null) {
      return existing;
    }
    await _refreshUserRelayListProjection(pubKey);
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
    final event = await _loadLatestVisibleEvent(
      pubKey: pubKey,
      kind: ContactList.kKind,
    );
    if (event != null) {
      return ContactList.fromEvent(event);
    }
    return null;
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await saveEvent(contactList.toEvent());
  }

  @override
  Future<void> saveContactLists(List<ContactList> list) async {
    for (var contactList in list) {
      await saveContactList(contactList);
    }
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    final event = await _loadLatestVisibleEvent(
      pubKey: pubKey,
      kind: Metadata.kKind,
    );
    if (event != null) {
      final metadata = Metadata.fromEvent(event);
      metadata.refreshedTimestamp = Nip01Event.secondsSinceEpoch();
      return metadata;
    }
    return null;
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await saveEvent(metadata.toEvent());
  }

  @override
  Future<void> saveMetadatas(List<Metadata> list) async {
    for (var metadata in list) {
      await saveMetadata(metadata);
    }
  }

  @override
  Future<void> removeAllRelaySets() async {
    relaySets.clear();
  }

  @override
  Future<void> removeAllContactLists() async {
    await removeEvents(kinds: [ContactList.kKind]);
  }

  @override
  Future<void> removeAllMetadatas() async {
    await removeEvents(kinds: [Metadata.kKind]);
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    relaySets.remove(RelaySet.buildId(name, pubKey));
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    await removeEvents(pubKeys: [pubKey], kinds: [ContactList.kKind]);
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    await removeEvents(pubKeys: [pubKey], kinds: [Metadata.kKind]);
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    List<Metadata?> result = [];
    for (String pubKey in pubKeys) {
      result.add(await loadMetadata(pubKey));
    }
    return result;
  }

  /// Search for metadata by name, nip05
  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
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

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    return events[id];
  }

  @override
  Future<void> addEventSource({
    required String eventId,
    required String relayUrl,
  }) async {
    eventSources[_eventSourceKey(eventId, relayUrl)] = relayUrl;
  }

  @override
  Future<void> addEventSources({
    required String eventId,
    required Iterable<String> relayUrls,
  }) async {
    for (final relayUrl in relayUrls) {
      eventSources[_eventSourceKey(eventId, relayUrl)] = relayUrl;
    }
  }

  @override
  Future<List<String>> loadEventSources(String eventId) async {
    final prefix = '$eventId|';
    final result = eventSources.entries
        .where((entry) => entry.key.startsWith(prefix))
        .map((entry) => entry.value)
        .toList()
      ..sort();
    return result;
  }

  @override
  Future<void> removeEventSources(String eventId) async {
    final prefix = '$eventId|';
    eventSources.removeWhere((key, value) => key.startsWith(prefix));
  }

  @override
  Future<void> saveEventDeliveryRecord(EventDeliveryRecord record) async {
    eventDeliveryRecords[record.eventId] = record;
  }

  @override
  Future<void> saveEventDeliveryRecords(
      List<EventDeliveryRecord> records) async {
    for (final record in records) {
      eventDeliveryRecords[record.eventId] = record;
    }
  }

  @override
  Future<EventDeliveryRecord?> loadEventDeliveryRecord(String eventId) async {
    return eventDeliveryRecords[eventId];
  }

  @override
  Future<List<EventDeliveryRecord>> loadEventDeliveryRecords({
    EventDeliveryStatus? status,
    int? limit,
  }) async {
    var records = eventDeliveryRecords.values.where((record) {
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
    eventDeliveryRecords.remove(eventId);
  }

  @override
  Future<void> removeAllEventDeliveryRecords() async {
    eventDeliveryRecords.clear();
  }

  @override
  Future<void> saveRelayDeliveryTarget(RelayDeliveryTarget target) async {
    relayDeliveryTargets[target.key] = target;
  }

  @override
  Future<void> saveRelayDeliveryTargets(
      List<RelayDeliveryTarget> targets) async {
    for (final target in targets) {
      relayDeliveryTargets[target.key] = target;
    }
  }

  @override
  Future<RelayDeliveryTarget?> loadRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    return relayDeliveryTargets[_eventSourceKey(eventId, relayUrl)];
  }

  @override
  Future<List<RelayDeliveryTarget>> loadRelayDeliveryTargets({
    String? eventId,
    String? relayUrl,
    RelayDeliveryState? state,
    bool excludeAcked = false,
    int? limit,
  }) async {
    var records = relayDeliveryTargets.values.where((target) {
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

    if (limit != null && limit < records.length) {
      records = records.take(limit).toList();
    }

    return records;
  }

  @override
  Future<void> removeRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  }) async {
    relayDeliveryTargets.remove(_eventSourceKey(eventId, relayUrl));
  }

  @override
  Future<void> removeRelayDeliveryTargets(String eventId) async {
    final prefix = '$eventId|';
    relayDeliveryTargets.removeWhere((key, value) => key.startsWith(prefix));
  }

  @override
  Future<void> removeAllRelayDeliveryTargets() async {
    relayDeliveryTargets.clear();
  }

  @override
  Future<void> saveDecryptedEventPayloadRecord(
      DecryptedEventPayloadRecord record) async {
    decryptedEventPayloadRecords[record.key] = record;
  }

  @override
  Future<void> saveDecryptedEventPayloadRecords(
      List<DecryptedEventPayloadRecord> records) async {
    for (final record in records) {
      decryptedEventPayloadRecords[record.key] = record;
    }
  }

  @override
  Future<DecryptedEventPayloadRecord?> loadDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  }) async {
    return decryptedEventPayloadRecords[_eventSourceKey(eventId, viewerPubKey)];
  }

  @override
  Future<List<DecryptedEventPayloadRecord>> loadDecryptedEventPayloadRecords({
    String? eventId,
    String? viewerPubKey,
    DecryptedPayloadStatus? status,
    int? limit,
  }) async {
    var records = decryptedEventPayloadRecords.values.where((record) {
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
    decryptedEventPayloadRecords.remove(_eventSourceKey(eventId, viewerPubKey));
  }

  @override
  Future<void> removeDecryptedEventPayloadRecords(String eventId) async {
    final prefix = '$eventId|';
    decryptedEventPayloadRecords
        .removeWhere((key, value) => key.startsWith(prefix));
  }

  @override
  Future<void> removeAllDecryptedEventPayloadRecords() async {
    decryptedEventPayloadRecords.clear();
  }

  @override
  Future<EvictionResult> evict(EvictionPolicy policy) async {
    final lockedEventIds = <String>{
      ...eventDeliveryRecords.keys,
      ...relayDeliveryTargets.values.map((target) => target.eventId),
    };
    final plan = EventEvictionPlanner.plan(
      rawEvents: events.values.toList(),
      lockedEventIds: lockedEventIds,
      policy: policy,
    );

    if (plan.eventIdsToRemove.isEmpty) {
      return plan.toResult();
    }

    final removedEvents = events.values
        .where((event) => plan.eventIdsToRemove.contains(event.id))
        .toList();
    events.removeWhere((key, value) => plan.eventIdsToRemove.contains(key));
    _removeEventSidecarsByIds(plan.eventIdsToRemove);
    await _refreshDerivedStateForPubKeys(
      removedEvents.map((event) => event.pubKey).toSet(),
    );

    return plan.toResult();
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

    if (applyVisibilityRules) {
      result = _applyEventVisibilityRules(result);
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && limit > 0 && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    final eventIds = events.values
        .where((event) => event.pubKey == pubKey)
        .map((event) => event.id)
        .toList();
    events.removeWhere((key, value) => value.pubKey == pubKey);
    _removeEventSidecarsByIds(eventIds);
    await _refreshUserRelayListProjection(pubKey);
  }

  @override
  Future<void> removeAllEvents() async {
    events.clear();
    eventSources.clear();
    eventDeliveryRecords.clear();
    relayDeliveryTargets.clear();
    decryptedEventPayloadRecords.clear();
    userRelayLists.clear();
  }

  @override
  Future<void> removeEvent(String id) async {
    final removed = events.remove(id);
    _removeEventSidecarsByIds([id]);
    if (removed != null) {
      await _refreshDerivedStateForEvent(removed);
    }
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

    final rawEventsToRemove = await _loadEventsInternal(
      ids: ids,
      pubKeys: pubKeys,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      applyVisibilityRules: false,
    );
    final eventIdsToRemove =
        rawEventsToRemove.map((event) => event.id).toList();
    final eventIdSet = eventIdsToRemove.toSet();
    events.removeWhere((key, value) => eventIdSet.contains(key));
    _removeEventSidecarsByIds(eventIdsToRemove);
    await _refreshDerivedStateForPubKeys(
      rawEventsToRemove.map((event) => event.pubKey).toSet(),
    );
  }

  void _removeEventSidecarsByIds(Iterable<String> eventIds) {
    final eventIdSet = eventIds.toSet();
    if (eventIdSet.isEmpty) return;

    eventSources.removeWhere((key, value) {
      final separator = key.indexOf('|');
      final eventId = separator == -1 ? key : key.substring(0, separator);
      return eventIdSet.contains(eventId);
    });
    eventDeliveryRecords.removeWhere(
      (eventId, value) => eventIdSet.contains(eventId),
    );
    relayDeliveryTargets.removeWhere(
      (key, target) => eventIdSet.contains(target.eventId),
    );
    decryptedEventPayloadRecords.removeWhere(
      (key, record) => eventIdSet.contains(record.eventId),
    );
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    events[event.id] = event;
    await _refreshDerivedStateForEvent(event);
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    for (var event in events) {
      this.events[event.id] = event;
    }
    await _refreshDerivedStateForPubKeys(
      events.map((event) => event.pubKey).toSet(),
    );
  }

  @override
  Future<void> close() async {
    return;
  }

  @override
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl}) {
    if (cashuKeysets.containsKey(mintUrl)) {
      return Future.value(cashuKeysets[mintUrl]?.toList() ?? []);
    } else {
      return Future.value(cashuKeysets.values.expand((e) => e).toList());
    }
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
  Future<void> saveKeyset(CahsuKeyset keyset) {
    if (cashuKeysets.containsKey(keyset.mintUrl)) {
      cashuKeysets[keyset.mintUrl]!.add(keyset);
    } else {
      cashuKeysets[keyset.mintUrl] = {keyset};
    }
    return Future.value();
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  }) async {
    if (cashuProofs.containsKey(mintUrl)) {
      return cashuProofs[mintUrl]!
          .where((proof) =>
              proof.state == state &&
              (keysetId == null || proof.keysetId == keysetId))
          .toList();
    } else {
      return cashuProofs.values
          .expand((proofs) => proofs)
          .where((proof) =>
              proof.state == state &&
              (keysetId == null || proof.keysetId == keysetId))
          .toList();
    }
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) {
    if (cashuProofs.containsKey(mintUrl)) {
      cashuProofs[mintUrl]!.addAll(proofs);
    } else {
      cashuProofs[mintUrl] = Set<CashuProof>.from(proofs);
    }
    return Future.value();
  }

  @override
  Future<void> removeProofs(
      {required List<CashuProof> proofs, required String mintUrl}) {
    if (cashuProofs.containsKey(mintUrl)) {
      final existingProofs = cashuProofs[mintUrl]!;
      for (final proof in proofs) {
        existingProofs.removeWhere((p) => p.secret == proof.secret);
      }
      if (existingProofs.isEmpty) {
        cashuProofs.remove(mintUrl);
      }

      return Future.value();
    } else {
      return Future.error('No proofs found for mint URL: $mintUrl');
    }
  }

  @override
  Future<List<CashuMintInfo>?> getMintInfos({
    List<String>? mintUrls,
  }) {
    if (mintUrls == null) {
      return Future.value(cashuMintInfos.toList());
    } else {
      final result = cashuMintInfos
          .where(
            (info) => mintUrls.any((url) => info.isMintUrl(url)),
          )
          .toList();
      return Future.value(result.isNotEmpty ? result : null);
    }
  }

  @override
  Future<void> saveMintInfo({
    required CashuMintInfo mintInfo,
  }) {
    cashuMintInfos
        .removeWhere((info) => info.urls.any((url) => mintInfo.isMintUrl(url)));
    cashuMintInfos.add(mintInfo);
    return Future.value();
  }

  @override
  Future<void> removeMintInfo({
    required String mintUrl,
  }) {
    cashuMintInfos.removeWhere(
      (info) => info.urls.any((url) => info.isMintUrl(mintUrl)),
    );
    return Future.value();
  }

  @override
  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  }) {
    final key = '$mintUrl|$keysetId';
    return Future.value(_cashuSecretCounters[key] ?? 0);
  }

  @override
  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  }) async {
    final key = '$mintUrl|$keysetId';
    _cashuSecretCounters[key] = counter;

    return;
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
    eventSources.clear();
    eventDeliveryRecords.clear();
    relayDeliveryTargets.clear();
    decryptedEventPayloadRecords.clear();
    userRelayLists.clear();
    relaySets.clear();
    nip05s.clear();
    cashuKeysets.clear();
    cashuProofs.clear();
    cashuMintInfos.clear();
    nip05sByIdentifier.clear();
    filterFetchedRangeRecords.clear();
  }

  String _eventSourceKey(String eventId, String relayUrl) {
    return '$eventId|$relayUrl';
  }

  List<Nip01Event> _applyEventVisibilityRules(List<Nip01Event> events) {
    final visible = <Nip01Event>[];
    final replaceableWinners = <String, Nip01Event>{};
    final now = Nip01Event.secondsSinceEpoch();

    for (final event in events) {
      if (_isExpired(event, now)) continue;
      if (_isDeletedByAuthor(event)) continue;

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

  bool _isDeletedByAuthor(Nip01Event target) {
    if (target.kind == 5) return false;

    for (final event in events.values) {
      if (event.kind != 5) continue;
      if (event.pubKey != target.pubKey) continue;
      if (event.getTags('e').contains(target.id.toLowerCase())) {
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

  Future<Nip01Event?> _loadLatestVisibleEvent({
    required String pubKey,
    required int kind,
  }) async {
    final events = await loadEvents(pubKeys: [pubKey], kinds: [kind], limit: 1);
    if (events.isEmpty) return null;
    return events.first;
  }

  Future<void> _refreshDerivedStateForEvent(Nip01Event event) async {
    if (_affectsUserRelayListProjection(event.kind)) {
      await _refreshUserRelayListProjection(event.pubKey);
    }
  }

  Future<void> _refreshDerivedStateForPubKeys(Set<String> pubKeys) async {
    for (final pubKey in pubKeys) {
      await _refreshUserRelayListProjection(pubKey);
    }
  }

  bool _affectsUserRelayListProjection(int kind) {
    return kind == ContactList.kKind || kind == Nip65.kKind;
  }

  Future<void> _refreshUserRelayListProjection(String pubKey) async {
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
      userRelayLists[pubKey] = UserRelayList.fromNip65(
        Nip65.fromEvent(latestNip65),
      );
      return;
    }

    if (latestContactListWithRelays != null) {
      userRelayLists[pubKey] =
          UserRelayList.fromNip02EventContent(latestContactListWithRelays);
      return;
    }

    userRelayLists.remove(pubKey);
  }
}
