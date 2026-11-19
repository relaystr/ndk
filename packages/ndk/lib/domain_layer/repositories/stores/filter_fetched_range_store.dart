import '../../entities/filter_fetched_ranges.dart';

abstract interface class FilterFetchedRangeStore {
  /// Save a filter fetched range record
  Future<void> saveFilterFetchedRangeRecord(FilterFetchedRangeRecord record);

  /// Save multiple filter fetched range records
  Future<void> saveFilterFetchedRangeRecords(
    List<FilterFetchedRangeRecord> records,
  );

  /// Load all fetched range records for a filter hash
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
    String filterHash,
  );

  /// Load all fetched range records for a filter hash and relay
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
    String filterHash,
    String relayUrl,
  );

  /// Load all fetched range records for a relay (all filters)
  Future<List<FilterFetchedRangeRecord>>
  loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl);

  /// Remove all fetched range records for a filter hash
  Future<void> removeFilterFetchedRangeRecords(String filterHash);

  /// Remove fetched range records for a specific filter hash and relay
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
    String filterHash,
    String relayUrl,
  );

  /// Remove all fetched range records for a relay
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl);

  /// Remove all filter fetched range records
  Future<void> removeAllFilterFetchedRangeRecords();
}
