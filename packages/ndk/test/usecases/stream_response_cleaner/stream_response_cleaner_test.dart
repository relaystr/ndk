import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/domain_layer/usecases/stream_response_cleaner/stream_response_cleaner.dart';
import 'package:ndk/ndk.dart';

void main() async {
  final List<Nip01Event> myEvents = [
    Nip01Event(
      pubKey: "pubKey1",
      kind: 1,
      tags: [],
      content: "content1_a",
    ),
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

  final List<Nip01Event> myEventsNoDublicate = [
    Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_a"),
    Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_b"),
    Nip01Event(pubKey: "pubKey1", kind: 1, tags: [], content: "content1_c"),
    Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_a"),
    Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_b"),
    Nip01Event(pubKey: "pubKey2", kind: 1, tags: [], content: "content2_c"),
    Nip01Event(pubKey: "duplicate", kind: 1, tags: [], content: "duplicate"),
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
        timeout: 5,
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

    test('timeout closes the stream', () async {
      final Set<String> tracking = {};

      StreamController<Nip01Event> inputController =
          StreamController<Nip01Event>();
      StreamController<Nip01Event> outController =
          StreamController<Nip01Event>.broadcast();

      final timeout = 2; // 2 seconds timeout

      StreamResponseCleaner(
        inputStreams: [inputController.stream],
        trackingSet: tracking,
        outController: outController,
        timeout: timeout,
        eventOutFilters: [],
      )();

      // Add one event to the stream
      inputController.add(Nip01Event(
        pubKey: 'pubKey1',
        kind: 1,
        tags: [],
        content: 'content1',
      ));

      // Wait for slightly longer than the timeout
      await Future.delayed(Duration(seconds: timeout + 1));

      // Check if the outController is closed
      expect(outController.isClosed, isTrue);

      // Clean up
      await inputController.close();
    });
  });
}
