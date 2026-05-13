import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:ndk/data_layer/repositories/blob_cache/noop_blob_cache_manager.dart';
import 'package:test/test.dart';

void main() {
  const cache = NoopBlobCacheManager();

  Uint8List bytes(String s) => Uint8List.fromList(s.codeUnits);

  test('saveBlob computes the descriptor but discards the data', () async {
    final data = bytes('payload');
    final descriptor = await cache.saveBlob(
      data: data,
      mimeType: 'text/plain',
      sourceUrl: 'https://cdn.example.com/x',
    );
    expect(descriptor.sha256, crypto.sha256.convert(data).toString());
    expect(descriptor.size, data.length);
    expect(descriptor.type, 'text/plain');
    expect(descriptor.url, 'https://cdn.example.com/x');

    // Despite saveBlob succeeding, nothing is stored.
    expect(await cache.hasBlob(descriptor.sha256), isFalse);
    expect(await cache.getBlob(descriptor.sha256), isNull);
    expect(await cache.getBlobDescriptor(descriptor.sha256), isNull);
  });

  test('saveBlob honours an explicit sha256', () async {
    final descriptor =
        await cache.saveBlob(data: bytes('x'), sha256: 'forced-key');
    expect(descriptor.sha256, 'forced-key');
  });

  test('every read returns the empty / absent state', () async {
    expect(await cache.getBlob('any'), isNull);
    expect(await cache.hasBlob('any'), isFalse);
    expect(await cache.getBlobDescriptor('any'), isNull);
    expect(await cache.listBlobs(), isEmpty);
    expect(await cache.getTotalSize(), 0);
  });

  test('remove operations are no-ops and never throw', () async {
    await cache.removeBlob('missing');
    await cache.removeAllBlobs();
    expect(await cache.listBlobs(), isEmpty);
  });

  test('close is a no-op', () async {
    await cache.close();
    // Still usable after close.
    expect(await cache.hasBlob('x'), isFalse);
  });
}
