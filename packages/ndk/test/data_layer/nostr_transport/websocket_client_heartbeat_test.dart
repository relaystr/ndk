@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport_factory.dart';
import 'package:test/test.dart';

void main() {
  test(
    'custom heartbeat reaches native socket without delaying events',
    () async {
      final peer = await _RawPeer.start();
      final transport = WebSocketClientNostrTransportFactory(
        pingInterval: const Duration(milliseconds: 100),
      ).call(peer.url);
      addTearDown(() async {
        await transport.close();
        await peer.close();
      });
      await transport.ready.timeout(const Duration(seconds: 2));
      final received = Completer<String>();
      final subscription = transport.listen((message) {
        if (!received.isCompleted) received.complete(message as String);
      });
      addTearDown(subscription.cancel);

      peer.sendText('offer arrived');
      expect(
        await received.future.timeout(const Duration(seconds: 1)),
        'offer arrived',
      );
      await peer.firstPing.future.timeout(const Duration(seconds: 2));
      expect(transport.isOpen(), isTrue);
    },
  );

  test(
    'null heartbeat leaves idle socket silent and events available',
    () async {
      final peer = await _RawPeer.start();
      final transport = WebSocketClientNostrTransportFactory(
        pingInterval: null,
      ).call(peer.url);
      addTearDown(() async {
        await transport.close();
        await peer.close();
      });
      await transport.ready.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(peer.firstPing.isCompleted, isFalse);

      final received = Completer<String>();
      final subscription = transport.listen((message) {
        if (!received.isCompleted) received.complete(message as String);
      });
      addTearDown(subscription.cancel);
      peer.sendText('still listening');
      expect(
        await received.future.timeout(const Duration(seconds: 1)),
        'still listening',
      );
    },
  );
}

/// Minimal uncompressed WebSocket peer exposing control frames hidden by
/// dart:io.WebSocket, so the test observes real native heartbeat traffic.
class _RawPeer {
  final HttpServer server;
  final firstPing = Completer<void>();
  final List<int> _buffer = [];
  Socket? _socket;

  _RawPeer(this.server) {
    server.listen((request) async {
      final key = request.headers.value('sec-websocket-key')!;
      request.response
        ..statusCode = HttpStatus.switchingProtocols
        ..headers.set('connection', 'Upgrade')
        ..headers.set('upgrade', 'websocket')
        ..headers.set(
          'sec-websocket-accept',
          base64.encode(
            sha1
                .convert(
                  utf8.encode('${key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11'),
                )
                .bytes,
          ),
        );
      final socket = await request.response.detachSocket();
      _socket = socket;
      socket.listen(_onBytes, onError: (Object _) {});
    });
  }

  static Future<_RawPeer> start() async =>
      _RawPeer(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  String get url => 'ws://127.0.0.1:${server.port}';

  void sendText(String text) {
    final payload = utf8.encode(text);
    _socket!.add([0x81, payload.length, ...payload]);
  }

  void _onBytes(List<int> bytes) {
    _buffer.addAll(bytes);
    while (_buffer.length >= 2) {
      final opcode = _buffer[0] & 0x0f;
      final length = _buffer[1] & 0x7f;
      // These tests send only small client control frames.
      if (length >= 126) throw StateError('Unexpected extended frame');
      final masked = (_buffer[1] & 0x80) != 0;
      final headerLength = masked ? 6 : 2;
      if (_buffer.length < headerLength + length) return;
      final payload = List<int>.generate(
        length,
        (index) =>
            _buffer[headerLength + index] ^
            (masked ? _buffer[2 + index % 4] : 0),
      );
      _buffer.removeRange(0, headerLength + length);
      if (opcode == 9) {
        _socket!.add([0x8a, payload.length, ...payload]);
        if (!firstPing.isCompleted) firstPing.complete();
      } else if (opcode == 8) {
        _socket!.add([0x88, payload.length, ...payload]);
      }
    }
  }

  Future<void> close() async {
    _socket?.destroy();
    await server.close(force: true);
  }
}
