import 'dart:math';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';
import '../tools/simple_profiler.dart';

void main() async {
  group(
    "multiple filters (external REAL)",
    skip: true,
    () {
      late MockRelay relay0;
      late MockRelay relay1;
      late Ndk ndk;
      setUp(() async {
        relay0 = MockRelay(name: "relay 0", explicitPort: 5297);
        relay1 = MockRelay(name: "relay 1", explicitPort: 5298);

        await relay0.startServer();
        await relay1.startServer();

        final cache = MemCacheManager();
        final NdkConfig config = NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: cache,
          bootstrapRelays: [relay0.url, relay1.url],
          // logLevel: Logger.logLevels.trace,
          ignoreRelays: [],
        );

        ndk = Ndk(config);

        await ndk.relays.seedRelaysConnected;
      });

      tearDown(() async {
        await ndk.destroy();
        await relay0.stopServer();
        await relay1.stopServer();
      });

      test('multiple filters JIT query', () async {
        // ignore: non_constant_identifier_names

        CacheManager cacheManager = MemCacheManager();

        final profiler = SimpleProfiler('multiple filters JIT query');

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: MockEventVerifier(),
            cache: cacheManager,
            engine: NdkEngine.JIT,
          ),
        );

        final queryResponse = ndk.requests.query(filters: [
          Filter(
            ids: [
              "ad6137b9a3dc4b393a41d745c483837cfd2379e22ec9916c487d6bd6cfe4b3b7"
            ],
            kinds: [9041],
          ),
          Filter(
            kinds: [1311, 9735],
            limit: 200,
            aTags: [
              "30311:cf45a6ba1363ad7ed213a078e710d24115ae721c9b47bd1ebf4458eaefb4c2a5:ec9731a5-b1a0-4296-baf4-0f8355687581"
            ],
          ),
          Filter(
            authors: [
              "63fe6318dc58583cfe16810f86dd09e18bfd76aabc24a0081ce2856f330504ed",
              "46f5797187ff5cf4dddb33828fb4e1296a7fd0ce666a3f24cdd454329e201480"
            ],
            kinds: [10000],
          )
        ]);
        profiler.checkpoint('query req send ');

        queryResponse.stream.listen((event) {
          profiler.checkpoint('got event ${event.id} of kind ${event.kind}');
        }, onDone: () {
          profiler.checkpoint('query done');
          profiler.end();
        });
        await queryResponse.future;
      }, timeout: const Timeout.factor(60));

      test('multiple filters JIT sub', () async {
        Nip01Event textNote(KeyPair mykey, int kind) {
          return Nip01Event(
              kind: kind,
              pubKey: mykey.publicKey,
              content: "some note from key $mykey",
              tags: [],
              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
        }

        KeyPair key1 = Bip340.generatePrivateKey();
        KeyPair key2 = Bip340.generatePrivateKey();

        Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1, 1)};
        Map<KeyPair, Nip01Event> key2TextNotes = {key2: textNote(key2, 1)};

        CacheManager cacheManager = MemCacheManager();

        relay0.textNotes = key1TextNotes;

        final profiler = SimpleProfiler('multiple filters JIT sub');

        final ndk = Ndk(
          NdkConfig(
            eventVerifier: MockEventVerifier(),
            cache: cacheManager,
            engine: NdkEngine.JIT,
            bootstrapRelays: [relay0.url, relay1.url],
          ),
        );

        final queryResponse = ndk.requests.subscription(filters: [
          Filter(
            ids: [
              "ad6137b9a3dc4b393a41d745c483837cfd2379e22ec9916c487d6bd6cfe4b3b7",
              textNote(key1, 1).id,
            ],
            kinds: [9041],
          ),
          Filter(
            kinds: [1311, 9735],
            limit: 200,
            aTags: [
              "30311:cf45a6ba1363ad7ed213a078e710d24115ae721c9b47bd1ebf4458eaefb4c2a5:ec9731a5-b1a0-4296-baf4-0f8355687581"
            ],
          ),
          Filter(
            authors: [
              "63fe6318dc58583cfe16810f86dd09e18bfd76aabc24a0081ce2856f330504ed",
              "46f5797187ff5cf4dddb33828fb4e1296a7fd0ce666a3f24cdd454329e201480"
            ],
            kinds: [10000],
          ),
          Filter(kinds: [1]),
        ]);

        profiler.checkpoint('query sub send ');

        queryResponse.stream.listen((event) {
          profiler.checkpoint('got event ${event.id} of kind ${event.kind}');
        }, onDone: () {
          profiler.checkpoint('query done');
          profiler.end();
        });

        // insert new events

        // todo modify mock relay to allow adding text notes (or trigger sub event)
        relay0.textNotes!.addAll(key2TextNotes);

        await queryResponse.future;
      });
    },
  );
}
