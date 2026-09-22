import '../../entities/auth_policy.dart';
import '../../entities/blob_upload_progress.dart';
import '../../entities/blossom_blobs.dart';
import '../../entities/blossom_strategies.dart';
import '../../entities/ndk_file.dart';
import 'blossom.dart';

/// high level usecase to manage files on nostr
class Files {
  final Blossom _blossom;

  /// Regular expression to match SHA256 in URLs
  static final sha256Regex = RegExp(r'/([a-fA-F0-9]{64})(?:/|$)');

  Files({required Blossom blossom}) : _blossom = blossom;

  /// upload a file to the server(s) \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if no serverUrls (param or nostr) are found, throws an error
  /// [serverMediaOptimisation] is whether the server should optimise the media [BUD-05], IMPORTANT: the server hash will be different \
  /// [auth] says which identity the upload may be attributed to, see
  /// [AuthPolicy].
  Future<List<BlobUploadResult>> upload({
    required NdkFile file,
    List<String>? serverUrls,
    bool serverMediaOptimisation = false,
    AuthPolicy? auth,
  }) {
    return _blossom.uploadBlob(
      data: file.data,
      serverUrls: serverUrls,
      contentType: file.mimeType,
      serverMediaOptimisation: serverMediaOptimisation,
      auth: auth,
    );
  }

  /// Upload a file from disk path
  /// For native platforms (Windows, macOS, Linux, Android, iOS): uses actual file system paths
  /// For web: prompts user to select a file using File System Access API (modern browsers)
  ///
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if no serverUrls (param or nostr) are found, throws an error
  /// [serverMediaOptimisation] is whether the server should optimise the media [BUD-05], IMPORTANT: the server hash will be different \
  /// [auth] says which identity the upload may be attributed to, see
  /// [AuthPolicy].
  Stream<BlobUploadProgress> uploadFromFile({
    required String filePath,
    List<String>? serverUrls,
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool serverMediaOptimisation = false,
    AuthPolicy? auth,
  }) {
    return _blossom.uploadBlobFromFile(
      filePath: filePath,
      serverUrls: serverUrls,
      contentType: contentType,
      strategy: strategy,
      serverMediaOptimisation: serverMediaOptimisation,
      auth: auth,
    );
  }

  /// deletes a file from the server(s) \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// [auth] says which identity the deletion may be attributed to, see
  /// [AuthPolicy].
  Future<List<BlobDeleteResult>> delete({
    required String sha256,
    List<String>? serverUrls,
    AuthPolicy? auth,
  }) {
    return _blossom.deleteBlob(
      sha256: sha256,
      serverUrls: serverUrls,
      auth: auth,
    );
  }

  /// download a file from the server(s) \
  /// if its a blossom url (sha256 in url), blossom is used to download \
  /// if its a public url, the file is downloaded directly \
  /// \
  /// [serverUrls] and [pubkey] are used to download from blossom \
  /// if [serverUrls] is null, the userServerList is fetched from nostr (using the pubkey). \
  /// if both [serverUrls] and [pubkey] are null, throws an error.
  /// [auth] says which identity the download may be attributed to, see
  /// [AuthPolicy]. It is ignored for a plain url, which is fetched directly
  /// and never speaks blossom.
  Future<BlobResponse> download({
    required String url,
    List<String>? serverUrls,
    String? pubkey,
    AuthPolicy? auth,
  }) async {
    // Regular expression to match SHA256 in URLs
    final sha256Match = sha256Regex.firstMatch(url);

    if (sha256Match != null) {
      // This is a blossom URL, handle it using blossom protocol
      final sha256 = sha256Match.group(1)!;

      // Try to download using blossom
      return await _blossom.getBlob(
        sha256: sha256,
        serverUrls: serverUrls,
        pubkeyToFetchUserServerList: pubkey,
        auth: auth,
      );
    } else {
      return await _blossom.directDownload(url: Uri.parse(url));
    }
  }

  /// Downloads a file directly to disk path (without loading whole file into memory)
  /// For native platforms (Windows, macOS, Linux, Android, iOS): uses actual file system paths
  /// For web: triggers browser download dialog to save the file
  ///
  /// if its a blossom url (sha256 in url), blossom is used to download \
  /// if its a public url, the file is downloaded directly \
  /// \
  /// [serverUrls] and [pubkey] are used to download from blossom \
  /// if [serverUrls] is null, the userServerList is fetched from nostr (using the pubkey). \
  /// if both [serverUrls] and [pubkey] are null, throws an error.
  /// [auth] says which identity the download may be attributed to, see
  /// [AuthPolicy]. It is ignored for a plain url, which is fetched directly
  /// and never speaks blossom.
  Future<void> downloadToFile({
    required String url,
    required String outputPath,
    AuthPolicy? auth,
    @Deprecated(
      'Use auth instead. useAuth will be removed in a future version.',
    )
    bool? useAuth,
    List<String>? serverUrls,
    String? pubkey,
  }) async {
    // Regular expression to match SHA256 in URLs
    final sha256Match = sha256Regex.firstMatch(url);

    if (sha256Match != null) {
      // This is a blossom URL, handle it using blossom protocol
      final sha256 = sha256Match.group(1)!;

      // Download using blossom to file
      return await _blossom.downloadBlobToFile(
        sha256: sha256,
        outputPath: outputPath,
        auth: auth,
        // ignore: deprecated_member_use_from_same_package
        useAuth: useAuth,
        serverUrls: serverUrls,
        pubkeyToFetchUserServerList: pubkey,
      );
    } else {
      // Direct download for non-blossom URLs
      return await _blossom.directDownloadToFile(
        url: Uri.parse(url),
        outputPath: outputPath,
      );
    }
  }

  /// checks if a url is a blossom url. \
  /// it its not a blossom url, the url is returned. \
  /// if its a blossom url, blossom is used to check if the blob exists on the server(s) \
  /// returns alive url if the blob exists, throws an error if the blob does not exist
  /// [auth] says which identity the check may be attributed to, see
  /// [AuthPolicy]. It is ignored for a plain url, which is returned as is.
  Future<String> checkUrl({
    required String url,
    List<String>? serverUrls,
    String? pubkey,
    AuthPolicy? auth,
  }) async {
    // Regular expression to match SHA256 in URLs
    final sha256Match = sha256Regex.firstMatch(url);

    if (sha256Match != null) {
      // This is a blossom URL, handle it using blossom protocol
      final sha256 = sha256Match.group(1)!;

      // Try to check using blossom
      return await _blossom.checkBlob(
        sha256: sha256,
        serverUrls: serverUrls,
        pubkeyToFetchUserServerList: pubkey,
        auth: auth,
      );
    } else {
      return url;
    }
  }
}
