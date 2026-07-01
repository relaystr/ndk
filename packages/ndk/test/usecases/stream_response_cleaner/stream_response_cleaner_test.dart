import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/domain_layer/usecases/stream_response_cleaner/stream_response_cleaner.dart';
import 'package:ndk/ndk.dart';

void main() async {
  const int fixedCreatedAt = 1782139515;

  final List<Nip01Event> myEvents = [
    Nip01Event(
      pubKey: "pubKey1",
      kind: 1,
      tags: [],
      content: "content1_a",
      createdAt: fixedCreatedAt,
    ),
    Nip01Event(
        pubKey: "pubKey1",
        kind: 1,
        tags: [],
        content: "content1_b",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "duplicate",
        kind: 1,
        tags: [],
        content: "duplicate",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey1",
        kind: 1,
        tags: [],
        content: "content1_c",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey2",
        kind: 1,
        tags: [],
        content: "content2_a",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "duplicate",
        kind: 1,
        tags: [],
        content: "duplicate",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey2",
        kind: 1,
        tags: [],
        content: "content2_b",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey2",
        kind: 1,
        tags: [],
        content: "content2_c",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "duplicate",
        kind: 1,
        tags: [],
        content: "duplicate",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "duplicate",
        kind: 1,
        tags: [],
        content: "duplicate",
        createdAt: fixedCreatedAt),
  ];

  final List<Nip01Event> myEventsNoDublicate = [
    Nip01Event(
        pubKey: "pubKey1",
        kind: 1,
        tags: [],
        content: "content1_a",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey1",
        kind: 1,
        tags: [],
        content: "content1_b",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey1",
        kind: 1,
        tags: [],
        content: "content1_c",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey2",
        kind: 1,
        tags: [],
        content: "content2_a",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey2",
        kind: 1,
        tags: [],
        content: "content2_b",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "pubKey2",
        kind: 1,
        tags: [],
        content: "content2_c",
        createdAt: fixedCreatedAt),
    Nip01Event(
        pubKey: "duplicate",
        kind: 1,
        tags: [],
        content: "duplicate",
        createdAt: fixedCreatedAt),
  ];

  group('stream response cleaner', () {
    test('no duplicates ', () async {
      final Set<String> tracking = {};

      StreamController<Nip01Event> inputController =
          StreamController<Nip01Event>();
      StreamController<Nip01Event> outController =
          StreamController<Nip01Event>.broadcast();

      // bind
      StreamResponseCleaner(
        inputStreams: [inputController.stream],
        trackingSet: tracking,
        outController: outController,
        eventOutFilters: [],
      )();

      expectLater(outController.stream, emitsInAnyOrder(myEventsNoDublicate));

      // write msg

      for (final event in myEvents) {
        inputController.add(event);
      }

      await inputController.close();
      await outController.close();
    });
  });
}
