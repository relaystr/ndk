import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'filter.dart';
import '../../shared/isolates/isolate_manager.dart';

/// A time range that has been fetched from a relay
class TimeRange {
  /// Start timestamp (inclusive)
  final int since;

  /// End timestamp (inclusive)
  final int until;

  const TimeRange({
    required this.since,
    required this.until,
  });

  /// Check if this range overlaps or is adjacent to another range
  bool canMergeWith(TimeRange other) {
    // Adjacent or overlapping: one's end touches or exceeds the other's start
    return until >= other.since - 1 && since <= other.until + 1;
  }

  /// Merge this range with another (assumes they can be merged)
  TimeRange mergeWith(TimeRange other) {
    return TimeRange(
      since: min(since, other.since),
      until: max(until, other.until),
    );
  }

  /// Check if this range fully contains a time period
  bool contains(int start, int end) {
    return since <= start && until >= end;
  }

  /// Check if this range overlaps with a time period
  bool overlaps(int start, int end) {
    return since <= end && until >= start;
  }

  @override
  String toString() => 'TimeRange($since - $until)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRange && since == other.since && until == other.until;

  @override
  int get hashCode => since.hashCode ^ until.hashCode;

  Map<String, dynamic> toJson() => {
        'since': since,
        'until': until,
      };

  factory TimeRange.fromJson(Map<String, dynamic> json) => TimeRange(
        since: json['since'] as int,
        until: json['until'] as int,
      );
}

/// A gap in fetched ranges (missing time range)
class FetchedRangesGap {
  final String relayUrl;
  final int since;
  final int until;

  const FetchedRangesGap({
    required this.relayUrl,
    required this.since,
    required this.until,
  });

  @override
  String toString() => 'FetchedRangesGap($relayUrl: $since - $until)';
}

/// Fetched ranges information for a specific relay and filter combination
class RelayFetchedRanges {
  final String relayUrl;
  final Filter filter;
  final List<TimeRange> ranges;

  const RelayFetchedRanges({
    required this.relayUrl,
    required this.filter,
    required this.ranges,
  });

  /// Oldest timestamp we have data for (start of first range)
  int? get oldest {
    if (ranges.isEmpty) return null;
    return ranges.map((r) => r.since).reduce(min);
  }

  /// Whether we've confirmed there's no older data on this relay
  bool get reachedOldest => oldest == 0;

  /// Newest timestamp we have data for (end of last range)
  int? get newest {
    if (ranges.isEmpty) return null;
    return ranges.map((r) => r.until).reduce(max);
  }

  /// Calculate gaps between ranges for a given time period
  List<TimeRange> findGaps(int since, int until) {
    if (ranges.isEmpty) {
      return [TimeRange(since: since, until: until)];
    }

    // Sort ranges by since
    final sortedRanges = List<TimeRange>.from(ranges)
      ..sort((a, b) => a.since.compareTo(b.since));

    final gaps = <TimeRange>[];
    var currentPos = since;

    for (final range in sortedRanges) {
      // Skip ranges that end before our period starts
      if (range.until < since) continue;
      // Stop if range starts after our period ends
      if (range.since > until) break;

      // Gap before this range?
      if (currentPos < range.since) {
        gaps.add(TimeRange(
          since: currentPos,
          until: min(range.since - 1, until),
        ));
      }

      // Move position past this range
      currentPos = max(currentPos, range.until + 1);
    }

    // Gap after last range?
    if (currentPos <= until) {
      gaps.add(TimeRange(
        since: currentPos,
        until: until,
      ));
    }

    return gaps;
  }

  /// Get gaps as FetchedRangesGap objects
  List<FetchedRangesGap> getGaps(int since, int until) {
    return findGaps(since, until)
        .map((g) => FetchedRangesGap(
              relayUrl: relayUrl,
              since: g.since,
              until: g.until,
            ))
        .toList();
  }

  @override
  String toString() =>
      'RelayFetchedRanges($relayUrl, ${ranges.length} ranges, oldest: $oldest, newest: $newest, reachedOldest: $reachedOldest)';
}

/// Record stored in the database for filter fetched ranges
class FilterFetchedRangeRecord {
  /// Hash of the filter (without since/until)
  final String filterHash;

  /// The relay URL
  final String relayUrl;

  /// Start of the covered range
  final int rangeStart;

  /// End of the covered range
  final int rangeEnd;

  const FilterFetchedRangeRecord({
    required this.filterHash,
    required this.relayUrl,
    required this.rangeStart,
    required this.rangeEnd,
  });

  /// Create a unique key for this record
  String get key => '$filterHash:$relayUrl:$rangeStart';

  @override
  String toString() =>
      'FilterFetchedRangeRecord($filterHash, $relayUrl, $rangeStart-$rangeEnd)';

  Map<String, dynamic> toJson() => {
        'filterHash': filterHash,
        'relayUrl': relayUrl,
        'rangeStart': rangeStart,
        'rangeEnd': rangeEnd,
      };

  factory FilterFetchedRangeRecord.fromJson(Map<String, dynamic> json) =>
      FilterFetchedRangeRecord(
        filterHash: json['filterHash'] as String,
        relayUrl: json['relayUrl'] as String,
        rangeStart: json['rangeStart'] as int,
        rangeEnd: json['rangeEnd'] as int,
      );
}

/// Utility to generate a hash for a filter (excluding temporal fields)
class FilterFingerprint {
  /// Generate a stable hash for a filter, excluding since/until/limit
  /// Synchronous version - use [generateAsync] for heavy workloads
  static String generate(Filter filter) {
    return _computeFingerprintFromMap(_filterToMap(filter));
  }

  /// Async version using isolate for expensive SHA256 computation
  static Future<String> generateAsync(Filter filter) async {
    final map = _filterToMap(filter);
    return IsolateManager.instance.runInComputeIsolate(
      _computeFingerprintFromMap,
      map,
    );
  }

  /// Convert filter to a serializable map (for isolate transfer)
  static Map<String, dynamic> _filterToMap(Filter filter) {
    final map = <String, dynamic>{};

    if (filter.ids != null && filter.ids!.isNotEmpty) {
      map['ids'] = List<String>.from(filter.ids!)..sort();
    }
    if (filter.authors != null && filter.authors!.isNotEmpty) {
      map['authors'] = List<String>.from(filter.authors!)..sort();
    }
    if (filter.kinds != null && filter.kinds!.isNotEmpty) {
      map['kinds'] = List<int>.from(filter.kinds!)..sort();
    }
    if (filter.search != null) {
      map['search'] = filter.search;
    }
    if (filter.tags != null && filter.tags!.isNotEmpty) {
      final sortedTags = <String, List<String>>{};
      final keys = filter.tags!.keys.toList()..sort();
      for (final key in keys) {
        sortedTags[key] = List<String>.from(filter.tags![key]!)..sort();
      }
      map['tags'] = sortedTags;
    }

    return map;
  }
}

/// Top-level function for isolate - computes SHA256 hash from map
String _computeFingerprintFromMap(Map<String, dynamic> map) {
  final jsonStr = jsonEncode(map);
  final bytes = utf8.encode(jsonStr);
  final digest = sha256.convert(bytes);
  return digest.toString().substring(0, 16);
}
