import '../../entities/filter.dart';
import '../../entities/filter_fetched_ranges.dart';
import '../../repositories/cache_manager.dart';

/// Usecase to track and query fetched ranges per relay
class FetchedRanges {
  final CacheManager _cacheManager;

  FetchedRanges({
    required CacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  /// Get fetched ranges for a filter across all relays
  Future<Map<String, RelayFetchedRanges>> getForFilter(Filter filter) async {
    final filterHash = await FilterFingerprint.generateAsync(filter);
    final records =
        await _cacheManager.loadFilterFetchedRangeRecords(filterHash);

    return _buildFetchedRangesMap(filter, records);
  }

  /// Get all fetched ranges for a relay (all filters)
  Future<List<RelayFetchedRanges>> getForRelay(String relayUrl) async {
    final records =
        await _cacheManager.loadFilterFetchedRangeRecordsByRelayUrl(relayUrl);

    // Group by filterHash
    final grouped = <String, List<FilterFetchedRangeRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.filterHash, () => []).add(record);
    }

    // Build RelayFetchedRanges for each filter
    // Note: We don't have the original filter, so we create an empty one
    // The filterHash is preserved but the filter details are not available
    final result = <RelayFetchedRanges>[];
    for (final entry in grouped.entries) {
      final relayRecords =
          entry.value.where((r) => r.relayUrl == relayUrl).toList();
      if (relayRecords.isNotEmpty) {
        result.add(_buildRelayFetchedRanges(
          relayUrl,
          Filter(), // Empty filter - we only have the hash
          relayRecords,
        ));
      }
    }

    return result;
  }

  /// Find gaps in fetched ranges for a filter within a time range
  Future<List<FetchedRangesGap>> findGaps({
    required Filter filter,
    required int since,
    required int until,
  }) async {
    final fetchedRangesMap = await getForFilter(filter);
    final gaps = <FetchedRangesGap>[];

    for (final entry in fetchedRangesMap.entries) {
      gaps.addAll(entry.value.getGaps(since, until));
    }

    return gaps;
  }

  /// Get optimized filters for each relay to fill gaps
  /// Returns a map of relay URL to list of filters covering only the gaps
  Future<Map<String, List<Filter>>> getOptimizedFilters({
    required Filter filter,
    required int since,
    required int until,
  }) async {
    final fetchedRangesMap = await getForFilter(filter);
    final result = <String, List<Filter>>{};

    for (final entry in fetchedRangesMap.entries) {
      final relayUrl = entry.key;
      final fetchedRanges = entry.value;

      final gaps = fetchedRanges.findGaps(since, until);
      if (gaps.isNotEmpty) {
        result[relayUrl] = gaps.map((gap) {
          final gapFilter = filter.clone();
          gapFilter.since = gap.since;
          gapFilter.until = gap.until;
          return gapFilter;
        }).toList();
      }
    }

    return result;
  }

  /// Add a fetched range for a filter/relay combination
  /// Automatically merges with existing adjacent/overlapping ranges
  Future<void> addRange({
    required Filter filter,
    required String relayUrl,
    required int since,
    required int until,
  }) async {
    final filterHash = await FilterFingerprint.generateAsync(filter);

    // Load existing records for this filter/relay
    final existingRecords = await _cacheManager
        .loadFilterFetchedRangeRecordsByRelay(filterHash, relayUrl);

    // Convert to TimeRanges for merging
    final ranges = existingRecords
        .map((r) => TimeRange(
              since: r.rangeStart,
              until: r.rangeEnd,
            ))
        .toList();

    // Add the new range
    ranges.add(TimeRange(since: since, until: until));

    // Merge overlapping/adjacent ranges
    final mergedRanges = _mergeRanges(ranges);

    // Delete old records for this filter/relay and save merged ones
    await _cacheManager.removeFilterFetchedRangeRecordsByFilterAndRelay(
        filterHash, relayUrl);

    final newRecords = mergedRanges.map((range) {
      return FilterFetchedRangeRecord(
        filterHash: filterHash,
        relayUrl: relayUrl,
        rangeStart: range.since,
        rangeEnd: range.until,
      );
    }).toList();

    await _cacheManager.saveFilterFetchedRangeRecords(newRecords);
  }

  /// Clear fetched ranges for a specific filter
  Future<void> clearForFilter(Filter filter) async {
    final filterHash = await FilterFingerprint.generateAsync(filter);
    await _cacheManager.removeFilterFetchedRangeRecords(filterHash);
  }

  /// Clear all fetched range records for a relay
  Future<void> clearForRelay(String relayUrl) async {
    await _cacheManager.removeFilterFetchedRangeRecordsByRelay(relayUrl);
  }

  /// Clear all fetched range records
  Future<void> clearAll() async {
    await _cacheManager.removeAllFilterFetchedRangeRecords();
  }

  // =====================
  // Private helpers
  // =====================

  /// Build a map of relay URL to RelayFetchedRanges from records
  Map<String, RelayFetchedRanges> _buildFetchedRangesMap(
    Filter filter,
    List<FilterFetchedRangeRecord> records,
  ) {
    // Group by relay
    final grouped = <String, List<FilterFetchedRangeRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.relayUrl, () => []).add(record);
    }

    // Build RelayFetchedRanges for each relay
    final result = <String, RelayFetchedRanges>{};
    for (final entry in grouped.entries) {
      result[entry.key] =
          _buildRelayFetchedRanges(entry.key, filter, entry.value);
    }

    return result;
  }

  /// Build a RelayFetchedRanges from records for a single relay
  RelayFetchedRanges _buildRelayFetchedRanges(
    String relayUrl,
    Filter filter,
    List<FilterFetchedRangeRecord> records,
  ) {
    final ranges = records
        .map((r) => TimeRange(
              since: r.rangeStart,
              until: r.rangeEnd,
            ))
        .toList()
      ..sort((a, b) => a.since.compareTo(b.since));

    return RelayFetchedRanges(
      relayUrl: relayUrl,
      filter: filter,
      ranges: ranges,
    );
  }

  /// Merge overlapping and adjacent time ranges
  List<TimeRange> _mergeRanges(List<TimeRange> ranges) {
    if (ranges.isEmpty) return [];

    // Sort by since
    final sorted = List<TimeRange>.from(ranges)
      ..sort((a, b) => a.since.compareTo(b.since));

    final merged = <TimeRange>[];
    var current = sorted.first;

    for (var i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      if (current.canMergeWith(next)) {
        current = current.mergeWith(next);
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);

    return merged;
  }
}
