import '../../entities/blossom_blobs.dart';
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
  Future<List<BlobUploadResult>> upload({
    required NdkFile file,
    List<String>? serverUrls,
    bool serverMediaOptimisation = false,
  }) {
    return _blossom.uploadBlob(
      data: file.data,
      serverUrls: serverUrls,
      contentType: file.mimeType,
      serverMediaOptimisation: serverMediaOptimisation,
    );
  }

  /// deletes a file from the server(s) \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  Future<List<BlobDeleteResult>> delete({
    required String sha256,
    List<String>? serverUrls,
  }) {
    return _blossom.deleteBlob(
      sha256: sha256,
      serverUrls: serverUrls,
    );
  }

  /// download a file from the server(s) \
  /// if its a blossom url (sha256 in url), blossom is used to download \
  /// if its a public url, the file is downloaded directly \
  /// \
  /// [serverUrls] and [pubkey] are used to download from blossom \
  /// if [serverUrls] is null, the userServerList is fetched from nostr (using the pubkey). \
  /// if both [serverUrls] and [pubkey] are null, throws an error.
  Future<BlobResponse> download({
    required String url,
    List<String>? serverUrls,
    String? pubkey,
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
          pubkeyToFetchUserServerList: pubkey);
    } else {
      return await _blossom.directDownload(url: Uri.parse(url));
    }
  }

  /// checks if a url is a blossom url. \
  /// it its not a blossom url, the url is returned. \
  /// if its a blossom url, blossom is used to check if the blob exists on the server(s) \
  /// returns alive url if the blob exists, throws an error if the blob does not exist
  Future<String> checkUrl({
    required String url,
    List<String>? serverUrls,
    String? pubkey,
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
      );
    } else {
      return url;
    }
  }
}
