import 'package:drift_cache_manager/drift_cache_manager.dart';
import 'package:ndk/ndk.dart';

/// Example demonstrating how to use DriftCacheManager with NDK.
///
/// Note: This example requires a Flutter environment to run.
/// For a complete working example, see the sample-app in the NDK repository.
Future<void> main() async {
  // 1. Create the cache manager
  // Uses 'ndk_cache_debug' in debug mode, 'ndk_cache' in release mode
  final cacheManager = await DriftCacheManager.create();

  // Or with a custom database name:
  // final cacheManager = await DriftCacheManager.create(dbName: 'my_app_cache');

  // 2. Configure NDK with the cache manager
  final ndk = Ndk(
    NdkConfig(cache: cacheManager, eventVerifier: Bip340EventVerifier()),
  );

  // 3. Use NDK - data will be automatically cached
  // Example: Load metadata (will be cached automatically)
  final metadata = await ndk.metadata.loadMetadata(
    '32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245',
  );
  print('Loaded metadata: ${metadata?.name}');

  // 4. Direct cache operations (if needed)

  // Save an event
  final event = Nip01Event(
    pubKey: '32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245',
    kind: 1,
    tags: [
      ['t', 'nostr'],
    ],
    content: 'Hello from DriftCacheManager!',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
  await cacheManager.saveEvent(event);

  // Load events with filters
  final events = await cacheManager.loadEvents(kinds: [1], limit: 10);
  print('Found ${events.length} events');

  // Search metadata
  final results = await cacheManager.searchMetadatas('alice', 10);
  print('Found ${results.length} metadata entries');

  // 5. Clean up
  await cacheManager.close();
}
