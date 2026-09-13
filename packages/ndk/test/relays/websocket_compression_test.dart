import 'dart:async';
import 'dart:io';

import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport_factory.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

class _CompressionRelay {
  late final HttpServer _server;
  final Map<String, List<String?>> extensionOffers = {};
  final Map<String, List<WebSocket>> sockets = {};

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      final path = request.uri.path;
      extensionOffers
          .putIfAbsent(path, () => [])
          .add(request.headers.value('sec-websocket-extensions'));
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.putIfAbsent(path, () => []).add(socket);
      socket.listen(socket.add);
    });
  }

  String url(String path) => 'ws://localhost:${_server.port}$path';

  Future<void> close() async {
    for (final socket in sockets.values.expand((sockets) => sockets)) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}

Future<void> _waitUntil(
  bool Function() condition, {
  String reason = 'condition never became true',
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail(reason);
}

Ndk _createNdk(
  String relayUrl, {
  required NdkEngine engine,
  required bool compressionEnabled,
}) {
  return Ndk(
    NdkConfig(
      cache: MemCacheManager(),
      eventVerifier: Bip340EventVerifier(),
      bootstrapRelays: [relayUrl],
      engine: engine,
      webSocketCompression: compressionEnabled,
    ),
  );
}

void main() {
  group('WebSocket compression', () {
    late _CompressionRelay relay;

    setUp(() async {
      relay = _CompressionRelay();
      await relay.start();
    });

    tearDown(() => relay.close());

    test('NdkConfig preserves compression by default', () {
      final config = NdkConfig(
        cache: MemCacheManager(),
        eventVerifier: Bip340EventVerifier(),
      );

      expect(config.webSocketCompression, isTrue);
    });

    test('defaults on, supports opt-out, and keeps opt-out after reconnect',
        () async {
      final defaultTransport = WebSocketClientNostrTransportFactory()(
        relay.url('/default'),
      );
      final uncompressedTransport = WebSocketClientNostrTransportFactory(
        compressionEnabled: false,
      )(relay.url('/uncompressed'));

      try {
        await Future.wait([
          defaultTransport.ready,
          uncompressedTransport.ready,
        ]);

        expect(
          relay.extensionOffers['/default']!.single,
          contains('permessage-deflate'),
        );
        expect(relay.extensionOffers['/uncompressed']!.single, isNull);

        final firstEcho = Completer<dynamic>();
        final subscription = uncompressedTransport.listen((message) {
          if (!firstEcho.isCompleted) firstEcho.complete(message);
        });
        uncompressedTransport.send('before reconnect');
        expect(await firstEcho.future, 'before reconnect');

        await relay.sockets['/uncompressed']!.last.close();
        await _waitUntil(
          () => relay.extensionOffers['/uncompressed']!.length == 2,
          reason: 'transport did not reconnect',
        );
        await _waitUntil(
          uncompressedTransport.isOpen,
          reason: 'reconnected transport did not become ready',
        );
        expect(relay.extensionOffers['/uncompressed'], everyElement(isNull));

        final secondEcho = Completer<dynamic>();
        final reconnectedSubscription = uncompressedTransport.listen((message) {
          if (!secondEcho.isCompleted) secondEcho.complete(message);
        });
        uncompressedTransport.send('after reconnect');
        expect(await secondEcho.future, 'after reconnect');

        await subscription.cancel();
        await reconnectedSubscription.cancel();
      } finally {
        await defaultTransport.close();
        await uncompressedTransport.close();
      }
    });

    for (final engine in NdkEngine.values) {
      test('NdkConfig opt-out reaches ${engine.name} relay connections',
          () async {
        final path = '/${engine.name.toLowerCase()}';
        final ndk = _createNdk(
          relay.url(path),
          engine: engine,
          compressionEnabled: false,
        );

        try {
          await ndk.relays.seedRelaysConnected;
          expect(relay.extensionOffers[path], everyElement(isNull));
        } finally {
          await ndk.destroy();
        }
      });
    }

    test('compression setting remains instance-local', () async {
      final compressed = _createNdk(
        relay.url('/compressed-instance'),
        engine: NdkEngine.RELAY_SETS,
        compressionEnabled: true,
      );
      final uncompressed = _createNdk(
        relay.url('/uncompressed-instance'),
        engine: NdkEngine.RELAY_SETS,
        compressionEnabled: false,
      );

      try {
        await Future.wait([
          compressed.relays.seedRelaysConnected,
          uncompressed.relays.seedRelaysConnected,
        ]);
        expect(
          relay.extensionOffers['/compressed-instance']!.single,
          contains('permessage-deflate'),
        );
        expect(
          relay.extensionOffers['/uncompressed-instance']!.single,
          isNull,
        );
      } finally {
        await compressed.destroy();
        await uncompressed.destroy();
      }
    });
  });
}
