import 'dart:io';

import 'package:test/test.dart';

import 'mock_relay.dart';

void main() {
  test('stopServer closes the client websockets', () async {
    final relay = MockRelay(name: 'stop server relay');
    await relay.startServer();

    final client = await WebSocket.connect(relay.url);
    var closed = false;
    client.listen((_) {}, onDone: () => closed = true);

    await Future.delayed(const Duration(milliseconds: 100));
    expect(client.readyState, WebSocket.open);

    await relay.stopServer();
    await Future.delayed(const Duration(milliseconds: 300));

    expect(closed, isTrue);
    expect(client.readyState, WebSocket.closed);
  });
}
