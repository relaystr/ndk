import '../../entities/blossom_blobs.dart';
import '../../entities/ndk_file.dart';
import 'blossom.dart';

/// high level usecase to manage files on nostr
class Files {
  final Blossom blossom;

  /// Regular expression to match SHA256 in URLs
  static final sha256Regex = RegExp(r'/([a-fA-F0-9]{64})(?:/|$)');

  Files(this.blossom);

  /// upload a file to the server(s) \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if no serverUrls (param or nostr) are found, throws an error
  Future<List<BlobUploadResult>> upload(
    NdkFile file,
    List<String>? serverUrls,
  ) {
    return blossom.uploadBlob(
      data: file.data,
      serverUrls: serverUrls,
      contentType: file.mimeType,
    );
  }

  /// deletes a file from the server(s) \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  Future<List<BlobDeleteResult>> delete({
    required String sha256,
    List<String>? serverUrls,
  }) {
    return blossom.deleteBlob(
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
  Future<BlobResponse> download(
    String url,
    List<String>? serverUrls,
    String? pubkey,
  ) async {
    // Regular expression to match SHA256 in URLs
    final sha256Match = sha256Regex.firstMatch(url);

    if (sha256Match != null) {
      // This is a blossom URL, handle it using blossom protocol
      final sha256 = sha256Match.group(1)!;

      // Try to download using blossom
      return await blossom.getBlob(
          sha256: sha256,
          serverUrls: serverUrls,
          pubkeyToFetchUserServerList: pubkey);
    } else {
      return await blossom.directDownload(url: Uri.parse(url));
    }
  }
}
