import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/domain_layer/usecases/cache_write/cache_write.dart';
import 'package:ndk/ndk.dart';

void main() async {
  group('CacheWrite', () {
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

      final StreamController<Nip01Event> inputController =
          StreamController<Nip01Event>.broadcast();

      myUsecase.saveNetworkResponse(
        writeToCache: true,
        inputStream: inputController.stream,
      );

      for (final event in myEvens) {
        inputController.add(event);
      }
      await inputController.close();

      //check if events got saved
      for (final event in expectedEvents) {
        final loadedEvent = myCacheManager.loadEvent(event.id);
        expect(loadedEvent, isNotNull);
      }

      final duplicatedEvents =
          await myCacheManager.loadEvents(kinds: [1], pubKeys: ['duplicate']);

      expect(duplicatedEvents.length, equals(1));
    });

    test('check if skip flags works', () async {
      final CacheManager myCacheManager = MemCacheManager();
      final CacheWrite myUsecase = CacheWrite(myCacheManager);

      final StreamController<Nip01Event> inputController =
          StreamController<Nip01Event>();

      myUsecase.saveNetworkResponse(
        writeToCache: false,
        inputStream: inputController.stream,
      );

      for (final event in myEvens) {
        inputController.add(event);
      }

      //check if events got not saved
      for (final event in expectedEvents) {
        final loadedEvent = await myCacheManager.loadEvent(event.id);
        expect(loadedEvent, isNull);
      }
    });
  });
}
