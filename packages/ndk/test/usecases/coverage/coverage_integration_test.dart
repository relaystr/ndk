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
    event.sign(key.privateKey!);
    return event;
  }

  Map<KeyPair, Nip01Event> textNotes = {key1: textNote(key1)};

  group('Coverage integration', () {
    test('query automatically records coverage after EOSE',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      // Setup mock relay
      MockRelay relay1 = MockRelay(
        name: "relay coverage test",
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
      final response = ndk.requests.query(filters: [filter]);

      // Wait for response to complete
      await response.future;

      // Small delay to ensure coverage is recorded
      await Future.delayed(const Duration(milliseconds: 100));

      // Check coverage was recorded
      final coverage = await ndk.coverage.getForFilter(filter);

      expect(coverage.isNotEmpty, isTrue,
          reason: 'Coverage should be recorded after query');
      expect(coverage.containsKey(relay1.url), isTrue,
          reason: 'Coverage should contain the relay URL');

      final relayCoverage = coverage[relay1.url]!;
      expect(relayCoverage.ranges.isNotEmpty, isTrue,
          reason: 'Should have at least one range');
      expect(relayCoverage.ranges.first.since, equals(since),
          reason: 'Range since should match filter since');
      expect(relayCoverage.ranges.first.until, equals(until),
          reason: 'Range until should match filter until');

      await relay1.stopServer();
      await ndk.destroy();
    });

    test('multiple queries merge coverage ranges',
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
        ),
      );

      await ndk.relays.seedRelaysConnected;

      // First query: Jan 1-15
      final filter1 = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: 100,
        until: 200,
      );

      final response1 = ndk.requests.query(filters: [filter1]);
      await response1.future;
      await Future.delayed(const Duration(milliseconds: 100));

      // Second query: Jan 16-31 (adjacent)
      final filter2 = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: 201,
        until: 300,
      );

      final response2 = ndk.requests.query(filters: [filter2]);
      await response2.future;
      await Future.delayed(const Duration(milliseconds: 100));

      // Check coverage was merged
      final coverage = await ndk.coverage.getForFilter(filter1);

      expect(coverage.containsKey(relay1.url), isTrue);

      final relayCoverage = coverage[relay1.url]!;
      // Should have merged into 1 range (100-300)
      expect(relayCoverage.ranges.length, equals(1),
          reason: 'Adjacent ranges should be merged');
      expect(relayCoverage.ranges.first.since, equals(100));
      expect(relayCoverage.ranges.first.until, equals(300));

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

      final response = ndk.requests.query(filters: [filter]);
      await response.future;
      await Future.delayed(const Duration(milliseconds: 100));

      // Find gaps for 100-500
      final gaps = await ndk.coverage.findGaps(
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

      final response = ndk.requests.query(filters: [filter]);
      await response.future;
      await Future.delayed(const Duration(milliseconds: 100));

      // Get optimized filters for 100-500
      final optimized = await ndk.coverage.getOptimizedFilters(
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
