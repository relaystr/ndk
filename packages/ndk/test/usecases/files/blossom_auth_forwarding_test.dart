import 'dart:convert';
import 'dart:typed_data';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';
import '../../mocks/mock_event_verifier.dart';

const int authServerPort = 30010;
const int rangeServerPort = 30011;

/// An operation that asks for an authorization must carry it on every request
/// it makes, not only on the first one it happens to build headers for.
void main() {
  late MockBlossomServer server;
  late Blossom client;
  late Account loggedAccount;
  late String serverUrl;

  Future<Blossom> startWith(MockBlossomServer s) async {
    server = s;
    await server.start();
    serverUrl = 'http://localhost:${server.port}';

    KeyPair key = Bip340.generatePrivateKey();
    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ),
    );
    ndk.accounts.loginPrivateKey(
      pubkey: key.publicKey,
      privkey: key.privateKey!,
    );
    loggedAccount = ndk.accounts.getLoggedAccount()!;
    return ndk.blossom;
  }

  /// uploads through a server that demands nothing, so the blob exists before
  /// the reads under test
  Future<String> seedBlob(Uint8List data) async {
    final uploaded = await client.uploadBlob(
      data: data,
      serverUrls: [serverUrl],
    );
    expect(uploaded.first.success, true);
    server.clearRequests();
    return uploaded.first.descriptor!.sha256;
  }

  tearDown(() async {
    await server.stop();
  });

  group('checkBlob', () {
    setUp(() async {
      client = await startWith(MockBlossomServer(port: authServerPort));
    });

    test('sends the authorization on its HEAD request', () async {
      final sha256 = await seedBlob(
        Uint8List.fromList(utf8.encode('check me')),
      );

      await client.checkBlob(
        sha256: sha256,
        auth: AuthPolicy.require(loggedAccount),
        serverUrls: [serverUrl],
      );

      final heads = server.requests.where((r) => r.method == 'HEAD').toList();
      expect(heads, hasLength(1));
      expect(heads.single.hasAuth, true,
          reason: 'the header was built but never handed to client.head');
      expect(heads.single.authType, 'get');
    });

    test('sends nothing when no authorization was asked for', () async {
      final sha256 = await seedBlob(
        Uint8List.fromList(utf8.encode('check me anonymously')),
      );

      await client.checkBlob(sha256: sha256, serverUrls: [serverUrl]);

      expect(server.countRequests(method: 'HEAD', hasAuth: true), 0);
    });
  });

  group('getBlobStream', () {
    test('sends the authorization on the whole-blob fallback', () async {
      client = await startWith(MockBlossomServer(port: authServerPort));
      final sha256 = await seedBlob(
        Uint8List.fromList(utf8.encode('no ranges here')),
      );

      final stream = await client.getBlobStream(
        sha256: sha256,
        auth: AuthPolicy.require(loggedAccount),
        serverUrls: [serverUrl],
      );
      await stream.toList();

      // no accept-ranges, so this went through getBlob rather than chunking
      final gets = server.requests.where((r) => r.method == 'GET').toList();
      expect(gets, hasLength(1));
      expect(gets.single.hasAuth, true);
      expect(gets.single.authType, 'get');
    });

    test('sends the authorization on the HEAD probe and on every chunk',
        () async {
      client = await startWith(
        MockBlossomServer(port: rangeServerPort, supportRangeRequests: true),
      );
      // four chunks at the 16 byte chunk size below
      final data = Uint8List.fromList(utf8.encode('a' * 64));
      final sha256 = await seedBlob(data);

      final stream = await client.getBlobStream(
        sha256: sha256,
        auth: AuthPolicy.require(loggedAccount),
        serverUrls: [serverUrl],
        chunkSize: 16,
      );
      final chunks = await stream.toList();

      expect(chunks.length, greaterThan(1),
          reason: 'the ranged path should have been taken, not the fallback');
      expect(
        chunks.map((c) => utf8.decode(c.data)).join(),
        utf8.decode(data),
      );
      expect(server.countRequests(hasAuth: false), 0,
          reason: 'the probe and every chunk must carry the authorization');
      expect(server.countRequests(method: 'HEAD', hasAuth: true), 1);
      expect(server.countRequests(method: 'GET', hasAuth: true), chunks.length);
    });
  });
}
