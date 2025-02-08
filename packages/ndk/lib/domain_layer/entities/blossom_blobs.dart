import 'dart:typed_data';

/// Descriptor of a blob - when getting a blob from a server
class BlobDescriptor {
  /// server url e.g. https://example.com/<sha256>
  final String url;

  /// SHA-256 hexencoded string of the file
  final String sha256;

  /// size of file in bytes
  final int? size;

  /// mime type of the file
  final String? type;

  /// time of upload
  final DateTime uploaded;

  /// NIP-94 metadata
  final BlobNip94? nip94;

  BlobDescriptor({
    required this.url,
    required this.sha256,
    required this.size,
    required this.uploaded,
    this.type,
    this.nip94,
  });

  /// converts json response to BlobDescriptor
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

/// Result of a blob upload
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

/// Result of a blob delete
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

/// Response of a blob download
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
  ///? required fields can be empty!

  /// the content of nostr event
  final String content;

  /// the url to download the file
  final String url;

  /// a string indicating the data type of the file.
  final String mimeType;

  /// SHA-256 hexencoded string of the file
  final String sha256;

  /// SHA-256 hexencoded string of the original file
  final String originalsha256;

  /// size of file in bytes
  final int? size;

  /// size of file in pixels in the form <width>x<height>
  final int? dimenssions;

  /// URI to torrent magnet
  final String? magnet;

  /// torrent infohash
  final String? torrentInfoHash;

  /// the blurhash to show while the file is being loaded by the client
  final String? blurhash;

  /// ["thumb", <string with thumbnail URI>, <Hash SHA-256>]
  final List<String>? thumbnail;

  /// ["image", <string with preview URI>, <Hash SHA-256>]
  final List<String>? image;

  /// text excerpt
  final String? summary;

  /// description for accessibility
  final String? alt;

  /// zero or more fallback file sources in case url fails
  final String? fallback;

  /// service type which is serving the file (eg. NIP-96)
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

  /// converts json response to BlobNip94, \
  ///  does not work with nostr events! (tags)
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
