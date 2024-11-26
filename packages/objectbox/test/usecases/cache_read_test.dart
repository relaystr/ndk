import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/usecases/cache_read/cache_read.dart';
import 'package:ndk/ndk.dart';

void main() async {
  group('CacheRead', () {
    final CacheManager myCacheManager = MemCacheManager();

    final List<Nip01Event> myEvens = [
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_a"),
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_b"),
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_c"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_a"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_b"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_c"),
    ];

    setUp(() async {
      await myCacheManager.saveEvents(myEvens);
    });

    test('cache read - all', () async {
      final NdkRequest myNdkRequest = NdkRequest.query("id", filters: [
        Filter(
          authors: ['pubKey1', 'pubKey2'],
          kinds: [1],
        )
      ]);
      final RequestState myRequestState = RequestState(myNdkRequest);
      final CacheRead myUsecase = CacheRead(myCacheManager);

      closeStream() async {
        // wait to add events
        await Future.delayed(const Duration(seconds: 1));
        await myRequestState.controller.close();
      }

      closeStream();
      final response = myRequestState.stream.toList();

      await myUsecase.resolveUnresolvedFilters(
        requestState: myRequestState,
        outController: myRequestState.controller,
      );

      await response.then((data) {
        expect(data, equals(myEvens));
      });

      //await expectLater(myRequestState.stream, emitsInAnyOrder(myEvens));

      for (final filter in myRequestState.unresolvedFilters) {
        expect(filter.authors, equals([]));
      }
    });

    test('cache read - some missing', () async {
      final NdkRequest myNdkRequest = NdkRequest.query("id", filters: [
        Filter(
          authors: ['pubKey1', 'pubKey2', 'notInCachePubKey'],
          kinds: [1],
        )
      ]);
      final RequestState myRequestState = RequestState(myNdkRequest);
      final CacheRead myUsecase = CacheRead(myCacheManager);

      closeStream() async {
        // wait to add events
        await Future.delayed(const Duration(seconds: 1));
        await myRequestState.controller.close();
      }

      closeStream();
      final response = myRequestState.stream.toList();

      await myUsecase.resolveUnresolvedFilters(
        requestState: myRequestState,
        outController: myRequestState.controller,
      );

      await response.then((data) {
        expect(data, equals(myEvens));
      });

      //await expectLater(myRequestState.stream, emitsInAnyOrder(myEvens));

      for (final filter in myRequestState.unresolvedFilters) {
        expect(filter.authors, equals(['notInCachePubKey']));
      }
    });

    test('cache read - author removal based on limit - remove', () async {
      final CacheRead myUsecase = CacheRead(myCacheManager);

      // Test with limit
      final NdkRequest myNdkRequestWithLimit =
          NdkRequest.query("author-remove", filters: [
        Filter(
          authors: ['pubKey1', 'pubKey2'],
          kinds: [1],
          limit: 2,
        )
      ]);
      final RequestState myRequestStateWithLimit =
          RequestState(myNdkRequestWithLimit);

      await myUsecase.resolveUnresolvedFilters(
        requestState: myRequestStateWithLimit,
        outController: myRequestStateWithLimit.controller,
      );

      expect(myRequestStateWithLimit.unresolvedFilters[0].authors, equals([]));
    });

    test('cache read - not all in cache', () async {
      final CacheRead myUsecase = CacheRead(myCacheManager);

      // Test with limit
      final NdkRequest myNdkRequestWithLimit =
          NdkRequest.query("author-not-covered", filters: [
        Filter(
          authors: [
            'pubKey1',
            'pubKey2',
            'notInCachePubKey1',
            'notInCachePubKey2'
          ],
          kinds: [1],
          limit: 200, // some high limit
        )
      ]);
      final RequestState myRequestStateWithLimit =
          RequestState(myNdkRequestWithLimit);

      await myUsecase.resolveUnresolvedFilters(
        requestState: myRequestStateWithLimit,
        outController: myRequestStateWithLimit.controller,
      );

      expect(
          myRequestStateWithLimit.unresolvedFilters[0].authors,
          equals([
            'pubKey1',
            'pubKey2',
            'notInCachePubKey1',
            'notInCachePubKey2'
          ]));
    });
  });
}
