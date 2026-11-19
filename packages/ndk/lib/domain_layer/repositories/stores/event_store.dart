import 'package:ndk_core/domain_layer/entities/filter.dart';
import 'package:ndk_core/domain_layer/entities/nip_01_event.dart';

import '../../entities/cache_eviction.dart';
import '../../entities/hidden_event.dart';

/// Canonical Nostr events, their visibility rules and their provenance.
///
/// [loadEvents] returns *visible* events only, [loadHiddenEvents] is the only
/// read that returns superseded, deleted or expired rows.
abstract interface class EventStore {
  Future<void> saveEvent(Nip01Event event);

  /// Stores [event] only when its id is not already present.
  ///
  /// Returns `true` when the event was inserted and `false` when an event with
  /// the same id already existed. Existing payloads must never be overwritten.
  Future<bool> saveEventIfAbsent(Nip01Event event);

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

  /// The `(id, createdAt)` of the events [loadEvents] returns for [filter],
  /// same visibility rules and limit.
  ///
  /// NIP-77 builds its local set from these two fields alone, so a backend
  /// that can should skip reading content, tags and signatures.
  Future<List<({String id, int createdAt})>> loadEventIdsWithCreatedAt(
    Filter filter,
  );

  /// Loads the events [loadEvents] hides, newest first.
  ///
  /// A superseded version of a replaceable event, an author-deleted event and
  /// an expired event all stay stored, and [loadEvents] never returns them.
  /// This read exposes them, which is what an app needs to show the edit
  /// history of an addressable event or the content behind a deletion.
  ///
  /// Filters combine with AND and behave like the [loadEvents] ones, with two
  /// additions:
  /// - [coordinates]: replaceable conflict domains, `kind:pubkey:d-tag` for
  ///   addressable kinds and `kind:pubkey` for other replaceable kinds. A
  ///   trailing empty d-tag is accepted, so a NIP-01 `a` tag value can be
  ///   passed as is.
  /// - [reasons]: which hidden categories to return. Pass a single reason to
  ///   ask a precise question, for example only `superseded` to list previous
  ///   versions without resurfacing deleted content.
  ///
  /// [limit] applies after hidden events are selected, unlike the pre-filter
  /// limit some backends push into their query for visible reads.
  ///
  /// Eviction removes exactly these rows: [EvictionPolicy] sweeps superseded
  /// and deleted events by default. An app that shows history must disable
  /// those two sweeps, otherwise what it wants to display is swept in the
  /// background.
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
}
