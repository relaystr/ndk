import 'package:ndk/domain_layer/entities/nip_01_event.dart';
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
  });
}
