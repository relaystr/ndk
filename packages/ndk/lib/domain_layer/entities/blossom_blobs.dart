import 'dart:typed_data';

class BlobDescriptor {
  final String url;
  final String sha256;
  final int size;
  final String? type;
  final DateTime uploaded;

  BlobDescriptor({
    required this.url,
    required this.sha256,
    required this.size,
    this.type,
    required this.uploaded,
  });

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

class BlossomBlobResponse {
  final Uint8List data;
  final String? mimeType;
  final int? contentLength;
  final String? contentRange;

  BlossomBlobResponse({
    required this.data,
    this.mimeType,
    this.contentLength,
    this.contentRange,
  });
}
