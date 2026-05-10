import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../../domain_layer/entities/blossom_blobs.dart';
import '../../../domain_layer/repositories/blob_cache_manager.dart';

/// A [BlobCacheManager] that never stores anything.
///
/// Useful when caching must be opted out entirely:
/// - tests asserting per-server behaviour
/// - memory- or storage-constrained environments
/// - debugging / always-fetch flows
///
/// `saveBlob` returns a descriptor for caller convenience but discards
/// the bytes; every subsequent read returns the empty / absent state.
class NoopBlobCacheManager implements BlobCacheManager {
  const NoopBlobCacheManager();

  @override
  Future<BlobDescriptor> saveBlob({
    required Uint8List data,
    String? sha256,
    String? mimeType,
    String? sourceUrl,
    BlobNip94? nip94,
  }) async {
    final hash = sha256 ?? crypto.sha256.convert(data).toString();
    return BlobDescriptor(
      url: sourceUrl ?? '',
      sha256: hash,
      size: data.length,
      type: mimeType,
      uploaded: DateTime.now(),
      nip94: nip94,
    );
  }

  @override
  Future<BlobResponse?> getBlob(String sha256) async => null;

  @override
  Future<bool> hasBlob(String sha256) async => false;

  @override
  Future<BlobDescriptor?> getBlobDescriptor(String sha256) async => null;

  @override
  Future<List<BlobDescriptor>> listBlobs() async => const [];

  @override
  Future<void> removeBlob(String sha256) async {}

  @override
  Future<void> removeAllBlobs() async {}

  @override
  Future<int> getTotalSize() async => 0;

  @override
  Future<void> close() async {}
}
