@TestOn('vm')
library;

import 'dart:async';
import 'dart:io' as io;

import 'package:ndk/src/web_socket_client/web_socket_client.dart';
import 'package:test/test.dart';

void main() {
  test(
    'closing client aborts a native handshake with no upgrade response',
    () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      final peer = Completer<_HeldUpgrade>();
      server.listen((request) async {
        peer.complete(await _HeldUpgrade.fromRequest(request));
      });
      final client = WebSocket(Uri.parse('ws://127.0.0.1:${server.port}'));
      final held = await peer.future;
      addTearDown(() async {
        client.close();
        held.socket.destroy();
        await server.close(force: true);
      });

      client.close();
      await held.closed.future.timeout(const Duration(seconds: 1));
      expect(client.connection.state, const Disconnected());
    },
  );

  test(
    'handshake timeout closes native socket and preserves the live retry',
    () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      final firstPeer = Completer<_HeldUpgrade>();
      final retryPeer = Completer<io.WebSocket>();
      var attempts = 0;
      server.listen((request) async {
        if (attempts++ == 0) {
          firstPeer.complete(await _HeldUpgrade.fromRequest(request));
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
      final held = await firstPeer.future;
      io.WebSocket? livePeer;
      addTearDown(() async {
        client.close();
        held.socket.destroy();
        await livePeer?.close();
        await server.close(force: true);
      });

      await held.closed.future.timeout(const Duration(seconds: 1));
      await client.connection
          .firstWhere((state) => state is Reconnected)
          .timeout(const Duration(seconds: 3));
      livePeer = await retryPeer.future;
      expect(livePeer.readyState, io.WebSocket.open);
      final echo = client.messages.first;
      client.send('still connected');
      expect(await echo.timeout(const Duration(seconds: 1)), 'still connected');
    },
  );

  test('owned HTTP client preserves configured WebSocket user agent', () async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    final receivedAgent = Completer<String?>();
    io.WebSocket? peer;
    server.listen((request) async {
      receivedAgent.complete(
        request.headers.value(io.HttpHeaders.userAgentHeader),
      );
      peer = await io.WebSocketTransformer.upgrade(request);
      peer!.listen((_) {});
    });
    final previousAgent = io.WebSocket.userAgent;
    io.WebSocket.userAgent = 'NDK handshake lifecycle test';
    final client = WebSocket(Uri.parse('ws://127.0.0.1:${server.port}'));
    addTearDown(() async {
      io.WebSocket.userAgent = previousAgent;
      client.close();
      await peer?.close();
      await server.close(force: true);
    });
    await client.connection.firstWhere((state) => state is Connected);
    expect(await receivedAgent.future, 'NDK handshake lifecycle test');
  });
}

/// Reads the HTTP upgrade request but never answers it. Unlike an eventual
/// upgrade, this exposes native connections that survive client cancellation.
class _HeldUpgrade {
  final io.Socket socket;
  final closed = Completer<void>();

  _HeldUpgrade(this.socket) {
    socket.listen(
      (_) {},
      onDone: () {
        if (!closed.isCompleted) closed.complete();
      },
      onError: (Object _) {
        if (!closed.isCompleted) closed.complete();
      },
    );
  }

  static Future<_HeldUpgrade> fromRequest(io.HttpRequest request) async =>
      _HeldUpgrade(await request.response.detachSocket(writeHeaders: false));
}
