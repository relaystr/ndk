import 'dart:typed_data';

import '../entities/blossom_blobs.dart';
import '../entities/nip_01_event.dart';
import '../entities/tuple.dart';

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
  Future<List<BlobUploadResult>> uploadBlob({
    required Uint8List data,
    required Nip01Event authorization,
    String? contentType,
    required List<String> serverUrls,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool mediaOptimisation = false,
  });

  /// Gets a blob by trying servers sequentially until success
  /// If [authorization] is null, the server must be public
  /// If [start] and [end] are null, the entire blob is returned
  /// [start] and [end] are used to download a range of bytes, @see MDN HTTP range requests
  Future<BlobResponse> getBlob({
    required String sha256,
    required List<String> serverUrls,
    Nip01Event? authorization,
    int? start,
    int? end,
  });

  /// Checks if the blob exists on the server
  /// If [authorization] is null, the server must be public
  ///
  /// returns one server that has the blob
  Future<String> checkBlob({
    required String sha256,
    required List<String> serverUrls,
    Nip01Event? authorization,
  });

  /// Directly downloads a blob from the url, without blossom
  Future<BlobResponse> directDownload({
    required Uri url,
  });

  /// checks if the server supports range requests, if no server supports range requests, the entire blob is returned
  /// otherwise, the blob is returned in chunks. @see MDN HTTP range requests
  Future<Stream<BlobResponse>> getBlobStream({
    required String sha256,
    required List<String> serverUrls,
    Nip01Event? authorization,
    int chunkSize = 1024 * 1024, // 1MB chunks
  });

  /// Checks if the server supports range requests and gets the content length \
  /// first value is whether the server supports range requests \
  /// second value is the content length of the blob in bytes
  Future<Tuple<bool, int?>> supportsRangeRequests({
    required String sha256,
    required String serverUrl,
  });

  /// Lists blobs from the first successful server
  Future<List<BlobDescriptor>> listBlobs({
    required String pubkey,
    required List<String> serverUrls,
    DateTime? since,
    DateTime? until,
    Nip01Event? authorization,
  });

  /// Attempts to delete blob from all servers
  Future<List<BlobDeleteResult>> deleteBlob({
    required String sha256,
    required List<String> serverUrls,
    required Nip01Event authorization,
  });

  /// Reports a blob to the server \
  /// [sha256] is the hash of the blob \
  /// [reportEvent] is the report event
  ///
  /// returns the http status code of the rcv server
  Future<int> report({
    required String sha256,
    required Nip01Event reportEvent,
    required String serverUrl,
  });
}
