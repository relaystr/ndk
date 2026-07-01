import '../entities/cashu/cashu_keyset.dart';
import '../entities/cashu/cashu_mint_info.dart';
import '../entities/cashu/cashu_proof.dart';
import '../entities/cache_eviction.dart';
import '../entities/contact_list.dart';
import '../entities/event_cache_records.dart';
import '../entities/filter_fetched_ranges.dart';
import '../entities/metadata.dart';
import '../entities/nip_01_event.dart';
import '../entities/nip_05.dart';
import '../entities/relay_set.dart';
import '../entities/user_relay_list.dart';

/// Storage contract used by NDK.
///
/// This is intentionally broader than a plain event store. Modern NDK cache
/// backends persist several related data domains:
/// - canonical Nostr events
/// - event provenance (`source relays`)
/// - delivery state (`EventDeliveryRecord` and `RelayDeliveryTarget`)
/// - decrypted plaintext sidecars for encrypted events
/// - convenience projections like metadata/contact list/user relay list
/// - optional fetched-ranges state
///
/// Backend authors should treat this class as a behavior contract, not just a
/// list of CRUD methods. The most important behavioral expectations are:
/// - [loadEvents] returns *visible* events only
/// - metadata/contact list loaders are convenience views over the generic event
///   store, not separate authoritative silos
/// - provenance and delivery targets are separate concerns
abstract class CacheManager {
  /// closes the cache manger \
  /// used to close the db
  Future<void> close();

  Future<void> saveEvent(Nip01Event event);
  Future<void> saveEvents(List<Nip01Event> events);

  /// Loads the raw stored event by id.
  ///
  /// Prefer [loadEvents] in app-facing read paths because `loadEvent` does not
  /// itself promise visibility filtering.
  Future<Nip01Event?> loadEvent(String id);

  /// Adds one provenance relay for a stored event.
  ///
  /// Provenance is intentionally stored separately from broadcast delivery
  /// targets. A relay can be a source of truth for where an event was observed
  /// without being a relay NDK should later broadcast back to.
  Future<void> addEventSource({
    required String eventId,
    required String relayUrl,
  });
  Future<void> addEventSources({
    required String eventId,
    required Iterable<String> relayUrls,
  });
  Future<List<String>> loadEventSources(String eventId);
  Future<void> removeEventSources(String eventId);

  /// Persist aggregate delivery state for one event.
  Future<void> saveEventDeliveryRecord(EventDeliveryRecord record);
  Future<void> saveEventDeliveryRecords(List<EventDeliveryRecord> records);
  Future<EventDeliveryRecord?> loadEventDeliveryRecord(String eventId);
  Future<List<EventDeliveryRecord>> loadEventDeliveryRecords({
    EventDeliveryStatus? status,
    int? limit,
  });
  Future<void> removeEventDeliveryRecord(String eventId);
  Future<void> removeAllEventDeliveryRecords();

  /// Persist one relay-specific delivery target.
  Future<void> saveRelayDeliveryTarget(RelayDeliveryTarget target);
  Future<void> saveRelayDeliveryTargets(List<RelayDeliveryTarget> targets);
  Future<RelayDeliveryTarget?> loadRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  });
  Future<List<RelayDeliveryTarget>> loadRelayDeliveryTargets({
    String? eventId,
    String? relayUrl,
    RelayDeliveryState? state,
    bool excludeAcked = false,
    int? limit,
  });
  Future<void> removeRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  });
  Future<void> removeRelayDeliveryTargets(String eventId);
  Future<void> removeAllRelayDeliveryTargets();

  /// Persist one plaintext sidecar for an encrypted event.
  Future<void> saveDecryptedEventPayloadRecord(
      DecryptedEventPayloadRecord record);
  Future<void> saveDecryptedEventPayloadRecords(
      List<DecryptedEventPayloadRecord> records);
  Future<DecryptedEventPayloadRecord?> loadDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  });
  Future<List<DecryptedEventPayloadRecord>> loadDecryptedEventPayloadRecords({
    String? eventId,
    String? viewerPubKey,
    DecryptedPayloadStatus? status,
    int? limit,
  });
  Future<void> removeDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  });
  Future<void> removeDecryptedEventPayloadRecords(String eventId);
  Future<void> removeAllDecryptedEventPayloadRecords();

  /// Run one eviction pass according to [policy].
  ///
  /// Backends should remove associated sidecars, provenance, and delivery state
  /// for any event they physically delete.
  Future<EvictionResult> evict(EvictionPolicy policy);

  /// Load visible events from cache with flexible filtering.
  ///
  /// Parameters:
  /// - [ids]: event ids
  /// - [pubKeys]: author pubkeys
  /// - [kinds]: event kinds
  /// - [tags]: tag filters, e.g. `{'p': ['pubkey1'], 'e': ['eventid1']}`
  /// - [since]/[until]: created_at bounds
  /// - [search]: content search string
  /// - [limit]: maximum number of returned events
  ///
  /// Visibility rules apply here:
  /// - only the latest visible replaceable/addressable winner is returned
  /// - expired events are filtered out
  /// - author-deleted events are filtered out
  Future<List<Nip01Event>> loadEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
  });
  Future<void> removeEvent(String id);

  /// Remove events from cache with flexible filtering.
  ///
  /// If all parameters are empty, implementations should return early instead
  /// of deleting everything by accident.
  Future<void> removeEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
  });
  Future<void> removeAllEventsByPubKey(String pubKey);
  Future<void> removeAllEvents();

  /// Store a precomputed user relay list projection.
  ///
  /// This remains a convenience projection. The authoritative data still comes
  /// from the generic event store (for example kind `3` and kind `10002`
  /// inputs).
  Future<void> saveUserRelayList(UserRelayList userRelayList);
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists);
  Future<UserRelayList?> loadUserRelayList(String pubKey);
  Future<void> removeUserRelayList(String pubKey);
  Future<void> removeAllUserRelayLists();

  Future<RelaySet?> loadRelaySet(String name, String pubKey);
  Future<void> saveRelaySet(RelaySet relaySet);
  Future<void> removeRelaySet(String name, String pubKey);
  Future<void> removeAllRelaySets();

  @Deprecated(
    'Use saveEvent()/saveEvents() with kind 3 events; ContactList is now a convenience view over the generic event cache.',
  )
  Future<void> saveContactList(ContactList contactList);
  @Deprecated(
    'Use saveEvent()/saveEvents() with kind 3 events; ContactList is now a convenience view over the generic event cache.',
  )
  Future<void> saveContactLists(List<ContactList> contactLists);
  Future<ContactList?> loadContactList(String pubKey);
  @Deprecated(
    'Use removeEvents(pubKeys: ..., kinds: [ContactList.kKind]); ContactList is now a convenience view over the generic event cache.',
  )
  Future<void> removeContactList(String pubKey);
  Future<void> removeAllContactLists();

  @Deprecated(
    'Use saveEvent()/saveEvents() with kind 0 events; Metadata is now a convenience view over the generic event cache.',
  )
  Future<void> saveMetadata(Metadata metadata);
  @Deprecated(
    'Use saveEvent()/saveEvents() with kind 0 events; Metadata is now a convenience view over the generic event cache.',
  )
  Future<void> saveMetadatas(List<Metadata> metadatas);
  Future<Metadata?> loadMetadata(String pubKey);
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys);
  @Deprecated(
    'Use removeEvents(pubKeys: ..., kinds: [Metadata.kKind]); Metadata is now a convenience view over the generic event cache.',
  )
  Future<void> removeMetadata(String pubKey);
  Future<void> removeAllMetadatas();

  /// Search by name, nip05
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit);

  /// search events \
  /// [ids] - list of event ids \
  /// [authors] - list of authors pubKeys \
  /// [kinds] - list of kinds \
  /// [tags] - map of tags \
  /// [since] - timestamp \
  /// [until] - timestamp \
  /// [search] - search string to match against content \
  /// [limit] - limit of results \
  /// returns list of events
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
  });

  Future<void> saveNip05(Nip05 nip05);
  Future<void> saveNip05s(List<Nip05> nip05s);
  Future<Nip05?> loadNip05({String? pubKey, String? identifier});
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys);
  Future<void> removeNip05(String pubKey);
  Future<void> removeAllNip05s();

  /// cashu methods

  Future<void> saveKeyset(CahsuKeyset keyset);

  /// get all keysets if no mintUrl is provided \
  Future<List<CahsuKeyset>> getKeysets({
    String? mintUrl,
  });

  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  });

  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  });

  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  });

  Future<void> saveMintInfo({
    required CashuMintInfo mintInfo,
  });

  Future<void> removeMintInfo({
    required String mintUrl,
  });

  /// return all if no mintUrls are provided
  Future<List<CashuMintInfo>?> getMintInfos({
    List<String>? mintUrls,
  });

  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  });

  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  });
  // =====================
  // Filter Fetched Ranges
  // =====================

  /// Save a filter fetched range record
  Future<void> saveFilterFetchedRangeRecord(FilterFetchedRangeRecord record);

  /// Save multiple filter fetched range records
  Future<void> saveFilterFetchedRangeRecords(
      List<FilterFetchedRangeRecord> records);

  /// Load all fetched range records for a filter hash
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
      String filterHash);

  /// Load all fetched range records for a filter hash and relay
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
      String filterHash, String relayUrl);

  /// Load all fetched range records for a relay (all filters)
  Future<List<FilterFetchedRangeRecord>>
      loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl);

  /// Remove all fetched range records for a filter hash
  Future<void> removeFilterFetchedRangeRecords(String filterHash);

  /// Remove fetched range records for a specific filter hash and relay
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
      String filterHash, String relayUrl);

  /// Remove all fetched range records for a relay
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl);

  /// Remove all filter fetched range records
  Future<void> removeAllFilterFetchedRangeRecords();

  /// Clears all cached data.
  ///
  /// **DANGER**: This will permanently delete ALL cached data including events,
  /// metadata, contact lists, relay sets, user relay lists, nip05 records,
  /// and filter fetched range records. This operation cannot be undone.
  Future<void> clearAll();
}
