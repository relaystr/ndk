import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../../config/blossom_config.dart';
import '../../../data_layer/repositories/blossom/blossom_impl.dart';
import '../../entities/blossom_blobs.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_01_utils.dart';
import '../../repositories/blossom.dart';
import '../../repositories/event_signer.dart';
import '../accounts/accounts.dart';
import 'blossom_user_server_list.dart';

/// direct access usecase to blossom \
/// use files usecase for a more convinent way to manage files
class Blossom {
  /// kind for all most of blossom
  static const kBlossom = 24242;

  /// kind for reports NIP56
  static const int kReport = 1984;

  /// kind for blossom user server list
  static const kBlossomUserServerList = 10063;

  /// Regular expression to match SHA256 in URLs
  static final sha256Regex = RegExp(r'/([a-fA-F0-9]{64})(?:/|$)');

  final BlossomUserServerList _userServerList;
  final BlossomRepository _blossomImpl;
  final Accounts _accounts;

  Blossom({
    required BlossomUserServerList blossomUserServerList,
    required BlossomRepository blossomRepository,
    required Accounts accounts,
  })  : _accounts = accounts,
        _userServerList = blossomUserServerList,
        _blossomImpl = blossomRepository;

  void _checkSigner() {
    if (!_accounts.canSign) {
      throw "Not logged in";
    }
  }

  EventSigner get _signer {
    return _accounts.getLoggedAccount()!.signer;
  }

  /// upload a blob to the server
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error \
  /// the current signer is used to sign the request \
  /// [strategy] is the upload strategy, default is mirrorAfterSuccess \
  /// [serverMediaOptimisation] is whether the server should optimise the media [BUD-05], IMPORTANT: the server hash will be different \
  Future<List<BlobUploadResult>> uploadBlob({
    required Uint8List data,
    List<String>? serverUrls,
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool serverMediaOptimisation = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    /// sha256 of the data
    final dataSha256 = sha256.convert(data);

    _checkSigner();

    final Nip01Event myAuthorization = Nip01Event(
      content: "upload",
      pubKey: _signer.getPublicKey(),
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", "upload"],
        ["x", dataSha256.toString()],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
      ],
    );

    final signedAuthorization = await _signer.sign(myAuthorization);

    serverUrls ??= await _userServerList
        .getUserServerList(pubkeys: [_signer.getPublicKey()]);

    if (serverUrls == null) {
      throw Exception("User has no server list");
    }

    final stream = _blossomImpl.uploadBlob(
      dataStreamFactory: () => Stream.value(data),
      contentLength: data.length,
      serverUrls: serverUrls,
      authorization: signedAuthorization,
      contentType: contentType,
      strategy: strategy,
      mediaOptimisation: serverMediaOptimisation,
    );

    final done = await stream.last;

    return done.completedUploads;
  }

  /// Upload a blob from a file path
  /// For native platforms (Windows, macOS, Linux, Android, iOS): uses actual file system paths
  /// For web: prompts user to select a file using File System Access API (modern browsers)
  ///
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pubkey has no UserServerList (kind: 10063), throws an error \
  /// the current signer is used to sign the request \
  /// [strategy] is the upload strategy, default is mirrorAfterSuccess \
  /// [serverMediaOptimisation] is whether the server should optimise the media [BUD-05], IMPORTANT: the server hash will be different
  Stream<BlobUploadProgress> uploadBlobFromFile({
    required String filePath,
    List<String>? serverUrls,
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool serverMediaOptimisation = false,
  }) async* {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    _checkSigner();

    // Create authorization event (we'll need to read file to compute hash)
    // For now, we create a generic upload authorization
    final Nip01Event myAuthorization = Nip01Utils.createEventCalculateId(
      content: "upload",
      pubKey: _signer.getPublicKey(),
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", "upload"],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
      ],
    );

    final signedAuthorization = await _signer.sign(myAuthorization);

    serverUrls ??= await _userServerList
        .getUserServerList(pubkeys: [_signer.getPublicKey()]);

    if (serverUrls == null) {
      throw Exception("User has no server list");
    }

    yield* _blossomImpl.uploadBlobFromFile(
      filePath: filePath,
      serverUrls: serverUrls,
      authorization: signedAuthorization,
      contentType: contentType,
      strategy: strategy,
      mediaOptimisation: serverMediaOptimisation,
    );
  }

  /// Mirror a blob from a blossom URL to specified servers using the blossom /mirror endpoint
  ///
  /// [blossomUrl] is the source URL of the blob to mirror (e.g., https://cdn.example.com/sha265.jpg)
  ///   The URL must contain a 64-character SHA256 hash
  /// [targetServerUrls] is the list of servers to mirror the blob to
  /// the current signer is used to sign the mirror request
  ///
  /// Throws an [Exception] if no SHA256 hash is detected in the URL
  Future<List<BlobUploadResult>> mirrorToServers({
    required Uri blossomUrl,
    required List<String> targetServerUrls,
  }) async {
    _checkSigner();

    // Extract sha256 from the URL
    final sha256Match = sha256Regex.firstMatch(blossomUrl.toString());
    if (sha256Match == null) {
      throw Exception(
        "No SHA256 hash detected in URL: ${blossomUrl.toString()}",
      );
    }

    final sha256 = sha256Match.group(1)!;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Create authorization event for mirroring
    final Nip01Event myAuthorization = Nip01Utils.createEventCalculateId(
      content: "upload",
      pubKey: _signer.getPublicKey(),
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", "upload"],
        ["x", sha256],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
      ],
    );

    final signedAuthorization = await _signer.sign(myAuthorization);

    // Mirror to all target servers
    final results = await Future.wait(
      targetServerUrls.map(
        (serverUrl) => _blossomImpl.mirrorToServer(
          fileUrl: blossomUrl.toString(),
          serverUrl: serverUrl,
          sha256: sha256,
          authorization: signedAuthorization,
        ),
      ),
    );

    return results;
  }

  /// Gets a blob by trying servers sequentially until success (fallback) \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  Future<BlobResponse> getBlob({
    required String sha256,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
  }) async {
    Nip01Event? myAuthorization;
    Nip01Event? signedAuthorization;

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "get",
        pubKey: _signer.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "get"],
          ["x", sha256],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      signedAuthorization = await _signer.sign(myAuthorization);
    }

    if (serverUrls == null) {
      if (pubkeyToFetchUserServerList == null) {
        throw Exception(
            "pubkeyToFetchUserServerList is null and serverUrls is null");
      }

      serverUrls ??= await _userServerList
          .getUserServerList(pubkeys: [pubkeyToFetchUserServerList]);
    }

    if (serverUrls == null) {
      throw Exception("User has no server list");
    }

    return _blossomImpl.getBlob(
      sha256: sha256,
      authorization: signedAuthorization,
      serverUrls: serverUrls,
    );
  }

  /// Downloads a blob directly to a file path (without loading into memory)
  /// For native platforms (Windows, macOS, Linux, Android, iOS): uses actual file system paths
  /// For web: triggers browser download dialog to save the file
  ///
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pubkey has no UserServerList (kind: 10063), throws an error
  Future<void> downloadBlobToFile({
    required String sha256,
    required String outputPath,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
  }) async {
    Nip01Event? myAuthorization;
    Nip01Event? signedAuthorization;

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Utils.createEventCalculateId(
        content: "get",
        pubKey: _signer.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "get"],
          ["x", sha256],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      signedAuthorization = await _signer.sign(myAuthorization);
    }

    if (serverUrls == null) {
      if (pubkeyToFetchUserServerList == null) {
        throw Exception(
            "pubkeyToFetchUserServerList is null and serverUrls is null");
      }

      serverUrls ??= await _userServerList
          .getUserServerList(pubkeys: [pubkeyToFetchUserServerList]);
    }

    if (serverUrls == null) {
      throw Exception("User has no server list");
    }

    return _blossomImpl.downloadBlobToFile(
      sha256: sha256,
      outputPath: outputPath,
      authorization: signedAuthorization,
      serverUrls: serverUrls,
    );
  }

  /// checks if the blob exists on the server without downloading, useful to check before streaming a video via url \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  ///
  /// returns the url of one server that has the blob e.g. https://myserver.com/hash.pdf \
  /// otherwise  throws an error
  Future<String> checkBlob({
    required String sha256,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
  }) async {
    Nip01Event? myAuthorization;
    Nip01Event? signedAuthorization;

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "get",
        pubKey: _signer.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "get"],
          ["x", sha256],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      signedAuthorization = await _signer.sign(myAuthorization);
    }

    if (serverUrls == null) {
      if (pubkeyToFetchUserServerList == null) {
        throw Exception(
            "pubkeyToFetchUserServerList is null and serverUrls is null");
      }

      serverUrls ??= await _userServerList
          .getUserServerList(pubkeys: [pubkeyToFetchUserServerList]);
    }

    if (serverUrls == null) {
      throw Exception("User has no server list");
    }

    return _blossomImpl.checkBlob(
      sha256: sha256,
      authorization: signedAuthorization,
      serverUrls: serverUrls,
    );
  }

  /// downloads a blob as a stream, useful for large files like videos \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  Future<Stream<BlobResponse>> getBlobStream({
    required String sha256,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
    int chunkSize = 1024 * 1024, // 1MB chunks,
  }) async {
    Nip01Event? myAuthorization;
    Nip01Event? signedAuthorization;

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "get",
        pubKey: _signer.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "get"],
          ["x", sha256],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      signedAuthorization = await _signer.sign(myAuthorization);
    }

    if (serverUrls == null) {
      if (pubkeyToFetchUserServerList == null) {
        throw "pubkeyToFetchUserServerList is null and serverUrls is null";
      }

      serverUrls ??= await _userServerList
          .getUserServerList(pubkeys: [pubkeyToFetchUserServerList]);
    }

    if (serverUrls == null) {
      throw Exception("User has no server list");
    }

    return _blossomImpl.getBlobStream(
      sha256: sha256,
      authorization: signedAuthorization,
      serverUrls: serverUrls,
      chunkSize: chunkSize,
    );
  }

  /// list the [pubkey] blobs \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  ///
  Future<List<BlobDescriptor>> listBlobs({
    required String pubkey,
    List<String>? serverUrls,
    bool useAuth = true,
    DateTime? since,
    DateTime? until,
  }) async {
    Nip01Event? myAuthorization;
    Nip01Event? signedAuthorization;

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "List Blobs",
        pubKey: _signer.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "list"],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      signedAuthorization = await _signer.sign(myAuthorization);
    }

    /// fetch user server list from nostr
    serverUrls ??= await _userServerList.getUserServerList(pubkeys: [pubkey]);

    if (serverUrls == null) {
      throw Exception("User has no server list: $pubkey");
    }

    return _blossomImpl.listBlobs(
      pubkey: pubkey,
      since: since,
      until: until,
      serverUrls: serverUrls,
      authorization: signedAuthorization,
    );
  }

  /// delete a blob
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error \
  /// the current signer is used to sign the request
  Future<List<BlobDeleteResult>> deleteBlob({
    required String sha256,
    List<String>? serverUrls,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    _checkSigner();

    final Nip01Event myAuthorization = Nip01Event(
      content: "delete",
      pubKey: _signer.getPublicKey(),
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", "delete"],
        ["x", sha256],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
      ],
    );

    final signedAuthorization = await _signer.sign(myAuthorization);

    /// fetch user server list from nostr
    serverUrls ??= await _userServerList
        .getUserServerList(pubkeys: [_signer.getPublicKey()]);

    if (serverUrls == null) {
      throw Exception("User has no server list");
    }
    return _blossomImpl.deleteBlob(
      sha256: sha256,
      authorization: signedAuthorization,
      serverUrls: serverUrls,
    );
  }

  /// Directly downloads a blob from the url, without blossom
  Future<BlobResponse> directDownload({
    required Uri url,
  }) {
    return _blossomImpl.directDownload(url: url);
  }

  /// Directly downloads a blob from the url to a file, without blossom
  Future<void> directDownloadToFile({
    required Uri url,
    required String outputPath,
  }) {
    return _blossomImpl.directDownloadToFile(url: url, outputPath: outputPath);
  }

  /// Reports a blob to the server
  /// [sha256] is the hash of the blob
  /// [eventId] is the event id where the blob was mentioned
  /// [reportType] is the type of report, e.g. malware @see nip56
  /// [reportMsg] is the message to send to the server
  /// [serverUrl] server url to report to
  ///
  /// returns the http status code of the rcv server
  Future<int> report({
    required String sha256,
    required String eventId,
    required String reportType,
    required String reportMsg,
    required String serverUrl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    _checkSigner();

    final Nip01Event reportEvent = Nip01Event(
      content: reportMsg,
      pubKey: _signer.getPublicKey(),
      kind: kReport,
      createdAt: now,
      tags: [
        ["x", sha256, reportType.toLowerCase()],
        ["e", eventId, reportType.toLowerCase()],
        ["server", serverUrl],
      ],
    );

    final signedReport = await _signer.sign(reportEvent);

    return _blossomImpl.report(
      sha256: sha256,
      reportEvent: signedReport,
      serverUrl: serverUrl,
    );
  }
}
