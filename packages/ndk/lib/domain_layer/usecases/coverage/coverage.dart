import '../../entities/filter.dart';
import '../../entities/filter_coverage.dart';
import '../../repositories/cache_manager.dart';

/// Usecase to track and query filter coverage per relay
class Coverage {
  final CacheManager _cacheManager;

  Coverage({
    required CacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  /// Get coverage for a filter across all relays
  Future<Map<String, RelayCoverage>> getForFilter(Filter filter) async {
    final filterHash = FilterFingerprint.generate(filter);
    final records = await _cacheManager.loadFilterCoverageRecords(filterHash);

    return _buildCoverageMap(filter, records);
  }

  /// Get all coverages for a relay (all filters)
  Future<List<RelayCoverage>> getForRelay(String relayUrl) async {
    final records =
        await _cacheManager.loadFilterCoverageRecordsByRelayUrl(relayUrl);

    // Group by filterHash
    final grouped = <String, List<FilterCoverageRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.filterHash, () => []).add(record);
    }

    // Build RelayCoverage for each filter
    // Note: We don't have the original filter, so we create an empty one
    // The filterHash is preserved but the filter details are not available
    final result = <RelayCoverage>[];
    for (final entry in grouped.entries) {
      final relayRecords =
          entry.value.where((r) => r.relayUrl == relayUrl).toList();
      if (relayRecords.isNotEmpty) {
        result.add(_buildRelayCoverage(
          relayUrl,
          Filter(), // Empty filter - we only have the hash
          relayRecords,
        ));
      }
    }

    return result;
  }

  /// Find gaps in coverage for a filter within a time range
  Future<List<CoverageGap>> findGaps({
    required Filter filter,
    required int since,
    required int until,
  }) async {
    final coverageMap = await getForFilter(filter);
    final gaps = <CoverageGap>[];

    for (final entry in coverageMap.entries) {
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
    final coverageMap = await getForFilter(filter);
    final result = <String, List<Filter>>{};

    for (final entry in coverageMap.entries) {
      final relayUrl = entry.key;
      final coverage = entry.value;

      final gaps = coverage.findGaps(since, until);
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

  /// Add a coverage range for a filter/relay combination
  /// Automatically merges with existing adjacent/overlapping ranges
  Future<void> addRange({
    required Filter filter,
    required String relayUrl,
    required int since,
    required int until,
  }) async {
    final filterHash = FilterFingerprint.generate(filter);

    // Load existing records for this filter/relay
    final existingRecords = await _cacheManager
        .loadFilterCoverageRecordsByRelay(filterHash, relayUrl);

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
    await _cacheManager.removeFilterCoverageRecordsByFilterAndRelay(
        filterHash, relayUrl);

    final newRecords = mergedRanges.map((range) {
      return FilterCoverageRecord(
        filterHash: filterHash,
        relayUrl: relayUrl,
        rangeStart: range.since,
        rangeEnd: range.until,
      );
    }).toList();

    await _cacheManager.saveFilterCoverageRecords(newRecords);
  }

  /// Clear coverage for a specific filter
  Future<void> clearForFilter(Filter filter) async {
    final filterHash = FilterFingerprint.generate(filter);
    await _cacheManager.removeFilterCoverageRecords(filterHash);
  }

  /// Clear all coverage records for a relay
  Future<void> clearForRelay(String relayUrl) async {
    await _cacheManager.removeFilterCoverageRecordsByRelay(relayUrl);
  }

  /// Clear all coverage records
  Future<void> clearAll() async {
    await _cacheManager.removeAllFilterCoverageRecords();
  }

  // =====================
  // Private helpers
  // =====================

  /// Build a map of relay URL to RelayCoverage from records
  Map<String, RelayCoverage> _buildCoverageMap(
    Filter filter,
    List<FilterCoverageRecord> records,
  ) {
    // Group by relay
    final grouped = <String, List<FilterCoverageRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.relayUrl, () => []).add(record);
    }

    // Build RelayCoverage for each relay
    final result = <String, RelayCoverage>{};
    for (final entry in grouped.entries) {
      result[entry.key] = _buildRelayCoverage(entry.key, filter, entry.value);
    }

    return result;
  }

  /// Build a RelayCoverage from records for a single relay
  RelayCoverage _buildRelayCoverage(
    String relayUrl,
    Filter filter,
    List<FilterCoverageRecord> records,
  ) {
    final ranges = records
        .map((r) => TimeRange(
              since: r.rangeStart,
              until: r.rangeEnd,
            ))
        .toList()
      ..sort((a, b) => a.since.compareTo(b.since));

    return RelayCoverage(
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
