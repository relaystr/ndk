@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport_factory.dart';
import 'package:test/test.dart';

void main() {
  test('a refused connection reports its error on disconnect', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();

    final reported = Completer<Object?>();
    final transport = WebSocketClientNostrTransportFactory().call(
      'ws://127.0.0.1:$port',
      onDisconnect: (code, error, reason) {
        if (!reported.isCompleted) reported.complete(error);
      },
    );
    addTearDown(transport.close);

    final error = await reported.future.timeout(const Duration(seconds: 2));
    expect(error, isNotNull);
    expect('$error', contains('SocketException'));
  });
}
