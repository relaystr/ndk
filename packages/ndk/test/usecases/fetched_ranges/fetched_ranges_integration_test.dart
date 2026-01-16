import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_relay.dart';

void main() async {
  KeyPair key1 = Bip340.generatePrivateKey();

  Nip01Event textNoteWithTimestamp(KeyPair key, int timestamp) {
    Nip01Event event = Nip01Event(
      kind: Nip01Event.kTextNodeKind,
      pubKey: key.publicKey,
      content: "test note at $timestamp",
      tags: [],
      createdAt: timestamp,
    );
    event.sign(key.privateKey!);
    return event;
  }

  group('FetchedRanges integration', () {
    test('query automatically records fetched ranges based on event timestamps',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      // Create event with specific timestamp
      final event1 = textNoteWithTimestamp(key1, 150);
      Map<KeyPair, Nip01Event> textNotes = {key1: event1};

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

      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
      );

      // Make query
      final response = ndk.requests.query(filters: [filter]);

      // Wait for response to complete
      await response.future;

      // Small delay to ensure fetched ranges are recorded
      await Future.delayed(const Duration(milliseconds: 100));

      // Check fetched ranges were recorded
      final fetchedRanges = await ndk.fetchedRanges.getForFilter(filter);

      expect(fetchedRanges.isNotEmpty, isTrue,
          reason: 'Fetched ranges should be recorded after query');
      expect(fetchedRanges.containsKey(relay1.url), isTrue,
          reason: 'Fetched ranges should contain the relay URL');

      final relayFetchedRanges = fetchedRanges[relay1.url]!;
      expect(relayFetchedRanges.ranges.isNotEmpty, isTrue,
          reason: 'Should have at least one range');

      // Fetched range since should be based on the event's createdAt (150)
      // Fetched range until should extend to now (no filter.until specified)
      expect(relayFetchedRanges.ranges.first.since, equals(150),
          reason: 'Range since should match oldest event timestamp');
      expect(relayFetchedRanges.ranges.first.until, greaterThan(150),
          reason:
              'Range until should extend to now (EOSE means no newer events)');

      await relay1.stopServer();
      await ndk.destroy();
    });

    test('fetched ranges reflect actual events received, not filter bounds',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      // Create event with timestamp 500
      final event1 = textNoteWithTimestamp(key1, 500);
      Map<KeyPair, Nip01Event> textNotes = {key1: event1};

      MockRelay relay1 = MockRelay(
        name: "relay bounds test",
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

      // Query with wide bounds (100-1000), but event is at 500
      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: 100,
        until: 1000,
      );

      final response = ndk.requests.query(filters: [filter]);
      await response.future;
      await Future.delayed(const Duration(milliseconds: 100));

      final fetchedRanges = await ndk.fetchedRanges.getForFilter(filter);

      expect(fetchedRanges.containsKey(relay1.url), isTrue);

      final relayFetchedRanges = fetchedRanges[relay1.url]!;
      // Fetched range since should be event timestamp (500), not filter.since (100)
      // Fetched range until should be filter.until (1000) since EOSE confirms no newer events
      expect(relayFetchedRanges.ranges.first.since, equals(500),
          reason: 'Fetched range since should reflect oldest event timestamp');
      expect(relayFetchedRanges.ranges.first.until, equals(1000),
          reason:
              'Fetched range until should be filter.until (EOSE confirms coverage)');

      await relay1.stopServer();
      await ndk.destroy();
    });

    test('fetched ranges recorded with filter bounds when no events received',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      // Empty - no events
      Map<KeyPair, Nip01Event> textNotes = {};

      MockRelay relay1 = MockRelay(
        name: "relay empty test",
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

      // Filter with explicit bounds
      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
        since: 100,
        until: 200,
      );

      final response = ndk.requests.query(filters: [filter]);
      await response.future;
      await Future.delayed(const Duration(milliseconds: 100));

      final fetchedRanges = await ndk.fetchedRanges.getForFilter(filter);

      // No events but filter has bounds = fetched ranges recorded with filter bounds
      expect(fetchedRanges.containsKey(relay1.url), isTrue,
          reason: 'Fetched ranges should be recorded using filter bounds');

      final relayFetchedRanges = fetchedRanges[relay1.url]!;
      expect(relayFetchedRanges.ranges.first.since, equals(100));
      expect(relayFetchedRanges.ranges.first.until, equals(200));

      await relay1.stopServer();
      await ndk.destroy();
    });

    test('fetched ranges use event timestamp',
        timeout: const Timeout(Duration(seconds: 5)), () async {
      // Create event with specific timestamp
      final event1 = textNoteWithTimestamp(key1, 100);

      MockRelay relay1 = MockRelay(
        name: "relay event timestamp test",
        explicitPort: 4203,
        signEvents: false,
      );
      await relay1.startServer(textNotes: {key1: event1});

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

      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
      );

      final response = ndk.requests.query(filters: [filter]);
      await response.future;
      await Future.delayed(const Duration(milliseconds: 100));

      final fetchedRanges = await ndk.fetchedRanges.getForFilter(filter);

      expect(fetchedRanges.containsKey(relay1.url), isTrue);

      final relayFetchedRanges = fetchedRanges[relay1.url]!;
      // since = oldest event timestamp, until = now (no filter.until)
      expect(relayFetchedRanges.ranges.first.since, equals(100));
      expect(relayFetchedRanges.ranges.first.until, greaterThan(100));

      await relay1.stopServer();
      await ndk.destroy();
    });
  });
}
