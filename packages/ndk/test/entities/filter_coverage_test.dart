import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

void main() {
  group('TimeRange', () {
    test('constructor initializes correctly', () {
      final range = TimeRange(
        since: 1704067200,
        until: 1704153600,
        fetchedAt: 1704160000,
      );

      expect(range.since, 1704067200);
      expect(range.until, 1704153600);
      expect(range.fetchedAt, 1704160000);
    });

    test('canMergeWith detects overlapping ranges', () {
      final range1 = TimeRange(since: 100, until: 200, fetchedAt: 1000);
      final range2 = TimeRange(since: 150, until: 250, fetchedAt: 1000);

      expect(range1.canMergeWith(range2), isTrue);
      expect(range2.canMergeWith(range1), isTrue);
    });

    test('canMergeWith detects adjacent ranges', () {
      final range1 = TimeRange(since: 100, until: 200, fetchedAt: 1000);
      final range2 = TimeRange(since: 201, until: 300, fetchedAt: 1000);

      expect(range1.canMergeWith(range2), isTrue);
      expect(range2.canMergeWith(range1), isTrue);
    });

    test('canMergeWith returns false for non-adjacent ranges', () {
      final range1 = TimeRange(since: 100, until: 200, fetchedAt: 1000);
      final range2 = TimeRange(since: 300, until: 400, fetchedAt: 1000);

      expect(range1.canMergeWith(range2), isFalse);
      expect(range2.canMergeWith(range1), isFalse);
    });

    test('mergeWith combines ranges correctly', () {
      final range1 = TimeRange(since: 100, until: 200, fetchedAt: 1000);
      final range2 = TimeRange(since: 150, until: 300, fetchedAt: 2000);

      final merged = range1.mergeWith(range2);

      expect(merged.since, 100);
      expect(merged.until, 300);
      expect(merged.fetchedAt, 2000); // Takes the most recent fetchedAt
    });

    test('contains checks if range fully contains a period', () {
      final range = TimeRange(since: 100, until: 300, fetchedAt: 1000);

      expect(range.contains(150, 250), isTrue);
      expect(range.contains(100, 300), isTrue);
      expect(range.contains(50, 200), isFalse);
      expect(range.contains(200, 400), isFalse);
    });

    test('overlaps checks if range overlaps with a period', () {
      final range = TimeRange(since: 100, until: 300, fetchedAt: 1000);

      expect(range.overlaps(150, 250), isTrue);
      expect(range.overlaps(50, 150), isTrue);
      expect(range.overlaps(250, 400), isTrue);
      expect(range.overlaps(400, 500), isFalse);
      expect(range.overlaps(0, 50), isFalse);
    });

    test('toJson and fromJson work correctly', () {
      final range = TimeRange(
        since: 1704067200,
        until: 1704153600,
        fetchedAt: 1704160000,
      );

      final json = range.toJson();
      final restored = TimeRange.fromJson(json);

      expect(restored.since, range.since);
      expect(restored.until, range.until);
      expect(restored.fetchedAt, range.fetchedAt);
    });

    test('equality works correctly', () {
      final range1 = TimeRange(since: 100, until: 200, fetchedAt: 1000);
      final range2 = TimeRange(since: 100, until: 200, fetchedAt: 1000);
      final range3 = TimeRange(since: 100, until: 300, fetchedAt: 1000);

      expect(range1, equals(range2));
      expect(range1, isNot(equals(range3)));
    });
  });

  group('RelayCoverage', () {
    test('oldest and newest return correct values', () {
      final coverage = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [
          TimeRange(since: 200, until: 300, fetchedAt: 1000),
          TimeRange(since: 100, until: 150, fetchedAt: 1000),
          TimeRange(since: 500, until: 600, fetchedAt: 1000),
        ],
      );

      expect(coverage.oldest, 100);
      expect(coverage.newest, 600);
    });

    test('oldest and newest return null for empty ranges', () {
      final coverage = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [],
      );

      expect(coverage.oldest, isNull);
      expect(coverage.newest, isNull);
    });

    test('reachedOldest getter works correctly', () {
      final coverageNotReached = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [],
        reachedOldestAt: null,
      );

      final coverageReached = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [],
        reachedOldestAt: 1704160000,
      );

      expect(coverageNotReached.reachedOldest, isFalse);
      expect(coverageReached.reachedOldest, isTrue);
    });

    test('findGaps returns correct gaps for empty ranges', () {
      final coverage = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [],
      );

      final gaps = coverage.findGaps(100, 500);

      expect(gaps.length, 1);
      expect(gaps[0].since, 100);
      expect(gaps[0].until, 500);
    });

    test('findGaps returns correct gaps for single range', () {
      final coverage = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [
          TimeRange(since: 200, until: 300, fetchedAt: 1000),
        ],
      );

      final gaps = coverage.findGaps(100, 500);

      expect(gaps.length, 2);
      expect(gaps[0].since, 100);
      expect(gaps[0].until, 199);
      expect(gaps[1].since, 301);
      expect(gaps[1].until, 500);
    });

    test('findGaps returns correct gaps for multiple ranges', () {
      // Ranges: [100-150], [300-400]
      // Query: 0 to 600
      // Expected gaps: [0-99], [151-299], [401-600]
      final coverage = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [
          TimeRange(since: 100, until: 150, fetchedAt: 1000),
          TimeRange(since: 300, until: 400, fetchedAt: 1000),
        ],
      );

      final gaps = coverage.findGaps(0, 600);

      expect(gaps.length, 3);
      expect(gaps[0].since, 0);
      expect(gaps[0].until, 99);
      expect(gaps[1].since, 151);
      expect(gaps[1].until, 299);
      expect(gaps[2].since, 401);
      expect(gaps[2].until, 600);
    });

    test('findGaps returns empty list when fully covered', () {
      final coverage = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [
          TimeRange(since: 100, until: 500, fetchedAt: 1000),
        ],
      );

      final gaps = coverage.findGaps(200, 400);

      expect(gaps, isEmpty);
    });

    test('getGaps returns CoverageGap objects', () {
      final coverage = RelayCoverage(
        relayUrl: 'wss://relay.example.com',
        filter: Filter(kinds: [1]),
        ranges: [
          TimeRange(since: 200, until: 300, fetchedAt: 1000),
        ],
      );

      final gaps = coverage.getGaps(100, 500);

      expect(gaps.length, 2);
      expect(gaps[0].relayUrl, 'wss://relay.example.com');
      expect(gaps[0].since, 100);
      expect(gaps[0].until, 199);
    });
  });

  group('FilterCoverageRecord', () {
    test('constructor initializes correctly', () {
      final record = FilterCoverageRecord(
        filterHash: 'abc123',
        relayUrl: 'wss://relay.example.com',
        rangeStart: 1704067200,
        rangeEnd: 1704153600,
        fetchedAt: 1704160000,
        reachedOldest: true,
        reachedOldestAt: 1704160000,
      );

      expect(record.filterHash, 'abc123');
      expect(record.relayUrl, 'wss://relay.example.com');
      expect(record.rangeStart, 1704067200);
      expect(record.rangeEnd, 1704153600);
      expect(record.fetchedAt, 1704160000);
      expect(record.reachedOldest, isTrue);
      expect(record.reachedOldestAt, 1704160000);
    });

    test('key is generated correctly', () {
      final record = FilterCoverageRecord(
        filterHash: 'abc123',
        relayUrl: 'wss://relay.example.com',
        rangeStart: 1704067200,
        rangeEnd: 1704153600,
        fetchedAt: 1704160000,
      );

      expect(record.key, 'abc123:wss://relay.example.com:1704067200');
    });

    test('toJson and fromJson work correctly', () {
      final record = FilterCoverageRecord(
        filterHash: 'abc123',
        relayUrl: 'wss://relay.example.com',
        rangeStart: 1704067200,
        rangeEnd: 1704153600,
        fetchedAt: 1704160000,
        reachedOldest: true,
        reachedOldestAt: 1704155000,
      );

      final json = record.toJson();
      final restored = FilterCoverageRecord.fromJson(json);

      expect(restored.filterHash, record.filterHash);
      expect(restored.relayUrl, record.relayUrl);
      expect(restored.rangeStart, record.rangeStart);
      expect(restored.rangeEnd, record.rangeEnd);
      expect(restored.fetchedAt, record.fetchedAt);
      expect(restored.reachedOldest, record.reachedOldest);
      expect(restored.reachedOldestAt, record.reachedOldestAt);
    });
  });

  group('FilterFingerprint', () {
    test('generates same hash for identical filters', () {
      final filter1 = Filter(kinds: [1], authors: ['pubkey1', 'pubkey2']);
      final filter2 = Filter(kinds: [1], authors: ['pubkey1', 'pubkey2']);

      final hash1 = FilterFingerprint.generate(filter1);
      final hash2 = FilterFingerprint.generate(filter2);

      expect(hash1, equals(hash2));
    });

    test('generates same hash regardless of author order', () {
      final filter1 = Filter(kinds: [1], authors: ['pubkey1', 'pubkey2']);
      final filter2 = Filter(kinds: [1], authors: ['pubkey2', 'pubkey1']);

      final hash1 = FilterFingerprint.generate(filter1);
      final hash2 = FilterFingerprint.generate(filter2);

      expect(hash1, equals(hash2));
    });

    test('ignores since/until/limit in hash', () {
      final filter1 = Filter(kinds: [1], authors: ['pubkey1']);
      final filter2 = Filter(
        kinds: [1],
        authors: ['pubkey1'],
        since: 1704067200,
        until: 1704153600,
        limit: 100,
      );

      final hash1 = FilterFingerprint.generate(filter1);
      final hash2 = FilterFingerprint.generate(filter2);

      expect(hash1, equals(hash2));
    });

    test('generates different hash for different filters', () {
      final filter1 = Filter(kinds: [1], authors: ['pubkey1']);
      final filter2 = Filter(kinds: [1], authors: ['pubkey2']);
      final filter3 = Filter(kinds: [0], authors: ['pubkey1']);

      final hash1 = FilterFingerprint.generate(filter1);
      final hash2 = FilterFingerprint.generate(filter2);
      final hash3 = FilterFingerprint.generate(filter3);

      expect(hash1, isNot(equals(hash2)));
      expect(hash1, isNot(equals(hash3)));
    });
  });

  group('CoverageGap', () {
    test('constructor initializes correctly', () {
      final gap = CoverageGap(
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      expect(gap.relayUrl, 'wss://relay.example.com');
      expect(gap.since, 100);
      expect(gap.until, 200);
    });
  });
}
