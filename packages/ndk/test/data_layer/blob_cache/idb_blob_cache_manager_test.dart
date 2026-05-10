import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:idb_shim/idb_client_memory.dart';
import 'package:ndk/data_layer/repositories/blob_cache/idb_blob_cache_manager.dart';
import 'package:ndk/domain_layer/entities/blossom_blobs.dart';
import 'package:ndk/domain_layer/repositories/blob_cache_manager.dart';
import 'package:test/test.dart';

void main() {
  late BlobCacheManager cache;

  setUp(() {
    // Fresh in-memory factory per test → isolated db.
    cache = IdbBlobCacheManager(factory: newIdbFactoryMemory());
  });

  tearDown(() async {
    await cache.close();
  });

  Uint8List bytes(String s) => Uint8List.fromList(s.codeUnits);
  String hashOf(Uint8List data) => crypto.sha256.convert(data).toString();

  group('saveBlob', () {
    test('computes sha256 from data when not provided', () async {
      final data = bytes('hello blob');
      final descriptor = await cache.saveBlob(data: data);
      expect(descriptor.sha256, hashOf(data));
      expect(descriptor.size, data.length);
      expect(descriptor.url, '');
      expect(descriptor.type, isNull);
    });

    test('uses provided sha256 without recomputing', () async {
      final data = bytes('hello blob');
      // Pass an arbitrary "sha256" — the cache trusts the caller.
      final descriptor =
          await cache.saveBlob(data: data, sha256: 'trusted-key');
      expect(descriptor.sha256, 'trusted-key');
    });

    test('round-trips mime type, source url and nip94', () async {
      final data = bytes('payload');
      final nip94 = BlobNip94(
        content: '',
        url: 'https://cdn.example.com/x',
        mimeType: 'image/png',
        sha256: 'aaaa',
        size: data.length,
        dimensions: '100x100',
      );
      await cache.saveBlob(
        data: data,
        mimeType: 'image/png',
        sourceUrl: 'https://cdn.example.com/x',
        nip94: nip94,
      );
      final descriptor = await cache.getBlobDescriptor(hashOf(data));
      expect(descriptor, isNotNull);
      expect(descriptor!.type, 'image/png');
      expect(descriptor.url, 'https://cdn.example.com/x');
      expect(descriptor.nip94, isNotNull);
      expect(descriptor.nip94!.dimensions, '100x100');
    });

    test('overwrites an existing blob with the same sha256', () async {
      final hash = 'reused-key';
      await cache.saveBlob(data: bytes('first'), sha256: hash);
      await cache.saveBlob(
        data: bytes('second'),
        sha256: hash,
        mimeType: 'text/plain',
      );
      final response = await cache.getBlob(hash);
      expect(response, isNotNull);
      expect(response!.data, bytes('second'));
      expect(response.mimeType, 'text/plain');
    });
  });

  group('getBlob / hasBlob / getBlobDescriptor', () {
    test('returns null / false when absent', () async {
      expect(await cache.getBlob('missing'), isNull);
      expect(await cache.hasBlob('missing'), isFalse);
      expect(await cache.getBlobDescriptor('missing'), isNull);
    });

    test('returns the persisted bytes on hit', () async {
      final data = bytes('contents');
      final hash = hashOf(data);
      await cache.saveBlob(data: data, mimeType: 'text/plain');
      final response = await cache.getBlob(hash);
      expect(response, isNotNull);
      expect(response!.data, data);
      expect(response.contentLength, data.length);
      expect(response.mimeType, 'text/plain');
      expect(await cache.hasBlob(hash), isTrue);
    });
  });

  group('listBlobs', () {
    test('returns an empty list when the cache is empty', () async {
      expect(await cache.listBlobs(), isEmpty);
    });

    test('returns all stored descriptors, newest first', () async {
      await cache.saveBlob(data: bytes('first'), sha256: 'a');
      // Wait > 1s so the unix-second timestamp differs (BlobDescriptor
      // serialises `uploaded` to seconds, dropping sub-second precision).
      await Future.delayed(const Duration(milliseconds: 1100));
      await cache.saveBlob(data: bytes('second'), sha256: 'b');
      final list = await cache.listBlobs();
      expect(list.map((d) => d.sha256).toList(), ['b', 'a']);
    });
  });

  group('removeBlob / removeAllBlobs', () {
    test('removeBlob is a no-op when the blob is absent', () async {
      await cache.removeBlob('missing');
      expect(await cache.listBlobs(), isEmpty);
    });

    test('removeBlob removes both bytes and descriptor', () async {
      final data = bytes('to-be-removed');
      final hash = hashOf(data);
      await cache.saveBlob(data: data);
      await cache.removeBlob(hash);
      expect(await cache.hasBlob(hash), isFalse);
      expect(await cache.getBlob(hash), isNull);
      expect(await cache.getBlobDescriptor(hash), isNull);
    });

    test('removeAllBlobs empties the store', () async {
      await cache.saveBlob(data: bytes('a'), sha256: '1');
      await cache.saveBlob(data: bytes('b'), sha256: '2');
      await cache.removeAllBlobs();
      expect(await cache.listBlobs(), isEmpty);
      expect(await cache.getTotalSize(), 0);
    });
  });

  group('getTotalSize', () {
    test('returns 0 when the cache is empty', () async {
      expect(await cache.getTotalSize(), 0);
    });

    test('sums the size of every stored blob', () async {
      await cache.saveBlob(data: bytes('aaa'), sha256: '1');
      await cache.saveBlob(data: bytes('bbbb'), sha256: '2');
      expect(await cache.getTotalSize(), 7);
    });
  });

  test('separate IdbBlobCacheManager instances have isolated stores', () async {
    // Each `newIdbFactoryMemory()` returns a fresh memory db.
    final a = IdbBlobCacheManager(factory: newIdbFactoryMemory());
    final b = IdbBlobCacheManager(factory: newIdbFactoryMemory());
    addTearDown(() async {
      await a.close();
      await b.close();
    });

    await a.saveBlob(data: bytes('only-in-a'), sha256: 'x');
    expect(await a.hasBlob('x'), isTrue);
    expect(await b.hasBlob('x'), isFalse);
  });
}
