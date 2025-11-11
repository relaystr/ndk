import 'dart:async';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/repositories/event_verifier.dart';
import 'package:ndk/domain_layer/usecases/requests/verify_event_stream.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';

void main() {
  group('VerifyEventStream', () {
    late MockEventVerifier mockVerifier;

    setUp(() {
      mockVerifier = MockEventVerifier(result: true);
    });

    Nip01Event createMockEvent(String id) {
      final event = Nip01Event(
        pubKey: 'pubkey$id',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 1,
        tags: [],
        content: 'content$id',
      );
      return event;
    }

    test('should verify and yield valid events', () async {
      final events = [
        createMockEvent('1'),
        createMockEvent('2'),
        createMockEvent('3'),
      ];
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
      );

      final results = await verifyStream().toList();

      expect(results.length, equals(3));
      expect(results.every((e) => e.validSig == true), isTrue);
      expect(results[0].content, equals('content1'));
      expect(results[1].content, equals('content2'));
      expect(results[2].content, equals('content3'));
    });

    test('should verify and yield valid events with small buffer', () async {
      final events = [
        createMockEvent('1'),
        createMockEvent('2'),
        createMockEvent('3'),
        createMockEvent('4'),
        createMockEvent('5'),
        createMockEvent('6'),
      ];
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
        maxConcurrent: 2,
      );

      final results = await verifyStream().toList();

      expect(results.length, equals(6));
      expect(results.every((e) => e.validSig == true), isTrue);
      expect(results[0].content, equals('content1'));
      expect(results[1].content, equals('content2'));
      expect(results[2].content, equals('content3'));
      expect(results[3].content, equals('content4'));
      expect(results[4].content, equals('content5'));
      expect(results[5].content, equals('content6'));
    });

    test('should filter out invalid events', () async {
      mockVerifier = MockEventVerifier(result: false);
      final events = [
        createMockEvent('1'),
        createMockEvent('2'),
      ];
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
      );

      final results = await verifyStream().toList();

      expect(results.length, equals(0));
    });

    test('should handle empty stream', () async {
      final inputStream = Stream<Nip01Event>.fromIterable([]);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
      );

      final results = await verifyStream().toList();

      expect(results.length, equals(0));
    });

    test('should handle stream with small maxConcurrent', () async {
      final events = List.generate(5, (i) => createMockEvent('$i'));
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
        maxConcurrent: 3,
      );

      final results = await verifyStream().toList();

      expect(results.length, equals(5));
    });

    test('should return broadcast stream', () async {
      final events = [createMockEvent('1')];
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
      );

      final stream = verifyStream();

      expect(stream.isBroadcast, isTrue);
    });

    test('should allow multiple listeners on broadcast stream', () async {
      final events = [
        createMockEvent('1'),
        createMockEvent('2'),
      ];
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
      );

      final stream = verifyStream();

      final results1Future = stream.toList();
      final results2Future = stream.toList();

      final results1 = await results1Future;
      final results2 = await results2Future;

      expect(results1.length, equals(2));
      expect(results2.length, equals(2));
    });

    test('should process remaining buffer after stream ends', () async {
      final events = List.generate(5, (i) => createMockEvent('$i'));
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
        maxConcurrent: 10, // Higher than event count
      );

      final results = await verifyStream().toList();

      expect(results.length, equals(5));
      expect(results.every((e) => e.validSig == true), isTrue);
    });

    test('should set validSig property correctly', () async {
      final events = [createMockEvent('1')];
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
      );

      final results = await verifyStream().toList();

      expect(results.length, equals(1));
      expect(results[0].validSig, equals(true));
    });

    test('should handle large number of events', () async {
      final events = List.generate(100, (i) => createMockEvent('$i'));
      final inputStream = Stream.fromIterable(events);

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: inputStream,
        eventVerifier: mockVerifier,
        maxConcurrent: 50,
      );

      final results = await verifyStream().toList();

      expect(results.length, equals(100));
    });

    test('should process events immediately from non-closing stream', () async {
      final controller = StreamController<Nip01Event>();
      final resultList = <Nip01Event>[];

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: controller.stream,
        eventVerifier: mockVerifier,
        maxConcurrent: 5,
      );

      final subscription = verifyStream().listen((event) {
        resultList.add(event);
      });

      controller.add(createMockEvent('1'));

      await Future.delayed(Duration(milliseconds: 50));

      expect(resultList.length, equals(1), reason: 'First event should be processed immediately');
      expect(resultList[0].content, equals('content1'));

      controller.add(createMockEvent('2'));

      await Future.delayed(Duration(milliseconds: 50));

      expect(resultList.length, equals(2), reason: 'Second event should be processed immediately');
      expect(resultList[1].content, equals('content2'));

      await subscription.cancel();
      await controller.close();
    });

    test('should process events from non-closing stream with fewer events than maxConcurrent', () async {
      final controller = StreamController<Nip01Event>();
      final resultList = <Nip01Event>[];

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: controller.stream,
        eventVerifier: mockVerifier,
        maxConcurrent: 10,
      );

      final subscription = verifyStream().listen((event) {
        resultList.add(event);
      });

      controller.add(createMockEvent('1'));
      controller.add(createMockEvent('2'));
      controller.add(createMockEvent('3'));

      await Future.delayed(Duration(milliseconds: 100));

      expect(resultList.length, equals(3), reason: 'All events should be processed even when count < maxConcurrent');

      await subscription.cancel();
      await controller.close();
    });

    test('should process events as they complete, not in order', () async {
      final controller = StreamController<Nip01Event>();
      final resultList = <Nip01Event>[];

      final delayedVerifier = DelayedMockEventVerifier();

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: controller.stream,
        eventVerifier: delayedVerifier,
        maxConcurrent: 5,
      );

      final subscription = verifyStream().listen((event) {
        resultList.add(event);
      });

      controller.add(createMockEvent('slow'));
      controller.add(createMockEvent('fast'));

      await Future.delayed(Duration(milliseconds: 50));

      expect(resultList.length, equals(1), reason: 'Fast event should complete first');
      expect(resultList[0].content, equals('contentfast'), reason: 'Fast event should be yielded before slow event');

      await Future.delayed(Duration(milliseconds: 80));

      expect(resultList.length, equals(2));
      expect(resultList[1].content, equals('contentslow'));

      await subscription.cancel();
      await controller.close();
    });

    test('should handle continuous stream of events without blocking', () async {
      final controller = StreamController<Nip01Event>();
      final resultList = <Nip01Event>[];

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: controller.stream,
        eventVerifier: mockVerifier,
        maxConcurrent: 3,
      );

      final subscription = verifyStream().listen((event) {
        resultList.add(event);
      });

      for (int i = 0; i < 10; i++) {
        controller.add(createMockEvent('$i'));

        await Future.delayed(Duration(milliseconds: 10));

        if (i >= 2) {
          expect(resultList.length, greaterThan(0),
              reason: 'Events should be processed continuously, not waiting for stream end');
        }
      }

      await Future.delayed(Duration(milliseconds: 100));

      expect(resultList.length, equals(10), reason: 'All events should be processed from continuous stream');

      await subscription.cancel();
      await controller.close();
    });

    test('should not deadlock when maxConcurrent is reached with non-closing stream', () async {
      final controller = StreamController<Nip01Event>();
      final resultList = <Nip01Event>[];

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: controller.stream,
        eventVerifier: mockVerifier,
        maxConcurrent: 2,
      );

      final subscription = verifyStream().listen((event) {
        resultList.add(event);
      });

      controller.add(createMockEvent('1'));
      controller.add(createMockEvent('2'));
      controller.add(createMockEvent('3'));
      controller.add(createMockEvent('4'));

      await Future.delayed(Duration(milliseconds: 200));

      expect(resultList.length, equals(4), reason: 'Should process all events without deadlocking');

      await subscription.cancel();
      await controller.close();
    });

    test('should yield events immediately upon verification completion', () async {
      final controller = StreamController<Nip01Event>();
      final resultTimes = <DateTime>[];

      final verifyStream = VerifyEventStream(
        unverifiedStreamInput: controller.stream,
        eventVerifier: mockVerifier,
        maxConcurrent: 5,
      );

      final subscription = verifyStream().listen((event) {
        resultTimes.add(DateTime.now());
      });

      final startTime = DateTime.now();

      controller.add(createMockEvent('1'));
      await Future.delayed(Duration(milliseconds: 20));
      controller.add(createMockEvent('2'));
      await Future.delayed(Duration(milliseconds: 20));
      controller.add(createMockEvent('3'));

      await Future.delayed(Duration(milliseconds: 100));

      expect(resultTimes.length, equals(3));

      for (int i = 0; i < resultTimes.length; i++) {
        final timeDiff = resultTimes[i].difference(startTime).inMilliseconds;
        expect(timeDiff, lessThan(200), reason: 'Event $i should be processed within 200ms, was ${timeDiff}ms');
      }

      await subscription.cancel();
      await controller.close();
    });
  });
}

/// A mock event verifier that introduces variable delays based on event content
/// Used to test completion-order processing rather than input-order processing
class DelayedMockEventVerifier extends EventVerifier {
  @override
  Future<bool> verify(Nip01Event event) async {
    // Introduce different delays based on event content to test completion order
    if (event.content.contains('slow')) {
      await Future.delayed(Duration(milliseconds: 100));
    } else if (event.content.contains('fast')) {
      await Future.delayed(Duration(milliseconds: 10));
    } else {
      // Default small delay
      await Future.delayed(Duration(milliseconds: 1));
    }
    return true;
  }
}
