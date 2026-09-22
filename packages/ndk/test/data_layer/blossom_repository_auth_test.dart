import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/io/file_io_platform.dart';
import 'package:ndk/data_layer/repositories/blossom/blossom_impl.dart';
import 'package:ndk/domain_layer/repositories/blossom.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../mocks/mock_blossom_server.dart';

const int refusingPort = 30020;
const int secondRefusingPort = 30021;
const int publicPort = 30022;

Nip01Event _authEvent(String type) => Nip01Event(
      pubKey:
          'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
      kind: 24242,
      tags: [
        ['t', type],
      ],
      content: type,
    );

/// A server that refuses without an identity is asking for one. These drive
/// the repository directly, because the usecase cannot express a policy yet.
void main() {
  late BlossomRepository repo;

  setUp(() {
    repo = BlossomRepositoryImpl(
      client: HttpRequestDS(http.Client()),
      fileIO: createFileIO(),
    );
  });

  /// puts a blob on [server] while it still accepts anonymous writes
  Future<String> seed(MockBlossomServer server, Uint8List data) async {
    final uploaded = await repo.uploadBlob(
      dataStreamFactory: () => Stream.value(data),
      contentLength: data.length,
      authorization: BlossomAuthorization.upfront(_authEvent('upload')),
      serverUrls: ['http://localhost:${server.port}'],
    ).last;
    expect(uploaded.completedUploads.first.success, true);
    server.clearRequests();
    return uploaded.completedUploads.first.descriptor!.sha256;
  }

  group('a refused read', () {
    late MockBlossomServer server;
    late Uint8List data;
    late String sha256;

    setUp(() async {
      server = MockBlossomServer(port: refusingPort, authRefusalStatus: 401);
      await server.start();
      data = Uint8List.fromList(utf8.encode('private blob'));
      sha256 = await seed(server, data);
      server.requireAuthForReads = true;
    });

    tearDown(() async => server.stop());

    test('is not retried when the operation may not authorise', () async {
      await expectLater(
        repo.getBlob(
          sha256: sha256,
          serverUrls: ['http://localhost:${server.port}'],
        ),
        throwsA(isA<Exception>()),
      );

      expect(server.countRequests(method: 'GET'), 1);
      expect(server.countRequests(hasAuth: true), 0);
    });

    test('is replayed with an event signed only once refused', () async {
      var signatures = 0;

      final blob = await repo.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
        authorization: BlossomAuthorization.onRefusal(() async {
          signatures++;
          return _authEvent('get');
        }),
      );

      expect(utf8.decode(blob.data), utf8.decode(data));
      expect(signatures, 1);

      final gets = server.requests.where((r) => r.method == 'GET').toList();
      expect(gets, hasLength(2));
      expect(gets.first.hasAuth, false, reason: 'the first try stays bare');
      expect(gets.last.hasAuth, true);
    });

    test('goes out authorised from the start when required', () async {
      await repo.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
        authorization: BlossomAuthorization.upfront(_authEvent('get')),
      );

      expect(server.countRequests(method: 'GET'), 1);
      expect(server.countRequests(method: 'GET', hasAuth: true), 1);
    });
  });

  group('a server that never asks', () {
    late MockBlossomServer server;
    late String sha256;

    setUp(() async {
      server = MockBlossomServer(port: publicPort);
      await server.start();
      sha256 = await seed(server, Uint8List.fromList(utf8.encode('public')));
    });

    tearDown(() async => server.stop());

    test('never sees the identity of an operation that would allow it',
        () async {
      var signatures = 0;

      await repo.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
        authorization: BlossomAuthorization.onRefusal(() async {
          signatures++;
          return _authEvent('get');
        }),
      );

      expect(signatures, 0, reason: 'nothing refused, so nothing was signed');
      expect(server.countRequests(hasAuth: true), 0);
    });
  });

  group('several refusing servers', () {
    late MockBlossomServer first;
    late MockBlossomServer second;
    late Uint8List data;

    setUp(() async {
      first = MockBlossomServer(
        port: refusingPort,
        authRefusalStatus: 401,
        responseDelay: const Duration(milliseconds: 20),
      );
      second = MockBlossomServer(
        port: secondRefusingPort,
        authRefusalStatus: 401,
        responseDelay: const Duration(milliseconds: 20),
      );
      await first.start();
      await second.start();
      data = Uint8List.fromList(utf8.encode('deleted everywhere'));
    });

    tearDown(() async {
      await first.stop();
      await second.stop();
    });

    test('share one signature when they refuse at the same time', () async {
      final sha256 = await seed(first, data);
      await seed(second, data);
      var signatures = 0;

      final results = await repo.deleteBlob(
        sha256: sha256,
        serverUrls: [
          'http://localhost:${first.port}',
          'http://localhost:${second.port}',
        ],
        authorization: BlossomAuthorization.onRefusal(() async {
          signatures++;
          return _authEvent('delete');
        }),
      );

      expect(results.every((r) => r.success), true);
      expect(signatures, 1,
          reason: 'a remote signer would otherwise prompt once per server');
      expect({...first.signedEventIds, ...second.signedEventIds}, hasLength(1));
    });
  });

  group('a refused upload', () {
    late MockBlossomServer server;

    setUp(() async {
      server = MockBlossomServer(port: refusingPort, authRefusalStatus: 401);
      await server.start();
    });

    tearDown(() async => server.stop());

    test('replays the body intact', () async {
      final data = Uint8List.fromList(utf8.encode('a' * 2048));

      final uploaded = await repo
          .uploadBlob(
            dataStreamFactory: () => Stream.value(data),
            contentLength: data.length,
            serverUrls: ['http://localhost:${server.port}'],
            authorization: BlossomAuthorization.onRefusal(
              () async => _authEvent('upload'),
            ),
          )
          .last;

      final result = uploaded.completedUploads.single;
      expect(result.success, true);

      final puts = server.requests.where((r) => r.method == 'PUT').toList();
      expect(puts, hasLength(2));
      expect(puts.first.hasAuth, false);
      expect(puts.last.hasAuth, true);

      // the server stores by hash, so a truncated replay could not match
      final served = await repo.getBlob(
        sha256: result.descriptor!.sha256,
        serverUrls: ['http://localhost:${server.port}'],
      );
      expect(served.data, data);
    });
  });
}
