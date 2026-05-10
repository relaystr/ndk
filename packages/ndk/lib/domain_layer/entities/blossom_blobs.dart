import 'dart:typed_data';

int? _parseSize(dynamic size) {
  if (size is int) return size;
  if (size is String) return int.tryParse(size);
  return null;
}

/// Descriptor of a blob - when getting a blob from a server
class BlobDescriptor {
  /// server url e.g. https://example.com/&lt;sha256&gt;
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
      size: _parseSize(json['size']),
      type: json['type'],
      uploaded: json['uploaded'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['uploaded'] * 1000)
          : DateTime.now(),
      nip94: json['nip94'] != null ? BlobNip94.fromJson(json['nip94']) : null,
    );
  }

  /// Inverse of [BlobDescriptor.fromJson]. `uploaded` is encoded as a
  /// Unix timestamp in seconds to match the server-side BUD-02 format.
  Map<String, dynamic> toJson() => {
        'url': url,
        'sha256': sha256,
        'size': size,
        'type': type,
        'uploaded': uploaded.millisecondsSinceEpoch ~/ 1000,
        'nip94': nip94?.toJson(),
      };
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

  /// size of file in bytes
  final int? size;

  /// size of file in pixels as String in the form &lt;width&gt;x&lt;height&gt;
  final String? dimensions;

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
  final List<String>? fallback;

  /// service type which is serving the file (eg. NIP-96)
  final String? service;

  BlobNip94({
    required this.content,
    required this.url,
    required this.mimeType,
    required this.sha256,
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
    this.dimensions,
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
      // parse int from string
      size: _parseSize(json['size']),
      dimensions: json['dim']?.toString(),
      magnet: json['magnet'],
      torrentInfoHash: json['i'],
      blurhash: json['blurhash'],
      thumbnail: json['thumb'] != null ? [json['thumb'] as String] : null,
      image: json['image'] != null ? [json['image'] as String] : null,
      summary: json['summary'],
      alt: json['alt'],
      fallback: json['fallback'] != null ? [json['fallback'] as String] : null,
      service: json['service'],
    );
  }

  /// Inverse of [BlobNip94.fromJson]. Uses BUD-08 / NIP-94 short tag
  /// keys (`m`, `x`, `i`, `dim`, ...). `thumbnail`, `image` and
  /// `fallback` are encoded as a single string (their first element)
  /// since [BlobNip94.fromJson] only consumes one.
  Map<String, dynamic> toJson() => {
        'content': content,
        'url': url,
        'm': mimeType,
        'x': sha256,
        'size': size,
        'dim': dimensions,
        'magnet': magnet,
        'i': torrentInfoHash,
        'blurhash': blurhash,
        'thumb': (thumbnail != null && thumbnail!.isNotEmpty)
            ? thumbnail!.first
            : null,
        'image':
            (image != null && image!.isNotEmpty) ? image!.first : null,
        'summary': summary,
        'alt': alt,
        'fallback': (fallback != null && fallback!.isNotEmpty)
            ? fallback!.first
            : null,
        'service': service,
      };
}
