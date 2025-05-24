import 'dart:math';

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../tools/simple_profiler.dart';

void main() async {
  group(
    "multiple filters (external REAL)",
    skip: true,
    () {
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
    },
  );
}
