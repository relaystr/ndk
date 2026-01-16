import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_relay.dart';

void main() async {
  KeyPair key1 = Bip340.generatePrivateKey();

  Nip01Event textNote(KeyPair key) {
    Nip01Event event = Nip01Event(
      kind: Nip01Event.kTextNodeKind,
      pubKey: key.publicKey,
      content: "test note",
      tags: [],
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    return Nip01Utils.signWithPrivateKey(
        event: event, privateKey: key.privateKey!);
  }

  Map<KeyPair, Nip01Event> textNotes = {key1: textNote(key1)};

  group('FetchedRanges integration', () {
    test('query automatically records fetched ranges after EOSE',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      // Setup mock relay
      MockRelay relay1 = MockRelay(
        name: "relay fetched ranges test",
        explicitPort: 4200,
        signEvents: false,
      );
      await relay1.startServer(textNotes: textNotes);

      // Setup NDK
      final cache = MemCacheManager();
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: cache,
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: [relay1.url],
          fetchedRangesEnabled: true,
        ),
      );

      await ndk.relays.seedRelaysConnected;

      // Define filter with time bounds
      final since = DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch ~/
          1000;
      final until = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: since,
        until: until,
      );

      // Make query
      final response = ndk.requests.query(filter: filter);

      // Wait for response to complete
      await response.future;

      // Small delay to ensure fetched ranges are recorded
      await Future.delayed(const Duration(milliseconds: 100));

      // Check fetched ranges were recorded
      final fetchedRanges = await ndk.fetchedRanges.getForFilter(filter);

      expect(fetchedRanges.isNotEmpty, isTrue,
          reason: 'FetchedRanges should be recorded after query');
      expect(fetchedRanges.containsKey(relay1.url), isTrue,
          reason: 'FetchedRanges should contain the relay URL');

      final relayFetchedRanges = fetchedRanges[relay1.url]!;
      expect(relayFetchedRanges.ranges.isNotEmpty, isTrue,
          reason: 'Should have at least one range');
      expect(relayFetchedRanges.ranges.first.since, equals(since),
          reason: 'Range since should match filter since');
      expect(relayFetchedRanges.ranges.first.until, equals(until),
          reason: 'Range until should match filter until');

      await relay1.stopServer();
      await ndk.destroy();
    });

    test('multiple queries merge fetched ranges',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      MockRelay relay1 = MockRelay(
        name: "relay merge test",
        explicitPort: 4201,
        signEvents: false,
      );
      await relay1.startServer(textNotes: textNotes);

      final cache = MemCacheManager();
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: cache,
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: [relay1.url],
          fetchedRangesEnabled: true,
        ),
      );

      await ndk.relays.seedRelaysConnected;

      // First query: 100-200
      final filter1 = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: 100,
        until: 200,
      );

      final response1 = ndk.requests.query(filter: filter1);
      await response1.future;
      await Future.delayed(const Duration(milliseconds: 100));

      // Second query: 201-300 (adjacent)
      final filter2 = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: 201,
        until: 300,
      );

      final response2 = ndk.requests.query(filter: filter2);
      await response2.future;
      await Future.delayed(const Duration(milliseconds: 100));

      // Check fetched ranges were merged
      final fetchedRanges = await ndk.fetchedRanges.getForFilter(filter1);

      expect(fetchedRanges.containsKey(relay1.url), isTrue);

      final relayFetchedRanges = fetchedRanges[relay1.url]!;
      // Should have merged into 1 range (100-300)
      expect(relayFetchedRanges.ranges.length, equals(1),
          reason: 'Adjacent ranges should be merged');
      expect(relayFetchedRanges.ranges.first.since, equals(100));
      expect(relayFetchedRanges.ranges.first.until, equals(300));

      await relay1.stopServer();
      await ndk.destroy();
    });

    test('findGaps returns correct gaps after query',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      MockRelay relay1 = MockRelay(
        name: "relay gaps test",
        explicitPort: 4202,
        signEvents: false,
      );
      await relay1.startServer(textNotes: textNotes);

      final cache = MemCacheManager();
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: cache,
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: [relay1.url],
          fetchedRangesEnabled: true,
        ),
      );

      await ndk.relays.seedRelaysConnected;

      // Query for 200-300
      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: 200,
        until: 300,
      );

      final response = ndk.requests.query(filter: filter);
      await response.future;
      await Future.delayed(const Duration(milliseconds: 100));

      // Find gaps for 100-500
      final gaps = await ndk.fetchedRanges.findGaps(
        filter: filter,
        since: 100,
        until: 500,
      );

      // Should have 2 gaps: 100-199 and 301-500
      expect(gaps.length, equals(2), reason: 'Should have 2 gaps');
      expect(gaps[0].since, equals(100));
      expect(gaps[0].until, equals(199));
      expect(gaps[1].since, equals(301));
      expect(gaps[1].until, equals(500));

      await relay1.stopServer();
      await ndk.destroy();
    });

    test('getOptimizedFilters returns filters for gaps only',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      MockRelay relay1 = MockRelay(
        name: "relay optimized test",
        explicitPort: 4203,
        signEvents: false,
      );
      await relay1.startServer(textNotes: textNotes);

      final cache = MemCacheManager();
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: cache,
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: [relay1.url],
          fetchedRangesEnabled: true,
        ),
      );

      await ndk.relays.seedRelaysConnected;

      // Query for 200-300
      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: 200,
        until: 300,
      );

      final response = ndk.requests.query(filter: filter);
      await response.future;
      await Future.delayed(const Duration(milliseconds: 100));

      // Get optimized filters for 100-500
      final optimized = await ndk.fetchedRanges.getOptimizedFilters(
        filter: filter,
        since: 100,
        until: 500,
      );

      expect(optimized.containsKey(relay1.url), isTrue);

      final filters = optimized[relay1.url]!;
      expect(filters.length, equals(2), reason: 'Should have 2 gap filters');

      // First gap filter: 100-199
      expect(filters[0].since, equals(100));
      expect(filters[0].until, equals(199));
      expect(filters[0].kinds, equals([Nip01Event.kTextNodeKind]));
      expect(filters[0].authors, equals([key1.publicKey]));

      // Second gap filter: 301-500
      expect(filters[1].since, equals(301));
      expect(filters[1].until, equals(500));

      await relay1.stopServer();
      await ndk.destroy();
    });
  });
}
