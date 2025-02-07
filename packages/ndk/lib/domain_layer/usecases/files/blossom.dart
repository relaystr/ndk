import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../../config/blossom_config.dart';
import '../../entities/blossom_blobs.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/blossom.dart';
import '../../repositories/event_signer.dart';
import 'blossom_user_server_list.dart';

/// direct access usecase to blossom \
/// use files usecase for a more convinent way to manage files
class Blossom {
  /// kind for all most of blossom
  static const kBlossom = 24242;

  /// kind for blossom user server list
  static const kBlossomUserServerList = 10063;

  final BlossomUserServerList userServerList;
  final BlossomRepository blossomImpl;
  final EventSigner? signer;

  Blossom({
    required this.userServerList,
    required this.blossomImpl,
    required this.signer,
  });

  _checkSigner() {
    if (signer == null) {
      throw "Signer is null";
    }
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
      pubKey: signer!.getPublicKey(),
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", "upload"],
        ["x", dataSha256.toString()],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
      ],
    );

    await signer!.sign(myAuthorization);

    serverUrls ??= await userServerList
        .getUserServerList(pubkeys: [signer!.getPublicKey()]);

    if (serverUrls == null) {
      throw "User has no server list";
    }

    return blossomImpl.uploadBlob(
      data: data,
      serverUrls: serverUrls,
      authorization: myAuthorization,
      contentType: contentType,
      strategy: strategy,
      mediaOptimisation: serverMediaOptimisation,
    );
  }

  /// downloads a blob using the sha256 with fallback stragegy \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  Future<BlobResponse> getBlob({
    required String sha256,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
  }) async {
    Nip01Event? myAuthorization;

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "get",
        pubKey: signer!.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "get"],
          ["x", sha256],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      await signer!.sign(myAuthorization);
    }

    if (serverUrls == null) {
      if (pubkeyToFetchUserServerList == null) {
        throw "pubkeyToFetchUserServerList is null and serverUrls is null";
      }

      serverUrls ??= await userServerList
          .getUserServerList(pubkeys: [pubkeyToFetchUserServerList]);
    }

    if (serverUrls == null) {
      throw "User has no server list";
    }

    return blossomImpl.getBlob(
      sha256: sha256,
      authorization: myAuthorization,
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

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "get",
        pubKey: signer!.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "get"],
          ["x", sha256],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      await signer!.sign(myAuthorization);
    }

    if (serverUrls == null) {
      if (pubkeyToFetchUserServerList == null) {
        throw "pubkeyToFetchUserServerList is null and serverUrls is null";
      }

      serverUrls ??= await userServerList
          .getUserServerList(pubkeys: [pubkeyToFetchUserServerList]);
    }

    if (serverUrls == null) {
      throw "User has no server list";
    }

    return blossomImpl.checkBlob(
      sha256: sha256,
      authorization: myAuthorization,
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

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "get",
        pubKey: signer!.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "get"],
          ["x", sha256],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      await signer!.sign(myAuthorization);
    }

    if (serverUrls == null) {
      if (pubkeyToFetchUserServerList == null) {
        throw "pubkeyToFetchUserServerList is null and serverUrls is null";
      }

      serverUrls ??= await userServerList
          .getUserServerList(pubkeys: [pubkeyToFetchUserServerList]);
    }

    if (serverUrls == null) {
      throw "User has no server list";
    }

    return blossomImpl.getBlobStream(
      sha256: sha256,
      authorization: myAuthorization,
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

    if (useAuth) {
      _checkSigner();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "List Blobs",
        pubKey: signer!.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "list"],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      await signer!.sign(myAuthorization);
    }

    /// fetch user server list from nostr
    serverUrls ??= await userServerList.getUserServerList(pubkeys: [pubkey]);

    if (serverUrls == null) {
      throw "User has no server list: $pubkey";
    }

    return blossomImpl.listBlobs(
      pubkey: pubkey,
      since: since,
      until: until,
      serverUrls: serverUrls,
      authorization: myAuthorization,
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
      pubKey: signer!.getPublicKey(),
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", "delete"],
        ["x", sha256],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
      ],
    );

    await signer!.sign(myAuthorization);

    /// fetch user server list from nostr
    serverUrls ??= await userServerList
        .getUserServerList(pubkeys: [signer!.getPublicKey()]);

    if (serverUrls == null) {
      throw "User has no server list";
    }
    return blossomImpl.deleteBlob(
      sha256: sha256,
      authorization: myAuthorization,
      serverUrls: serverUrls,
    );
  }

  /// Directly downloads a blob from the url, without blossom
  Future<BlobResponse> directDownload({
    required Uri url,
  }) {
    return blossomImpl.directDownload(url: url);
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
      pubKey: signer!.getPublicKey(),
      kind: 1984,
      createdAt: now,
      tags: [
        ["x", sha256, reportType.toLowerCase()],
        ["e", eventId, reportType.toLowerCase()],
        ["server", serverUrl],
      ],
    );

    await signer!.sign(reportEvent);

    return blossomImpl.report(
      sha256: sha256,
      reportEvent: reportEvent,
      serverUrl: serverUrl,
    );
  }
}
