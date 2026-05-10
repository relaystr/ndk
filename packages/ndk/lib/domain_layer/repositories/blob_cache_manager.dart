import 'dart:typed_data';

import '../entities/blossom_blobs.dart';

/// Local store for binary blobs, content-addressed by SHA-256.
///
/// Conceptually a *local Blossom server* (without the network layer): the
/// API mirrors the operations a remote Blossom server exposes
/// (save/get/has/list/remove) so cached and remote blobs share the same
/// vocabulary and entities ([BlobDescriptor], [BlobResponse]).
///
/// Differences with a real Blossom server:
/// - no HTTP, no port, no kind 24242 authorization (BUD-11)
/// - single local store: no `serverUrls`, no `pubkey` filter on list
/// - mirror, media optimization, reports and payments are not in scope
/// - [BlobDescriptor.url] of cached entries is empty, or carries the
///   original source URL when the caller passes one
abstract class BlobCacheManager {
  /// Persist a blob keyed by its SHA-256.
  ///
  /// If [sha256] is omitted it is computed from [data]. Pass it when
  /// already known (e.g. right after a Blossom GET) to avoid hashing
  /// twice. The caller is trusted not to lie about a provided hash.
  ///
  /// Re-saving an existing blob updates the descriptor metadata and
  /// keeps the existing bytes.
  Future<BlobDescriptor> saveBlob({
    required Uint8List data,
    String? sha256,
    String? mimeType,
    String? sourceUrl,
    BlobNip94? nip94,
  });

  /// Read a blob by its SHA-256. Returns `null` when absent.
  Future<BlobResponse?> getBlob(String sha256);

  /// True when a blob with this SHA-256 is in the cache.
  Future<bool> hasBlob(String sha256);

  /// Read the descriptor only (no bytes). Returns `null` when absent.
  Future<BlobDescriptor?> getBlobDescriptor(String sha256);

  /// Enumerate every blob currently stored, newest first.
  Future<List<BlobDescriptor>> listBlobs();

  /// Delete a blob by its SHA-256. No-op if absent.
  Future<void> removeBlob(String sha256);

  /// Delete every blob.
  Future<void> removeAllBlobs();

  /// Total size in bytes of all stored blob payloads.
  Future<int> getTotalSize();

  /// Release any underlying resources (db handles, etc.).
  Future<void> close();
}
