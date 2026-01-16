import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/usecases/cache_read/cache_read.dart';
import 'package:ndk/ndk.dart';

void main() async {
  group('CacheRead', () {
    final CacheManager myCacheManager = MemCacheManager();

    final List<Nip01Event> myEvens = [
      Nip01Event(
          pubKey: "pubKey1", kind: 1, tags: [], content: "content1_a"),
      Nip01Event(
          pubKey: "pubKey1", kind: 1, tags: [], content: "content1_b"),
      Nip01Event(
          pubKey: "pubKey1", kind: 1, tags: [], content: "content1_c"),
      Nip01Event(
          pubKey: "pubKey2", kind: 1, tags: [], content: "content2_a"),
      Nip01Event(
          pubKey: "pubKey2", kind: 1, tags: [], content: "content2_b"),
      Nip01Event(
          pubKey: "pubKey2", kind: 1, tags: [], content: "content2_c"),
    ];

    setUp(() async {
      await myCacheManager.saveEvents(myEvens);
    });

    test('cache read - all - BAD TEST', skip: true, () async {
      final NdkRequest myNdkRequest = NdkRequest.query(
        "id",
        filters: [
          Filter(
            authors: ['pubKey1', 'pubKey2'],
            kinds: [1],
          )
        ],
        timeoutDuration: Duration(seconds: 5),
      );
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

    test('cache read - some missing - BAD TEST', skip: true, () async {
      final NdkRequest myNdkRequest = NdkRequest.query("id",
          filters: [
            Filter(
              authors: ['pubKey1', 'pubKey2', 'notInCachePubKey'],
              kinds: [1],
            )
          ],
          timeoutDuration: Duration(seconds: 5));
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
        expect(data, unorderedEquals(myEvens));
      });

      //await expectLater(myRequestState.stream, emitsInAnyOrder(myEvens));

      for (final filter in myRequestState.unresolvedFilters) {
        expect(filter.authors, equals(['notInCachePubKey']));
      }
    });

    test('cache read - author removal based on limit - remove - BAD TEST',
        skip: true, () async {
      final CacheRead myUsecase = CacheRead(myCacheManager);

      // Test with limit
      final NdkRequest myNdkRequestWithLimit = NdkRequest.query("author-remove",
          filters: [
            Filter(
              authors: ['pubKey1', 'pubKey2'],
              kinds: [1],
              limit: 2,
            )
          ],
          timeoutDuration: Duration(seconds: 5));
      final RequestState myRequestStateWithLimit =
          RequestState(myNdkRequestWithLimit);

      await myUsecase.resolveUnresolvedFilters(
        requestState: myRequestStateWithLimit,
        outController: myRequestStateWithLimit.controller,
      );

      expect(myRequestStateWithLimit.unresolvedFilters[0].authors, equals([]));
    });

    test('cache read - not all in cache - BAD TEST', skip: true, () async {
      final CacheRead myUsecase = CacheRead(myCacheManager);

      // Test with limit
      final NdkRequest myNdkRequestWithLimit = NdkRequest.query(
        "author-not-covered",
        filters: [
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
        ],
        timeoutDuration: Duration(seconds: 5),
      );
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

    test('cache read - id filter with one missing', () async {
      final CacheManager myCacheManager = MemCacheManager();
      final CacheRead myUsecase = CacheRead(myCacheManager);

      final eventId0 = Nip01Event(
          pubKey: "pubKey0",
          kind: 1,
          tags: [],
          content: "content0",
          id: "id0",
          sig: null,
          validSig: null);

      final eventId1 = Nip01Event(
          pubKey: "pubKey1",
          kind: 1,
          tags: [],
          content: "content1",
          id: "id1",
          sig: null,
          validSig: null);

      final eventId2 = Nip01Event(
          pubKey: "pubKey2",
          kind: 1,
          tags: [],
          content: "content2",
          id: "id2",
          sig: null,
          validSig: null);

      final List<Nip01Event> idEvents = [
        eventId0,
        eventId1,
        eventId2,
      ];

      await myCacheManager.saveEvents(idEvents);

      final NdkRequest myNdkRequest = NdkRequest.query(
        "id-filter",
        filters: [
          Filter(
            ids: ['id0', 'id1', 'id2', 'id3'],
            kinds: [1],
          )
        ],
        timeoutDuration: Duration(seconds: 5),
      );
      final RequestState myRequestState = RequestState(myNdkRequest);

      final streamController = StreamController<Nip01Event>();
      final response = streamController.stream.toList();

      await myUsecase.resolveUnresolvedFilters(
        requestState: myRequestState,
        outController: streamController,
      );

      await streamController.close();

      final foundEvents = await response;
      expect(foundEvents.length, equals(3));
      expect(
          foundEvents.map((e) => e.id).toSet(), equals({'id0', 'id1', 'id2'}));

      expect(myRequestState.unresolvedFilters[0].ids, equals(['id3']));
    });

    test('cache read - id filter all in cache', () async {
      final CacheManager myCacheManager = MemCacheManager();
      final CacheRead myUsecase = CacheRead(myCacheManager);

      final eventId0 = Nip01Event(
          pubKey: "pubKey0",
          kind: 1,
          tags: [],
          content: "content0",
          id: "id0",
          sig: null,
          validSig: null);

      final eventId1 = Nip01Event(
          pubKey: "pubKey1",
          kind: 1,
          tags: [],
          content: "content1",
          id: "id1",
          sig: null,
          validSig: null);

      final eventId2 = Nip01Event(
          pubKey: "pubKey2",
          kind: 1,
          tags: [],
          content: "content2",
          id: "id2",
          sig: null,
          validSig: null);

      final List<Nip01Event> idEvents = [
        eventId0,
        eventId1,
        eventId2,
      ];

      await myCacheManager.saveEvents(idEvents);

      final NdkRequest myNdkRequest = NdkRequest.query(
        "id-filter",
        filters: [
          Filter(
            ids: ['id0', 'id1', 'id2'],
            kinds: [1],
          )
        ],
        timeoutDuration: Duration(seconds: 5),
      );
      final RequestState myRequestState = RequestState(myNdkRequest);

      final streamController = StreamController<Nip01Event>();
      final response = streamController.stream.toList();

      await myUsecase.resolveUnresolvedFilters(
        requestState: myRequestState,
        outController: streamController,
      );

      await streamController.close();

      final foundEvents = await response;
      expect(foundEvents.length, equals(3));
      expect(
          foundEvents.map((e) => e.id).toSet(), equals({'id0', 'id1', 'id2'}));

      expect(myRequestState.unresolvedFilters, equals([]));
    });

    test('cache read - has events for all authors', () async {
      // ...but we cannot remove them from the filter because only replaceable events have 1 event per pubKey+kind, normal events can have many per pubKey+kind
      final filter = Filter(
        authors: ['pubKey1', 'pubKey2'],
        kinds: [1],
      );
      final NdkRequest myNdkRequest = NdkRequest.query("id",
          filters: [filter], timeoutDuration: Duration(seconds: 5));
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

      /// expect in any order

      expect(myRequestState.unresolvedFilters, unorderedEquals([filter]));
    });
  });
}
