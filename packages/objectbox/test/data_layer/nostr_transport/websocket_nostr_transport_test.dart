import 'package:test/test.dart';
import 'package:ndk/data_layer/data_sources/websocket.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';

// This will generate a MockWebsocketDS class
@GenerateNiceMocks([MockSpec<WebsocketDS>()])
import 'websocket_nostr_transport_test.mocks.dart';

void main() {
  late MockWebsocketDS mockWebsocketDS;
  late WebSocketNostrTransport transport;

  setUp(() {
    mockWebsocketDS = MockWebsocketDS();
    transport = WebSocketNostrTransport(mockWebsocketDS);
  });

  test('ready should return the WebsocketDS ready future', () async {
    final readyFuture = Future<void>.value();
    when(mockWebsocketDS.ready()).thenAnswer((_) => readyFuture);

    expect(transport.ready, completion(equals(null)));

    // Verify that transport.ready and readyFuture complete at the same time
    await Future.wait([transport.ready, readyFuture]);
  });

  test('close should call WebsocketDS close', () async {
    when(mockWebsocketDS.close()).thenAnswer((_) => Future.value());

    await transport.close();

    verify(mockWebsocketDS.close()).called(1);
  });

  test('listen should delegate to WebsocketDS listen', () {
    onData(dynamic _) {}
    onError() {}
    onDone() {}
    final mockSubscription = MockStreamSubscription();

    when(mockWebsocketDS.listen(any,
            onError: anyNamed('onError'), onDone: anyNamed('onDone')))
        .thenReturn(mockSubscription);

    final result = transport.listen(onData, onError: onError, onDone: onDone);

    expect(result, equals(mockSubscription));
    verify(mockWebsocketDS.listen(onData, onError: onError, onDone: onDone))
        .called(1);
  });

  test('send should delegate to WebsocketDS send', () {
    final testData = {'key': 'value'};

    transport.send(testData);

    verify(mockWebsocketDS.send(testData)).called(1);
  });

  test('isOpen should return WebsocketDS isOpen result', () {
    when(mockWebsocketDS.isOpen()).thenReturn(true);

    expect(transport.isOpen(), isTrue);

    verify(mockWebsocketDS.isOpen()).called(1);
  });

  test('closeCode should return WebsocketDS closeCode', () {
    when(mockWebsocketDS.closeCode()).thenReturn(1000);

    expect(transport.closeCode(), equals(1000));

    verify(mockWebsocketDS.closeCode()).called(1);
  });

  test('closeReason should return WebsocketDS closeReason', () {
    when(mockWebsocketDS.closeReason()).thenReturn('Normal Closure');

    expect(transport.closeReason(), equals('Normal Closure'));

    verify(mockWebsocketDS.closeReason()).called(1);
  });
}

// Mock StreamSubscription for the listen test
class MockStreamSubscription extends Mock implements StreamSubscription {}
