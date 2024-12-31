import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../tools/simple_profiler.dart';

void main() async {
  group(
    "list + metadata (external REAL)",
    skip: true,
    () {
      test('camelus - starter packs', () async {
        // ignore: non_constant_identifier_names
        final List<String> CAMELUS_RECOMMEDED_STARTER_PACKS = [
          'c7779fdc1e5d2bbf5edd5f68785bfc4299b3c77d8046957cc79bc4d25ad9d330', // camelus.app
          '0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6', // nos.social
        ];

        CacheManager cacheManager = MemCacheManager();

        final profiler = SimpleProfiler('list + metadata (external REAL)');

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: MockEventVerifier(),
            cache: cacheManager,
            engine: NdkEngine.JIT,
          ),
        );
        final recommededSets =
            await Future.wait(CAMELUS_RECOMMEDED_STARTER_PACKS.map((rPubkey) {
          return ndk.lists.getPublicNip51RelaySets(
            kind: 30000,
            publicKey: rPubkey,
            forceRefresh: false,
          );
        }));

        profiler.checkpoint('got ${recommededSets.length} sets');

        final allPubkeys = recommededSets
            .expand((set) => set!)
            .expand((e) => e.elements)
            .map((e) => e.value)
            .toSet()
            .toList();

        profiler.checkpoint('got ${allPubkeys.length} pubkeys');

        //? sync
        // for (final pubkey in allPubkeys) {
        //   final metadataR = await ndk.metadata.loadMetadata(pubkey);
        //   profiler.checkpoint('got metadata for $pubkey, ${metadataR?.name}');
        // }

        final metadataFutures = allPubkeys
            .map((pubkey) => ndk.metadata.loadMetadata(pubkey).then((metadata) {
                  profiler.checkpoint(
                      'got metadata for $pubkey, ${metadata?.name}');
                  return {'pubkey': pubkey, 'metadata': metadata};
                }));

        final allMetadata = await Future.wait(metadataFutures);
        profiler
            .checkpoint('got metadata for all ${allMetadata.length} pubkeys');
      }, timeout: const Timeout.factor(60));
    },
  );
}
