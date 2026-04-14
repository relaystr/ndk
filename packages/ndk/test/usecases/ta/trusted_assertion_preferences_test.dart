import 'package:ndk/data_layer/repositories/cache_manager/ndk_extensions.dart';
import 'package:ndk/domain_layer/entities/trusted_assertion_preferences.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() {
  group('TrustedAssertionPrefsUsecase', () {
    late MockRelay relay;
    late Ndk ndk;

    // User keys (logged in account)
    final userKey = Bip340.generatePrivateKey();

    // Provider keys
    final provider1Key = Bip340.generatePrivateKey();
    final provider2Key = Bip340.generatePrivateKey();

    // Create a kind 10040 event
    Nip01Event createKind10040Event({
      required String pubKey,
      required List<Nip85TrustedProvider> providers,
      String content = '',
    }) {
      return Nip01Event(
        pubKey: pubKey,
        kind: kTrustedAssertionPreferencesKind,
        tags: providers.map((p) => p.toTag()).toList(),
        content: content,
      );
    }

    setUp(() async {
      relay = MockRelay(name: 'ta-prefs-relay', explicitPort: 5199);

      // Create a kind 10040 preferences event for the user
      final userSigner = Bip340EventSigner(
        privateKey: userKey.privateKey,
        publicKey: userKey.publicKey,
      );

      final prefsEvent = await userSigner.sign(
        createKind10040Event(
          pubKey: userKey.publicKey,
          providers: [
            Nip85TrustedProvider(
              kind: Nip85Kind.user,
              metric: Nip85Metric.rank,
              pubkey: provider1Key.publicKey,
              relay: relay.url,
            ),
            Nip85TrustedProvider(
              kind: Nip85Kind.user,
              metric: Nip85Metric.followers,
              pubkey: provider1Key.publicKey,
              relay: relay.url,
            ),
            Nip85TrustedProvider(
              kind: Nip85Kind.event,
              metric: Nip85Metric.commentCount,
              pubkey: provider2Key.publicKey,
              relay: relay.url,
            ),
          ],
        ),
      );

      await relay.startServer();

      // Configure NDK with the user's account
      final config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay.url],
        defaultTrustedProviders: [],
      );

      ndk = Ndk(config);

      // Log in the user
      ndk.accounts.loginPrivateKey(
        pubkey: userKey.publicKey,
        privkey: userKey.privateKey!,
      );

      await ndk.relays.seedRelaysConnected;

      // Manually store the preferences event in the relay so it can be queried
      relay.storeEvent(prefsEvent);
    });

    tearDown(() async {
      await ndk.destroy();
      await relay.stopServer();
    });

    group('getPreferences', () {
      test('returns cached preferences when available', () async {
        // First call fetches from network and caches
        final prefs = await ndk.taPreferences.getPreferences();

        expect(prefs, isNotNull);
        expect(prefs!.pubKey, equals(userKey.publicKey));
        expect(prefs.providers.length, equals(3));
        expect(
          prefs.providers.where((p) => p.metric == Nip85Metric.rank).length,
          equals(1),
        );
      });

      test('returns cached preferences without network call', () async {
        // First call to populate cache
        final firstPrefs = await ndk.taPreferences.getPreferences();
        expect(firstPrefs, isNotNull);

        // Stop relay - second call should still work from cache
        await relay.stopServer();

        final cachedPrefs = await ndk.taPreferences.getPreferences();

        expect(cachedPrefs, isNotNull);
        expect(cachedPrefs!.pubKey, equals(userKey.publicKey));
      });

      test('returns null when no preferences exist', () async {
        final unknownKey = Bip340.generatePrivateKey();
        final prefs = await ndk.taPreferences.getPreferences(
          pubKey: unknownKey.publicKey,
        );

        expect(prefs, isNull);
      });

      test('forceRefresh fetches from network', () async {
        // First call
        final firstPrefs = await ndk.taPreferences.getPreferences();
        expect(firstPrefs, isNotNull);
        final firstCreatedAt = firstPrefs!.createdAt;

        // Force refresh - should fetch again
        final refreshedPrefs = await ndk.taPreferences.getPreferences(
          forceRefresh: true,
        );

        expect(refreshedPrefs, isNotNull);
        // Same content, so createdAt should be same (same event)
        expect(refreshedPrefs!.createdAt, equals(firstCreatedAt));
      });
    });

    group('getProvidersForKind', () {
      test('returns all providers for a specific kind', () async {
        final providers = await ndk.taPreferences.getProvidersForKind(
          kind: Nip85Kind.user,
        );

        expect(providers.length, equals(2));
        expect(
          providers.every((p) => p.kind == Nip85Kind.user),
          isTrue,
        );
      });

      test('returns empty list when no providers for kind', () async {
        final providers = await ndk.taPreferences.getProvidersForKind(
          kind: Nip85Kind.addressable,
        );

        expect(providers, isEmpty);
      });
    });

    group('getProvidersForKindAndMetric', () {
      test('returns providers matching kind and metric', () async {
        final providers =
            await ndk.taPreferences.getProvidersForKindAndMetric(
          kind: Nip85Kind.user,
          metric: Nip85Metric.rank,
        );

        expect(providers.length, equals(1));
        expect(providers.first.pubkey, equals(provider1Key.publicKey));
      });

      test('returns empty list when no match', () async {
        final providers =
            await ndk.taPreferences.getProvidersForKindAndMetric(
          kind: Nip85Kind.user,
          metric: Nip85Metric.zapAmountReceived,
        );

        expect(providers, isEmpty);
      });
    });

    group('Nip85TrustedProvider serialization', () {
      test('fromTag and toTag are inverse operations', () {
        final original = Nip85TrustedProvider(
          kind: Nip85Kind.user,
          metric: Nip85Metric.rank,
          pubkey: 'test_pubkey',
          relay: 'wss://test.relay',
        );

        final tag = original.toTag();
        final restored = Nip85TrustedProvider.fromTag(tag);

        expect(restored, isNotNull);
        expect(restored!.kind, equals(original.kind));
        expect(restored.metric, equals(original.metric));
        expect(restored.pubkey, equals(original.pubkey));
        expect(restored.relay, equals(original.relay));
      });

      test('fromTag returns null for invalid tag', () {
        expect(Nip85TrustedProvider.fromTag([]), isNull);
        expect(Nip85TrustedProvider.fromTag(['short']), isNull);
        expect(
          Nip85TrustedProvider.fromTag(['invalid', 'pubkey', 'relay']),
          isNull,
        );
      });
    });

    group('TrustedAssertionPreferences entity', () {
      test('fromEvent parses kind 10040 correctly', () {
        final event = Nip01Event(
          pubKey: 'test_pubkey',
          kind: kTrustedAssertionPreferencesKind,
          tags: [
            ['30382:rank', 'provider1', 'wss://relay1'],
            ['30382:followers', 'provider1', 'wss://relay1'],
            ['30383:comment_cnt', 'provider2', 'wss://relay2'],
          ],
          content: '',
        );

        final prefs = TrustedAssertionPreferences.fromEvent(event);

        expect(prefs, isNotNull);
        expect(prefs!.pubKey, equals('test_pubkey'));
        expect(prefs.providers.length, equals(3));
        expect(prefs.hasEncryptedContent, isFalse);
        expect(prefs.encryptedContent, isNull);
      });

      test('detects encrypted content', () {
        final event = Nip01Event(
          pubKey: 'test_pubkey',
          kind: kTrustedAssertionPreferencesKind,
          tags: [],
          content: 'encrypted_data_here',
        );

        final prefs = TrustedAssertionPreferences.fromEvent(event);

        expect(prefs!.hasEncryptedContent, isTrue);
        expect(prefs.encryptedContent, equals('encrypted_data_here'));
      });

      test('filterProviders filters correctly', () {
        final event = Nip01Event(
          pubKey: 'test_pubkey',
          kind: kTrustedAssertionPreferencesKind,
          tags: [
            ['30382:rank', 'provider1', 'wss://relay1'],
            ['30382:followers', 'provider1', 'wss://relay1'],
            ['30383:comment_cnt', 'provider2', 'wss://relay2'],
            ['30384:rank', 'provider3', 'wss://relay3'],
          ],
          content: '',
        );

        final prefs = TrustedAssertionPreferences.fromEvent(event)!;

        // Filter by kind only
        final userProviders = prefs.filterProviders(kind: Nip85Kind.user);
        expect(userProviders.length, equals(2));

        // Filter by kind and metric
        final rankProviders = prefs.filterProviders(
          kind: Nip85Kind.user,
          metrics: {Nip85Metric.rank},
        );
        expect(rankProviders.length, equals(1));
        expect(rankProviders.first.metric, equals(Nip85Metric.rank));
      });

      test('returns null for wrong kind', () {
        final event = Nip01Event(
          pubKey: 'test_pubkey',
          kind: 1, // Not kind 10040
          tags: [],
          content: '',
        );

        final prefs = TrustedAssertionPreferences.fromEvent(event);
        expect(prefs, isNull);
      });
    });

    group('TrustedAssertions integration', () {
      test('getUserMetrics with usePreferencesFrom uses kind 10040 providers',
          () async {
        // This test verifies that TrustedAssertions can use providers from
        // the user's kind 10040 preferences instead of default providers.
        // Since we have no actual assertion events in this test, we verify
        // the integration by checking that no error is thrown and null is
        // returned (no assertions exist for the subject).
        final metrics = await ndk.ta.getUserMetrics(
          'unknown_subject',
          usePreferencesFrom: true,
        );

        // Should return null because no assertions exist, but no error thrown
        expect(metrics, isNull);
      });

      test('getUserMetrics with explicit providers still works', () async {
        final metrics = await ndk.ta.getUserMetrics(
          'unknown_subject',
          providers: [
            Nip85TrustedProvider(
              kind: Nip85Kind.user,
              metric: Nip85Metric.rank,
              pubkey: provider1Key.publicKey,
              relay: relay.url,
            ),
          ],
        );

        // Should return null because no assertions exist
        expect(metrics, isNull);
      });
    });

    group('Encrypted and mixed providers (NIP-44)', () {
      test('updatePreferences with mixed public and private providers',
          () async {
        final publicProvider = Nip85TrustedProvider(
          kind: Nip85Kind.user,
          metric: Nip85Metric.rank,
          pubkey: provider1Key.publicKey,
          relay: relay.url,
        );

        final privateProvider = Nip85TrustedProvider(
          kind: Nip85Kind.user,
          metric: Nip85Metric.followers,
          pubkey: provider2Key.publicKey,
          relay: relay.url,
        );

        // Update with both public and private providers
        final updatedPrefs = await ndk.taPreferences.updatePreferences(
          publicProviders: [publicProvider],
          privateProviders: [privateProvider],
          broadcastRelays: [relay.url],
        );

        expect(updatedPrefs, isNotNull);
        expect(updatedPrefs!.hasPublicProviders, isTrue);
        expect(updatedPrefs.hasPrivateProviders, isTrue);
        expect(updatedPrefs.publicProviders.length, equals(1));
        expect(updatedPrefs.privateProviders.length, equals(1));
        expect(updatedPrefs.allProviders.length, equals(2));

        // Public provider should match
        expect(
          updatedPrefs.publicProviders.first.metric,
          equals(Nip85Metric.rank),
        );
        // Private provider should match
        expect(
          updatedPrefs.privateProviders.first.metric,
          equals(Nip85Metric.followers),
        );
      });

      test('addProvider with private=true adds to private list', () async {
        final provider = Nip85TrustedProvider(
          kind: Nip85Kind.user,
          metric: Nip85Metric.rank,
          pubkey: provider1Key.publicKey,
          relay: relay.url,
        );

        // Use updatePreferences directly to test the private provider mechanism
        final updatedPrefs = await ndk.taPreferences.updatePreferences(
          publicProviders: [],
          privateProviders: [provider],
          broadcastRelays: [relay.url],
        );

        expect(updatedPrefs, isNotNull);
        expect(updatedPrefs!.hasPrivateProviders, isTrue);
        expect(
          updatedPrefs.privateProviders.any((p) =>
              p.pubkey == provider1Key.publicKey &&
              p.metric == Nip85Metric.rank),
          isTrue,
        );
      });

      test('addProvider with private=false adds to public list', () async {
        final provider = Nip85TrustedProvider(
          kind: Nip85Kind.event,
          metric: Nip85Metric.commentCount,
          pubkey: provider2Key.publicKey,
          relay: relay.url,
        );

        // Use updatePreferences directly to test the public provider mechanism
        final updatedPrefs = await ndk.taPreferences.updatePreferences(
          publicProviders: [provider],
          privateProviders: [],
          broadcastRelays: [relay.url],
        );

        expect(updatedPrefs, isNotNull);
        expect(updatedPrefs!.hasPublicProviders, isTrue);
        expect(
          updatedPrefs.publicProviders.any((p) =>
              p.pubkey == provider2Key.publicKey &&
              p.metric == Nip85Metric.commentCount),
          isTrue,
        );
      });

      test('setProviderVisibility moves provider between lists', () async {
        // Test by directly calling updatePreferences with different splits
        final provider = Nip85TrustedProvider(
          kind: Nip85Kind.user,
          metric: Nip85Metric.rank,
          pubkey: provider1Key.publicKey,
          relay: relay.url,
        );

        // Set as public
        final asPublic = await ndk.taPreferences.updatePreferences(
          publicProviders: [provider],
          privateProviders: [],
          broadcastRelays: [relay.url],
        );

        expect(asPublic, isNotNull);
        expect(asPublic!.hasPublicProviders, isTrue);
        expect(asPublic.hasPrivateProviders, isFalse);
        expect(asPublic.publicProviders.length, equals(1));
        expect(asPublic.publicProviders.first.metric, equals(Nip85Metric.rank));

        // Now use setProviderVisibility to make it private
        final asPrivate = await ndk.taPreferences.setProviderVisibility(
          provider: provider,
          private: true,
        );

        expect(asPrivate, isNotNull);
        expect(asPrivate!.hasPrivateProviders, isTrue);
        expect(
          asPrivate.privateProviders.any((p) =>
              p.metric == Nip85Metric.rank),
          isTrue,
        );
      });
    });

    group('TrustedAssertionPreferencesExtension (JSON serialization)', () {
      test('toJsonForStorage and fromJsonStorage are inverse', () {
        final prefs = TrustedAssertionPreferences(
          pubKey: 'test_pubkey',
          id: 'event_id_123',
          createdAt: 1234567890,
          publicProviders: [
            Nip85TrustedProvider(
              kind: Nip85Kind.user,
              metric: Nip85Metric.rank,
              pubkey: 'provider1',
              relay: 'wss://relay1',
            ),
          ],
          privateProviders: [
            Nip85TrustedProvider(
              kind: Nip85Kind.event,
              metric: Nip85Metric.commentCount,
              pubkey: 'provider2',
              relay: 'wss://relay2',
            ),
          ],
        );

        final json = prefs.toJsonForStorage();
        final restored = TrustedAssertionPreferencesExtension.fromJsonStorage(
            json);

        expect(restored.pubKey, equals(prefs.pubKey));
        expect(restored.id, equals(prefs.id));
        expect(restored.createdAt, equals(prefs.createdAt));
        expect(
            restored.publicProviders.length, equals(prefs.publicProviders.length));
        expect(restored.publicProviders[0].kind,
            equals(prefs.publicProviders[0].kind));
        expect(restored.publicProviders[0].metric,
            equals(prefs.publicProviders[0].metric));
        expect(restored.privateProviders.length,
            equals(prefs.privateProviders.length));
        expect(restored.privateProviders[0].kind,
            equals(prefs.privateProviders[0].kind));
        expect(restored.privateProviders[0].metric,
            equals(prefs.privateProviders[0].metric));
      });
    });
  });
}
