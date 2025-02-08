import 'dart:typed_data';

class BlobDescriptor {
  final String url;
  final String sha256;
  final int? size;
  final String? type;
  final DateTime uploaded;
  final BlobNip94? nip94;

  BlobDescriptor({
    required this.url,
    required this.sha256,
    required this.size,
    required this.uploaded,
    this.type,
    this.nip94,
  });

  factory BlobDescriptor.fromJson(Map<String, dynamic> json) {
    return BlobDescriptor(
      url: json['url'] ?? '',
      sha256: json['sha256'] ?? '',
      size: json['size'],
      type: json['type'],
      uploaded: json['uploaded'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['uploaded'] * 1000)
          : DateTime.now(),
      nip94: json['nip94'] != null ? BlobNip94.fromJson(json['nip94']) : null,
    );
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

class BlobResponse {
  final Uint8List data;
  final String? mimeType;
  final int? contentLength;
  final String? contentRange;

  BlobResponse({
    required this.data,
    this.mimeType,
    this.contentLength,
    this.contentRange,
  });
}

/// BUD-08 \
/// is BlobNip94 because fromJson does not work with nostr events, only blobDescriptor!
class BlobNip94 {
  final String content;
  final String url;
  final String mimeType;
  final String sha256;
  final String originalsha256;
  final int? size;
  final int? dimenssions;
  final String? magnet;
  final String? torrentInfoHash;
  final String? blurhash;

  /// ["thumb", <string with thumbnail URI>, <Hash SHA-256>]
  final List<String>? thumbnail;

  /// ["image", <string with preview URI>, <Hash SHA-256>]
  final List<String>? image;

  final String? summary;
  final String? alt;
  final String? fallback;
  final String? service;

  BlobNip94({
    required this.content,
    required this.url,
    required this.mimeType,
    required this.sha256,
    required this.originalsha256,
    required this.size,
    this.magnet,
    this.torrentInfoHash,
    this.blurhash,
    this.thumbnail,
    this.image,
    this.summary,
    this.alt,
    this.fallback,
    this.service,
    this.dimenssions,
  });

  factory BlobNip94.fromJson(Map<String, dynamic> json) {
    return BlobNip94(
      //? servers can't be trusted
      content: json['content'] ?? '',
      url: json['url'] ?? '',
      mimeType: json['m'] ?? '',
      sha256: json['x'] ?? '',
      originalsha256: json['ox'] ?? '',
      size: json['size'] ?? 0,
      dimenssions: json['dim'],
      magnet: json['magnet'],
      torrentInfoHash: json['i'],
      blurhash: json['blurhash'],
      thumbnail: json['thumb'],
      image: json['image'],
      summary: json['summary'],
      alt: json['alt'],
      fallback: json['fallback'],
      service: json['service'],
    );
  }
}
