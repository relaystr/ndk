import 'package:ndk/domain_layer/entities/blossom_strategies.dart';

import '../../data_layer/repositories/blossom/blossom_impl.dart';
import '../entities/blossom_blobs.dart';
import '../entities/nip_01_event.dart';
import '../entities/tuple.dart';

abstract class BlossomRepository {
  /// Uploads a blob using the specified strategy
  /// Returns a stream of progress updates
  Stream<BlobUploadProgress> uploadBlob({
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    required Nip01Event authorization,
    String? contentType,
    required List<String> serverUrls,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool mediaOptimisation = false,
  });

  /// Uploads a blob from a file path using the specified strategy
  /// Reads the file in chunks to minimize memory usage
  /// For web: prompts user to select a file via File System Access API
  /// For native: filePath is the actual file system path
  /// Returns a stream of progress updates
  Stream<BlobUploadProgress> uploadBlobFromFile({
    required String filePath,
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

  /// Downloads a blob directly to a file path
  /// For web: triggers browser download dialog with the file
  /// For native: saves to the file system at the given path
  Future<void> downloadBlobToFile({
    required String sha256,
    required String outputPath,
    required List<String> serverUrls,
    Nip01Event? authorization,
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

  /// Directly downloads a blob from the url to a file, without blossom
  Future<void> directDownloadToFile({
    required Uri url,
    required String outputPath,
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

  /// Mirrors a blob from one server to another using the /mirror endpoint
  /// [fileUrl] is the source URL where the blob exists
  /// [serverUrl] is the target server to mirror to
  /// [sha256] is the hash of the blob
  /// [authorization] is the signed authorization event
  Future<BlobUploadResult> mirrorToServer({
    required String fileUrl,
    required String serverUrl,
    required String sha256,
    required Nip01Event authorization,
  });

  /// Computes SHA256 hash of a file by reading it in chunks
  /// Returns the hash as a hex string without loading the entire file into memory
  Future<String> computeFileHash(String filePath);
}
