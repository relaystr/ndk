import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  group('TrustedAssertions', () {
    late MockRelay relay;
    late Ndk ndk;

    // Provider keys
    final providerKey = Bip340.generatePrivateKey();

    // Subject (user being rated)
    final subjectKey = Bip340.generatePrivateKey();

    // Create a NIP-85 user assertion event (kind 30382)
    Nip01Event createNip85UserAssertion({
      required String providerPubkey,
      required String subjectPubkey,
      int rank = 85,
      int followers = 1000,
      int postCount = 500,
    }) {
      return Nip01Event(
        pubKey: providerPubkey,
        kind: Nip85Kind.user,
        tags: [
          ['d', subjectPubkey],
          ['rank', rank.toString()],
          ['followers', followers.toString()],
          ['post_cnt', postCount.toString()],
          ['t', 'nostr'],
          ['t', 'bitcoin'],
        ],
        content: '',
      );
    }

    setUp(() async {
      relay = MockRelay(name: 'nip85-relay', explicitPort: 5196);

      // Create assertion event
      final assertionEvent = createNip85UserAssertion(
        providerPubkey: providerKey.publicKey,
        subjectPubkey: subjectKey.publicKey,
        rank: 89,
        followers: 2500,
        postCount: 150,
      );
      assertionEvent.sign(providerKey.privateKey!);

      // Start relay with NIP-85 assertions
      await relay.startServer(
        nip85Assertions: {
          '${providerKey.publicKey}:${subjectKey.publicKey}': assertionEvent,
        },
      );

      // Configure NDK with trusted provider
      final config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay.url],
        defaultTrustedProviders: [
          Nip85TrustedProvider(
            kind: Nip85Kind.user,
            metric: Nip85Metric.rank,
            pubkey: providerKey.publicKey,
            relay: relay.url,
          ),
          Nip85TrustedProvider(
            kind: Nip85Kind.user,
            metric: Nip85Metric.followers,
            pubkey: providerKey.publicKey,
            relay: relay.url,
          ),
          Nip85TrustedProvider(
            kind: Nip85Kind.user,
            metric: Nip85Metric.postCount,
            pubkey: providerKey.publicKey,
            relay: relay.url,
          ),
        ],
      );

      ndk = Ndk(config);
      await ndk.relays.seedRelaysConnected;
    });

    tearDown(() async {
      await ndk.destroy();
      await relay.stopServer();
    });

    test('getUserMetrics returns metrics from provider', () async {
      final metrics = await ndk.ta.getUserMetrics(subjectKey.publicKey);

      expect(metrics, isNotNull);
      expect(metrics!.pubkey, equals(subjectKey.publicKey));
      expect(metrics.providerPubkey, equals(providerKey.publicKey));
      expect(metrics.rank, equals(89));
      expect(metrics.followers, equals(2500));
      expect(metrics.postCount, equals(150));
      expect(metrics.topics, contains('nostr'));
      expect(metrics.topics, contains('bitcoin'));
    });

    test('getUserMetrics returns null for unknown pubkey', () async {
      final unknownKey = Bip340.generatePrivateKey();
      final metrics = await ndk.ta.getUserMetrics(unknownKey.publicKey);

      expect(metrics, isNull);
    });

    test('getUserMetrics filters specific metrics', () async {
      final metrics = await ndk.ta.getUserMetrics(
        subjectKey.publicKey,
        metrics: {Nip85Metric.rank, Nip85Metric.followers},
      );

      expect(metrics, isNotNull);
      expect(metrics!.rank, equals(89));
      expect(metrics.followers, equals(2500));
      // postCount should not be included when filtering
      expect(metrics.postCount, isNull);
    });

    test('getUserMetrics returns null when no providers configured', () async {
      // Create NDK without trusted providers
      final ndkNoProviders = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay.url],
        defaultTrustedProviders: [],
      ));

      await ndkNoProviders.relays.seedRelaysConnected;

      final metrics = await ndkNoProviders.ta.getUserMetrics(
        subjectKey.publicKey,
      );

      expect(metrics, isNull);

      await ndkNoProviders.destroy();
    });

    test('getUserMetrics with custom providers', () async {
      // Create a second provider
      final provider2Key = Bip340.generatePrivateKey();

      final relay2 = MockRelay(name: 'nip85-relay-2', explicitPort: 5197);

      final assertionEvent2 = createNip85UserAssertion(
        providerPubkey: provider2Key.publicKey,
        subjectPubkey: subjectKey.publicKey,
        rank: 75,
        followers: 500,
        postCount: 50,
      );
      assertionEvent2.sign(provider2Key.privateKey!);

      await relay2.startServer(
        nip85Assertions: {
          '${provider2Key.publicKey}:${subjectKey.publicKey}': assertionEvent2,
        },
      );

      // Use custom provider instead of default
      final metrics = await ndk.ta.getUserMetrics(
        subjectKey.publicKey,
        providers: [
          Nip85TrustedProvider(
            kind: Nip85Kind.user,
            metric: Nip85Metric.rank,
            pubkey: provider2Key.publicKey,
            relay: relay2.url,
          ),
        ],
      );

      expect(metrics, isNotNull);
      expect(metrics!.rank, equals(75));
      expect(metrics.providerPubkey, equals(provider2Key.publicKey));

      await relay2.stopServer();
    });

    test('Nip85TrustedProvider.fromTag parses correctly', () {
      final tag = ['30382:rank', 'abc123', 'wss://relay.example.com'];
      final provider = Nip85TrustedProvider.fromTag(tag);

      expect(provider, isNotNull);
      expect(provider!.kind, equals(30382));
      expect(provider.metric, equals(Nip85Metric.rank));
      expect(provider.pubkey, equals('abc123'));
      expect(provider.relay, equals('wss://relay.example.com'));
    });

    test('Nip85TrustedProvider.toTag converts correctly', () {
      final provider = Nip85TrustedProvider(
        kind: Nip85Kind.user,
        metric: Nip85Metric.followers,
        pubkey: 'xyz789',
        relay: 'wss://test.relay',
      );

      final tag = provider.toTag();

      expect(tag, equals(['30382:followers', 'xyz789', 'wss://test.relay']));
    });
  });
}
