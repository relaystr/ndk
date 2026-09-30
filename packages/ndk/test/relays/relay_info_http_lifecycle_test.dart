import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/relay_info_http_impl.dart';
import 'package:ndk/domain_layer/entities/relay_info.dart';
import 'package:test/test.dart';

/// Keep production HTTPS mapping while routing test requests to local HTTP.
/// Request abortion uses the real IOClient.
class _LoopbackClient extends http.BaseClient {
  final IOClient inner = IOClient();
  bool closed = false;
  bool aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final trigger = (request as http.Abortable).abortTrigger!;
    unawaited(trigger.then((_) => aborted = true));
    final local = http.AbortableRequest(
      request.method,
      request.url.replace(scheme: 'http'),
      abortTrigger: trigger,
    )..headers.addAll(request.headers);
    return inner.send(local);
  }

  @override
  void close() {
    closed = true;
    inner.close();
  }
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('socket remained open');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  for (final scenario in [('headers', true, false), ('body', true, true)]) {
    test(
      'timeout closes native socket when ${scenario.$1} never finishes',
      () async {
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final connected = Completer<void>();
        final peerClosed = Completer<void>();
        Socket? peer;
        server.listen((socket) {
          peer = socket;
          socket.listen(
            (data) {
              if (!connected.isCompleted) {
                connected.complete();
                if (scenario.$3) {
                  socket.write(
                    'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nTransfer-Encoding: chunked\r\n\r\n2\r\n{}\r\n',
                  );
                }
              }
            },
            onDone: () {
              if (!peerClosed.isCompleted) peerClosed.complete();
            },
          );
        });
        final client = _LoopbackClient();
        addTearDown(() async {
          client.close();
          peer?.destroy();
          await server.close();
        });
        final result = RelayInfoHttpRepoImpl(
          httpDS: HttpRequestDS(client),
          timeout: const Duration(milliseconds: 300),
        ).getRelayInfo('wss://127.0.0.1:${server.port}');
        await connected.future.timeout(const Duration(seconds: 2));
        expect(await result, isNull);
        await _waitUntil(() => client.aborted);
        await peerClosed.future.timeout(const Duration(seconds: 2));
      },
    );
  }

  test('valid response is decoded as UTF-8 nostr+json', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      expect(request.headers.value('Accept'), 'application/nostr+json');
      request.response.write(
        jsonEncode({
          'name': 'Test relay ⚡',
          'supported_nips': [1, 11],
        }),
      );
      await request.response.close();
    });
    final client = _LoopbackClient();
    addTearDown(() async {
      client.close();
      await server.close(force: true);
    });
    final info = await RelayInfoHttpRepoImpl(
      httpDS: HttpRequestDS(client),
    ).getRelayInfo('wss://127.0.0.1:${server.port}');
    expect(info?.name, 'Test relay ⚡');
    expect(info?.supportsNip(11), isTrue);
    expect(client.aborted, isFalse);
  });

  test('malformed response returns null', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write('invalid json');
      await request.response.close();
    });
    final client = _LoopbackClient();
    addTearDown(() async {
      client.close();
      await server.close(force: true);
    });
    final info = await RelayInfoHttpRepoImpl(
      httpDS: HttpRequestDS(client),
    ).getRelayInfo('wss://127.0.0.1:${server.port}');
    expect(info, isNull);
  });

  test('deprecated RelayInfo.get delegates and closes its client', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write(jsonEncode({'name': 'Legacy relay'}));
      await request.response.close();
    });
    final client = _LoopbackClient();
    addTearDown(() async => server.close(force: true));
    final info = await http.runWithClient(
      // ignore: deprecated_member_use_from_same_package
      () => RelayInfo.get('wss://127.0.0.1:${server.port}'),
      () => client,
    );
    expect(info?.name, 'Legacy relay');
    expect(client.closed, isTrue);
  });
}
