import 'dart:typed_data';

import '../../repositories/blossom.dart';

class Files {
  final BlossomRepository repository;

  Files(this.repository);

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

// lib/domain/usecases/delete_blob_usecase.dart

  Future<void> delteBlob(String sha256) {
    return repository.deleteBlob(sha256);
  }
}
