import 'dart:async';
import 'dart:io' as io;

import 'package:ndk/src/web_socket_client/web_socket_client.dart';
import 'package:test/test.dart';

void main() {
  test(
    'closes a handshake that completes after the client was closed',
    () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      final request = Completer<io.HttpRequest>();
      server.listen(request.complete);
      final client = WebSocket(Uri.parse('ws://127.0.0.1:${server.port}'));
      io.WebSocket? peer;
      addTearDown(() async {
        client.close();
        await peer?.close();
        await server.close(force: true);
      });

      final pendingRequest = await request.future;
      client.close();
      await client.connection.drain<void>();
      peer = await io.WebSocketTransformer.upgrade(pendingRequest);
      await expectLater(
        peer.drain<void>().timeout(const Duration(seconds: 1)),
        completes,
      );
      expect(client.connection.state, const Disconnected());
    },
  );

  test(
    'closes a timed-out handshake without replacing the live retry',
    () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      final firstRequest = Completer<io.HttpRequest>();
      final retryPeer = Completer<io.WebSocket>();
      server.listen((request) async {
        if (!firstRequest.isCompleted) {
          firstRequest.complete(request);
        } else {
          final peer = await io.WebSocketTransformer.upgrade(request);
          peer.listen(peer.add);
          retryPeer.complete(peer);
        }
      });
      final client = WebSocket(
        Uri.parse('ws://127.0.0.1:${server.port}'),
        timeout: const Duration(milliseconds: 150),
        backoff: const ConstantBackoff(Duration(milliseconds: 10)),
      );
      io.WebSocket? stalePeer;
      io.WebSocket? livePeer;
      addTearDown(() async {
        client.close();
        await stalePeer?.close();
        await livePeer?.close();
        await server.close(force: true);
      });

      await client.connection
          .firstWhere((state) => state is Reconnected)
          .timeout(const Duration(seconds: 3));
      livePeer = await retryPeer.future;
      stalePeer = await io.WebSocketTransformer.upgrade(
        await firstRequest.future,
      );
      await expectLater(
        stalePeer.drain<void>().timeout(const Duration(seconds: 1)),
        completes,
      );
      expect(livePeer.readyState, io.WebSocket.open);
      final echo = client.messages.first;
      client.send('still connected');
      expect(await echo.timeout(const Duration(seconds: 1)), 'still connected');
    },
  );
}
