import '../entities/contact_list.dart';
import '../entities/filter_fetched_ranges.dart';
import '../entities/nip_01_event.dart';
import '../entities/nip_05.dart';
import '../entities/relay_set.dart';
import '../entities/user_relay_list.dart';
import '../entities/metadata.dart';

abstract class CacheManager {
  /// closes the cache manger \
  /// used to close the db
  Future<void> close();

  Future<void> saveEvent(Nip01Event event);
  Future<void> saveEvents(List<Nip01Event> events);
  Future<Nip01Event?> loadEvent(String id);
  Future<List<Nip01Event>> loadEvents({
    List<String> pubKeys,
    List<int> kinds,
    String? pTag,
    int? since,
    int? until,
    int? limit,
  });
  Future<void> removeEvent(String id);
  Future<void> removeAllEventsByPubKey(String pubKey);
  Future<void> removeAllEvents();

  Future<void> saveUserRelayList(UserRelayList userRelayList);
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists);
  Future<UserRelayList?> loadUserRelayList(String pubKey);
  Future<void> removeUserRelayList(String pubKey);
  Future<void> removeAllUserRelayLists();

  Future<RelaySet?> loadRelaySet(String name, String pubKey);
  Future<void> saveRelaySet(RelaySet relaySet);
  Future<void> removeRelaySet(String name, String pubKey);
  Future<void> removeAllRelaySets();

  Future<void> saveContactList(ContactList contactList);
  Future<void> saveContactLists(List<ContactList> contactLists);
  Future<ContactList?> loadContactList(String pubKey);
  Future<void> removeContactList(String pubKey);
  Future<void> removeAllContactLists();

  Future<void> saveMetadata(Metadata metadata);
  Future<void> saveMetadatas(List<Metadata> metadatas);
  Future<Metadata?> loadMetadata(String pubKey);
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys);
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
  Future<Nip05?> loadNip05(String pubKey);
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys);
  Future<void> removeNip05(String pubKey);
  Future<void> removeAllNip05s();

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
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelayUrl(
      String relayUrl);

  /// Remove all fetched range records for a filter hash
  Future<void> removeFilterFetchedRangeRecords(String filterHash);

  /// Remove fetched range records for a specific filter hash and relay
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
      String filterHash, String relayUrl);

  /// Remove all fetched range records for a relay
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl);

  /// Remove all filter fetched range records
  Future<void> removeAllFilterFetchedRangeRecords();
}
