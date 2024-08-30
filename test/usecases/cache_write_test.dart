import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/domain_layer/usecases/cache_write/cache_write.dart';
import 'package:ndk/ndk.dart';

void main() async {
  group('CacheRead', () {
    final CacheManager myCacheManager = MemCacheManager();

    final List<Nip01Event> myEvens = [
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_a"),
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_b"),
      Nip01Event(pubKey: "duplicate", kind: 1, tags: [], content: "duplicate"),
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_c"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_a"),
      Nip01Event(pubKey: "duplicate", kind: 1, tags: [], content: "duplicate"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_b"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_c"),
      Nip01Event(pubKey: "duplicate", kind: 1, tags: [], content: "duplicate"),
      Nip01Event(pubKey: "duplicate", kind: 1, tags: [], content: "duplicate"),
    ];

    final List<Nip01Event> expectedEvents = [
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_a"),
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_b"),
      Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_c"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_a"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_b"),
      Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_c"),
      Nip01Event(pubKey: "duplicate", kind: 1, tags: [], content: "duplicate"),
    ];

    setUp(() async {});

    test('cache write', () async {
      final CacheWrite myUsecase = CacheWrite(myCacheManager);

      final StreamController<Nip01Event> responseController =
          StreamController<Nip01Event>.broadcast();
      final StreamController<Nip01Event> writeController =
          StreamController<Nip01Event>();

      closeStream() async {
        await Future.delayed(const Duration(seconds: 1));
        await responseController.close();
      }

      myUsecase.saveNetworkResponse(
        writeToCache: true,
        networkController: writeController,
        responseController: responseController,
      );

      for (final event in myEvens) {
        writeController.add(event);
      }

      closeStream();
      await responseController.stream.toList().then((data) {
        // check if every event of expectedEvents is in data
        for (final expectedEvent in expectedEvents) {
          expect(data.contains(expectedEvent), true);
        }
        // check if data has no more events than expectedEvents
        expect(data.length, equals(expectedEvents.length));
      });

      //check if events got saved
      for (final event in expectedEvents) {
        final loadedEvent = myCacheManager.loadEvent(event.id);
        expect(loadedEvent, isNotNull);
      }

      final duplicatedEvents =
          myCacheManager.loadEvents(kinds: [1], pubKeys: ['duplicate']);

      expect(duplicatedEvents.length, equals(1));
    });

    test('check if skip flags works', () async {
      final CacheManager myCacheManager = MemCacheManager();
      final CacheWrite myUsecase = CacheWrite(myCacheManager);

      final StreamController<Nip01Event> responseController =
          StreamController<Nip01Event>.broadcast();
      final StreamController<Nip01Event> writeController =
          StreamController<Nip01Event>();

      closeStream() async {
        await Future.delayed(const Duration(seconds: 1));
        await responseController.close();
      }

      myUsecase.saveNetworkResponse(
        writeToCache: false,
        networkController: writeController,
        responseController: responseController,
      );

      for (final event in myEvens) {
        writeController.add(event);
      }

      closeStream();
      await responseController.stream.toList().then((data) {
        // check if every event of expectedEvents is in data
        for (final expectedEvent in expectedEvents) {
          expect(data.contains(expectedEvent), true);
        }
        // check if data has no more events than expectedEvents
        //? here the events just get passed on, even if they are duplicates!
        expect(data.length, equals(myEvens.length));
      });

      //check if events got not saved
      for (final event in expectedEvents) {
        final loadedEvent = myCacheManager.loadEvent(event.id);
        expect(loadedEvent, isNull);
      }
    });
  });
}
