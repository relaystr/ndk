import 'dart:typed_data';

enum UploadStrategy {
  /// Upload to first server, then mirror to others
  mirrorAfterSuccess,

  /// Upload to all servers simultaneously
  allSimultaneous,

  /// Upload to first successful server only
  firstSuccess
}

abstract class BlossomRepository {
  /// Uploads a blob using the specified strategy
  Future<List<BlobUploadResult>> uploadBlob(
    Uint8List data, {
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
  });

  /// Gets a blob by trying servers sequentially until success
  Future<Uint8List> getBlob(String sha256);

  /// Lists blobs from the first successful server
  Future<List<BlobDescriptor>> listBlobs(String pubkey,
      {DateTime? since, DateTime? until});

  /// Attempts to delete blob from all servers
  Future<List<BlobDeleteResult>> deleteBlob(String sha256);
}

class BlobDescriptor {
  final String url;
  final String sha256;
  final int size;
  final String? type;
  final DateTime uploaded;

  BlobDescriptor(
      {required this.url,
      required this.sha256,
      required this.size,
      this.type,
      required this.uploaded});

  factory BlobDescriptor.fromJson(Map<String, dynamic> json) {
    return BlobDescriptor(
        url: json['url'],
        sha256: json['sha256'],
        size: json['size'],
        type: json['type'],
        uploaded: DateTime.fromMillisecondsSinceEpoch(json['uploaded'] * 1000));
  }
}

class BlobUploadResult {
  final String serverUrl;
  final bool success;
  final BlobDescriptor? descriptor;
  final String? error;

  BlobUploadResult({
    required this.serverUrl,
    required this.success,
    this.descriptor,
    this.error,
  });
}

class BlobDeleteResult {
  final String serverUrl;
  final bool success;
  final String? error;

  BlobDeleteResult({
    required this.serverUrl,
    required this.success,
    this.error,
  });
}
