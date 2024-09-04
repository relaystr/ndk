import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/domain_layer/usecases/stream_response_cleaner/stream_response_cleaner.dart';
import 'package:ndk/ndk.dart';

void main() async {
  final List<Nip01Event> myEvents = [
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

  group('stream response cleaner', () {
    test('no duplicates ', () async {
      // local test skips?
      expect(true, equals(false));

      final Set<String> tracking = {};

      StreamController<Nip01Event> inputController =
          StreamController<Nip01Event>();
      StreamController<Nip01Event> outController =
          StreamController<Nip01Event>.broadcast();

      // bind
      StreamResponseCleaner()(
        inputStream: inputController.stream,
        trackingSet: tracking,
        outController: outController,
      );

      // write msg

      for (final event in myEvents) {
        inputController.add(event);
      }

      await inputController.close();
      await outController.close();

      // check if events are there
      expectLater(outController.stream, emitsInAnyOrder(myEvents));

      final count = (await outController.stream.toList()).length;

      expect(count, equals(7));
    });

    test('---', () async {});
  });
}