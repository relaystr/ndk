@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import 'package:test/test.dart';

import '../../mocks/mock_relay.dart';

void main() {
  test('a refused connection is never open', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();

    final transport = WebSocketNostrTransportFactory().call(
      'ws://127.0.0.1:$port',
    );

    expect(transport.isOpen(), isFalse);
    expect(transport.isConnecting(), isTrue);

    await expectLater(transport.ready, throwsA(anything));

    expect(transport.isOpen(), isFalse);
    expect(transport.isConnecting(), isFalse);
  });

  test('a connection is open until the relay closes it', () async {
    final relay = MockRelay(name: 'closing relay');
    await relay.startServer();
    addTearDown(relay.stopServer);

    final transport = WebSocketNostrTransportFactory().call(relay.url);
    final ended = Completer<void>();
    transport.listen((_) {}, onDone: ended.complete);

    await transport.ready;
    expect(transport.isOpen(), isTrue);
    expect(transport.isConnecting(), isFalse);

    // the server registers the client asynchronously
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (relay.connectedClientCount == 0 &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await relay.closeClientSockets();
    await ended.future.timeout(const Duration(seconds: 5));

    expect(transport.isOpen(), isFalse);
    expect(transport.isConnecting(), isFalse);
  });
}
