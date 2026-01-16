import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

void main() {
  late MemCacheManager cacheManager;
  late FetchedRanges fetchedRanges;

  setUp(() {
    cacheManager = MemCacheManager();
    fetchedRanges = FetchedRanges(cacheManager: cacheManager);
  });

  group('FetchedRanges.addRange', () {
    test('adds a new range for a filter/relay', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      final result = await fetchedRanges.getForFilter(filter);

      expect(result.containsKey('wss://relay.example.com'), isTrue);
      expect(result['wss://relay.example.com']!.ranges.length, 1);
      expect(result['wss://relay.example.com']!.ranges[0].since, 100);
      expect(result['wss://relay.example.com']!.ranges[0].until, 200);
    });

    test('merges adjacent ranges', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 201,
        until: 300,
      );

      final result = await fetchedRanges.getForFilter(filter);

      expect(result['wss://relay.example.com']!.ranges.length, 1);
      expect(result['wss://relay.example.com']!.ranges[0].since, 100);
      expect(result['wss://relay.example.com']!.ranges[0].until, 300);
    });

    test('merges overlapping ranges', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 250,
      );

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 200,
        until: 400,
      );

      final result = await fetchedRanges.getForFilter(filter);

      expect(result['wss://relay.example.com']!.ranges.length, 1);
      expect(result['wss://relay.example.com']!.ranges[0].since, 100);
      expect(result['wss://relay.example.com']!.ranges[0].until, 400);
    });

    test('keeps separate ranges when not adjacent', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 400,
        until: 500,
      );

      final result = await fetchedRanges.getForFilter(filter);

      expect(result['wss://relay.example.com']!.ranges.length, 2);
    });

    test('tracks different relays separately', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay1.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay2.example.com',
        since: 150,
        until: 300,
      );

      final result = await fetchedRanges.getForFilter(filter);

      expect(result.length, 2);
      expect(result['wss://relay1.example.com']!.ranges[0].since, 100);
      expect(result['wss://relay1.example.com']!.ranges[0].until, 200);
      expect(result['wss://relay2.example.com']!.ranges[0].since, 150);
      expect(result['wss://relay2.example.com']!.ranges[0].until, 300);
    });

    test('tracks different filters separately', () async {
      final filter1 = Filter(kinds: [1], authors: ['pubkey1']);
      final filter2 = Filter(kinds: [0], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter1,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter2,
        relayUrl: 'wss://relay.example.com',
        since: 300,
        until: 400,
      );

      final result1 = await fetchedRanges.getForFilter(filter1);
      final result2 = await fetchedRanges.getForFilter(filter2);

      expect(result1['wss://relay.example.com']!.ranges[0].since, 100);
      expect(result2['wss://relay.example.com']!.ranges[0].since, 300);
    });
  });

  group('FetchedRanges.findGaps', () {
    test('returns full range as gap when no fetched ranges', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      final gaps = await fetchedRanges.findGaps(
        filter: filter,
        since: 100,
        until: 500,
      );

      expect(gaps, isEmpty); // No relays tracked, no gaps returned
    });

    test('returns gaps for partial coverage', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 200,
        until: 300,
      );

      final gaps = await fetchedRanges.findGaps(
        filter: filter,
        since: 100,
        until: 500,
      );

      expect(gaps.length, 2);
      expect(gaps[0].since, 100);
      expect(gaps[0].until, 199);
      expect(gaps[1].since, 301);
      expect(gaps[1].until, 500);
    });

    test('returns empty when fully covered', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 0,
        until: 1000,
      );

      final gaps = await fetchedRanges.findGaps(
        filter: filter,
        since: 100,
        until: 500,
      );

      expect(gaps, isEmpty);
    });
  });

  group('FetchedRanges.getOptimizedFilters', () {
    test('returns filters for gaps only', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 200,
        until: 300,
      );

      final optimized = await fetchedRanges.getOptimizedFilters(
        filter: filter,
        since: 100,
        until: 500,
      );

      expect(optimized.containsKey('wss://relay.example.com'), isTrue);
      final filters = optimized['wss://relay.example.com']!;
      expect(filters.length, 2);

      // First gap: 100-199
      expect(filters[0].since, 100);
      expect(filters[0].until, 199);
      expect(filters[0].kinds, [1]);
      expect(filters[0].authors, ['pubkey1']);

      // Second gap: 301-500
      expect(filters[1].since, 301);
      expect(filters[1].until, 500);
    });

    test('returns empty for fully covered relay', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 0,
        until: 1000,
      );

      final optimized = await fetchedRanges.getOptimizedFilters(
        filter: filter,
        since: 100,
        until: 500,
      );

      expect(optimized, isEmpty);
    });
  });

  group('FetchedRanges.reachedOldest', () {
    test('reachedOldest is true when oldest is 0', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 0,
        until: 200,
      );

      final result = await fetchedRanges.getForFilter(filter);

      expect(result['wss://relay.example.com']!.reachedOldest, isTrue);
    });

    test('reachedOldest is false when oldest is not 0', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      final result = await fetchedRanges.getForFilter(filter);

      expect(result['wss://relay.example.com']!.reachedOldest, isFalse);
    });
  });

  group('FetchedRanges.getForRelay', () {
    test('returns all fetched ranges for a relay', () async {
      final filter1 = Filter(kinds: [1], authors: ['pubkey1']);
      final filter2 = Filter(kinds: [0], authors: ['pubkey2']);

      await fetchedRanges.addRange(
        filter: filter1,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter2,
        relayUrl: 'wss://relay.example.com',
        since: 300,
        until: 400,
      );

      final result = await fetchedRanges.getForRelay('wss://relay.example.com');

      expect(result.length, 2);
    });
  });

  group('FetchedRanges.clearForFilter', () {
    test('clears fetched ranges for a specific filter', () async {
      final filter1 = Filter(kinds: [1], authors: ['pubkey1']);
      final filter2 = Filter(kinds: [0], authors: ['pubkey2']);

      await fetchedRanges.addRange(
        filter: filter1,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter2,
        relayUrl: 'wss://relay.example.com',
        since: 300,
        until: 400,
      );

      await fetchedRanges.clearForFilter(filter1);

      final result1 = await fetchedRanges.getForFilter(filter1);
      final result2 = await fetchedRanges.getForFilter(filter2);

      expect(result1, isEmpty);
      expect(result2.isNotEmpty, isTrue);
    });
  });

  group('FetchedRanges.clearForRelay', () {
    test('clears all fetched ranges for a relay', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay1.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay2.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.clearForRelay('wss://relay1.example.com');

      final result = await fetchedRanges.getForFilter(filter);

      expect(result.containsKey('wss://relay1.example.com'), isFalse);
      expect(result.containsKey('wss://relay2.example.com'), isTrue);
    });
  });

  group('FetchedRanges.clearAll', () {
    test('clears all fetched ranges', () async {
      final filter1 = Filter(kinds: [1], authors: ['pubkey1']);
      final filter2 = Filter(kinds: [0], authors: ['pubkey2']);

      await fetchedRanges.addRange(
        filter: filter1,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter2,
        relayUrl: 'wss://relay.example.com',
        since: 300,
        until: 400,
      );

      await fetchedRanges.clearAll();

      final result1 = await fetchedRanges.getForFilter(filter1);
      final result2 = await fetchedRanges.getForFilter(filter2);

      expect(result1, isEmpty);
      expect(result2, isEmpty);
    });
  });

  group('FetchedRanges realistic scenarios', () {
    test('handles Jan-Mar + Jun-Sep scenario with Apr-May gap', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      // Add Jan-Mar fetched range
      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.damus.io',
        since: 1704067200, // Jan 1
        until: 1711929599, // Mar 31
      );

      // Add Jun-Sep fetched range
      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.damus.io',
        since: 1717200000, // Jun 1
        until: 1727740799, // Sep 30
      );

      final result = await fetchedRanges.getForFilter(filter);
      final damusFetchedRanges = result['wss://relay.damus.io']!;

      // Should have 2 separate ranges
      expect(damusFetchedRanges.ranges.length, 2);

      // Check gaps for Jan-Oct query
      final gaps = await fetchedRanges.findGaps(
        filter: filter,
        since: 1704067200, // Jan 1
        until: 1730419199, // Oct 31
      );

      // Should have gap for Apr-May and Oct
      expect(gaps.length, 2);
    });

    test('fills gap and merges ranges', () async {
      final filter = Filter(kinds: [1], authors: ['pubkey1']);

      // Initial: two separate ranges
      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 100,
        until: 200,
      );

      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 400,
        until: 500,
      );

      // Verify 2 ranges and a gap
      var result = await fetchedRanges.getForFilter(filter);
      expect(result['wss://relay.example.com']!.ranges.length, 2);

      // Fill the gap
      await fetchedRanges.addRange(
        filter: filter,
        relayUrl: 'wss://relay.example.com',
        since: 201,
        until: 399,
      );

      // Should now be 1 merged range
      result = await fetchedRanges.getForFilter(filter);
      expect(result['wss://relay.example.com']!.ranges.length, 1);
      expect(result['wss://relay.example.com']!.ranges[0].since, 100);
      expect(result['wss://relay.example.com']!.ranges[0].until, 500);
    });
  });
}
