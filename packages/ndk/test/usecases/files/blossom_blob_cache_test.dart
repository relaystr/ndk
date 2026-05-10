import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';
import '../../mocks/mock_event_verifier.dart';

const int port = 30100;

void main() {
  late MockBlossomServer server;
  late Ndk ndk;
  late Blossom blossom;
  late BlobCacheManager blobCache;

  setUp(() async {
    server = MockBlossomServer(port: port);
    await server.start();

    final key = Bip340.generatePrivateKey();
    ndk = Ndk(
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

    blossom = ndk.blossom;
    // Default fallback in Initialization populates this with a fresh
    // in-memory IdbBlobCacheManager (via newIdbFactoryMemory()).
    blobCache = ndk.config.blobCache!;
  });

  tearDown(() async {
    await server.stop();
    await blobCache.close();
    await ndk.destroy();
  });

  Uint8List bytesOf(String s) => Uint8List.fromList(utf8.encode(s));

  // Test helper — uploads to the mock server without populating the
  // local cache, so getBlob tests start from a known-empty state.
  // Tests that exercise upload-caching behaviour call uploadBlob
  // directly with their own cacheWrite value.
  Future<String> uploadAndGetSha(String payload) async {
    final response = await blossom.uploadBlob(
      data: bytesOf(payload),
      serverUrls: ['http://localhost:$port'],
      cacheWrite: false,
    );
    return response.first.descriptor!.sha256;
  }

  test('config exposes the default in-memory blob cache instance', () {
    expect(ndk.config.blobCache, isNotNull);
    expect(ndk.config.blobCache, same(blobCache));
  });

  group('getBlob', () {
    test('caches the bytes after a cache miss', () async {
      final sha = await uploadAndGetSha('cache me');
      expect(await blobCache.hasBlob(sha), isFalse,
          reason: 'cache should be empty before the first get');

      await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );

      expect(await blobCache.hasBlob(sha), isTrue,
          reason: 'cache should be populated after a successful get');
      final descriptor = await blobCache.getBlobDescriptor(sha);
      expect(descriptor!.size, 'cache me'.length);
    });

    test('serves from the cache without hitting the server', () async {
      final sha = await uploadAndGetSha('cached payload');

      // First get → server hit + cache save.
      final first = await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );
      expect(utf8.decode(first.data), 'cached payload');

      // Stop the server: a second get must succeed from the cache.
      await server.stop();
      final second = await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );
      expect(utf8.decode(second.data), 'cached payload');
    });

    test('after removeBlob the next get hits the server again', () async {
      final sha = await uploadAndGetSha('payload');

      await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );
      // Drop the cache entry then stop the server: the next get has
      // nowhere to source the bytes from and must throw.
      await blobCache.removeBlob(sha);
      await server.stop();
      final attempt = blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );
      expect(attempt, throwsException);
    });

    test('user-managed cache is consulted by Blossom', () async {
      // The user pre-populates the cache with arbitrary bytes for an
      // arbitrary sha — Blossom should serve them without ever
      // contacting the server.
      const sha = 'user-injected-key';
      final data = bytesOf('injected from outside');
      await blobCache.saveBlob(
        data: data,
        sha256: sha,
        mimeType: 'text/plain',
      );

      // Server has no idea about this sha.
      final response = await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );
      expect(response.data, data);
      expect(response.mimeType, 'text/plain');
    });
  });

  group('downloadBlobToFile', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('ndk_blob_cache_test_');
    });

    tearDown(() async {
      if (tmp.existsSync()) {
        await tmp.delete(recursive: true);
      }
    });

    test('writes the cached bytes to disk on cache hit', () async {
      final sha = await uploadAndGetSha('to disk from cache');
      // Populate cache via getBlob first.
      await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );

      // Stop the server: download must come from the cache.
      await server.stop();
      final out = '${tmp.path}/blob.bin';
      await blossom.downloadBlobToFile(
        sha256: sha,
        outputPath: out,
        serverUrls: ['http://localhost:$port'],
      );

      final written = await File(out).readAsBytes();
      expect(utf8.decode(written), 'to disk from cache');
    });

    test('after removeBlob the next downloadBlobToFile hits the server',
        () async {
      final sha = await uploadAndGetSha('refresh me');
      await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );

      await blobCache.removeBlob(sha);
      await server.stop();
      final out = '${tmp.path}/blob.bin';
      final attempt = blossom.downloadBlobToFile(
        sha256: sha,
        outputPath: out,
        serverUrls: ['http://localhost:$port'],
      );
      expect(attempt, throwsException);
    });
  });

  group('deleteBlob', () {
    test('invalidates the cached entry', () async {
      final sha = await uploadAndGetSha('delete me');
      await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );
      expect(await blobCache.hasBlob(sha), isTrue);

      await blossom.deleteBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );
      expect(await blobCache.hasBlob(sha), isFalse);
    });
  });

  group('cacheWrite', () {
    test('uploadBlob auto-caches the bytes by default', () async {
      final data = bytesOf('upload-and-cache');
      final result = await blossom.uploadBlob(
        data: data,
        serverUrls: ['http://localhost:$port'],
      );
      final sha = result.first.descriptor!.sha256;
      expect(await blobCache.hasBlob(sha), isTrue);

      // Stop the server: getBlob must succeed from the local cache,
      // proving the upload populated it.
      await server.stop();
      final fetched = await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
      );
      expect(fetched.data, data);
    });

    test('uploadBlob with cacheWrite:false does not populate the cache',
        () async {
      final result = await blossom.uploadBlob(
        data: bytesOf('upload-no-cache'),
        serverUrls: ['http://localhost:$port'],
        cacheWrite: false,
      );
      final sha = result.first.descriptor!.sha256;
      expect(await blobCache.hasBlob(sha), isFalse);
    });

    test('getBlob with cacheWrite:false fetches but does not cache',
        () async {
      final sha = await uploadAndGetSha('fetch-no-cache');
      expect(await blobCache.hasBlob(sha), isFalse);

      await blossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$port'],
        cacheWrite: false,
      );
      expect(await blobCache.hasBlob(sha), isFalse);
    });

    test('uploadBlob caches even when every server rejects', () async {
      // Local-first: the cache reflects what the user has, regardless
      // of remote outcome. The user can retry the upload later or
      // serve the bytes from their own local store.
      final data = bytesOf('all-fail');
      final result = await blossom.uploadBlob(
        data: data,
        serverUrls: ['http://dead.example.com'],
      );
      expect(result.every((r) => !r.success), isTrue,
          reason: 'sanity: every server should reject');

      final sha = result.first.descriptor?.sha256 ??
          // Failed uploads don't carry a descriptor — recompute the
          // local hash to look the entry up.
          (await blossom.uploadBlob(
            data: data,
            serverUrls: ['http://localhost:$port'],
            cacheWrite: false,
          ))
              .first
              .descriptor!
              .sha256;
      expect(await blobCache.hasBlob(sha), isTrue);
      final fetched = await blobCache.getBlob(sha);
      expect(fetched!.data, data);
    });
  });

  group('NoopBlobCacheManager opt-out', () {
    late MockBlossomServer noopServer;
    late Ndk noopNdk;
    late Blossom noopBlossom;
    const noopPort = 30101;

    setUp(() async {
      noopServer = MockBlossomServer(port: noopPort);
      await noopServer.start();

      final key = Bip340.generatePrivateKey();
      noopNdk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          blobCache: const NoopBlobCacheManager(),
          engine: NdkEngine.JIT,
        ),
      );
      noopNdk.accounts.loginPrivateKey(
        pubkey: key.publicKey,
        privkey: key.privateKey!,
      );
      noopBlossom = noopNdk.blossom;
    });

    tearDown(() async {
      await noopServer.stop();
      await noopNdk.destroy();
    });

    test('every getBlob hits the server, nothing is stored', () async {
      final upload = await noopBlossom.uploadBlob(
        data: bytesOf('never cached'),
        serverUrls: ['http://localhost:$noopPort'],
      );
      final sha = upload.first.descriptor!.sha256;

      // Two successive gets should both reach the server (Noop returns
      // null on every read).
      await noopBlossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$noopPort'],
      );
      await noopBlossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$noopPort'],
      );

      // After stopping the server the third get must fail — no cache
      // to fall back on.
      await noopServer.stop();
      final attempt = noopBlossom.getBlob(
        sha256: sha,
        serverUrls: ['http://localhost:$noopPort'],
      );
      expect(attempt, throwsException);

      // The exposed cache instance reports nothing.
      final exposed = noopNdk.config.blobCache!;
      expect(await exposed.hasBlob(sha), isFalse);
      expect(await exposed.listBlobs(), isEmpty);
      expect(await exposed.getTotalSize(), 0);
    });
  });
}
