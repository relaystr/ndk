import 'dart:typed_data';

import '../../repositories/blossom.dart';

/// direct access usecase to blossom \
/// use files usecase for a more convinent way to manage files
class Blossom {
  final BlossomRepository repository;

  Blossom(this.repository);

  Future<List<BlobUploadResult>> uploadBlob({
    required Uint8List data,
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
  }) {
    return repository.uploadBlob(
      data,
      contentType: contentType,
      strategy: strategy,
    );
  }

  Future<Uint8List> getBlob(String sha256) {
    return repository.getBlob(sha256);
  }

  Future<List<BlobDescriptor>> listBlobs(
    String pubkey, {
    DateTime? since,
    DateTime? until,
  }) {
    return repository.listBlobs(pubkey, since: since, until: until);
  }

  Future<void> delteBlob(String sha256) {
    return repository.deleteBlob(sha256);
  }
}
