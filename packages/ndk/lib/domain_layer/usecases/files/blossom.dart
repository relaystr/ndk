import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../../config/blossom_config.dart';
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
  final EventSigner signer;

  Blossom({
    required this.userServerList,
    required this.blossomImpl,
    required this.signer,
  });

  /// upload a blob to the server
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  Future<List<BlobUploadResult>> uploadBlob({
    required Uint8List data,
    List<String>? serverUrls,
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    /// sha256 of the data
    final dataSha256 = sha256.convert(data);

    final Nip01Event myAuthorization = Nip01Event(
      content: "upload",
      pubKey: signer.getPublicKey(),
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", "upload"],
        ["x", dataSha256.toString()],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
      ],
    );

    await signer.sign(myAuthorization);

    serverUrls ??= await userServerList
        .getUserServerList(pubkeys: [signer.getPublicKey()]);

    if (serverUrls == null) {
      throw "User has no server list";
    }

    return blossomImpl.uploadBlob(
      data: data,
      serverUrls: serverUrls,
      authorization: myAuthorization,
      contentType: contentType,
      strategy: strategy,
    );
  }

  /// downloads a blob
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  Future<Uint8List> getBlob({
    required String sha256,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
  }) async {
    Nip01Event? myAuthorization;

    if (useAuth) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "get",
        pubKey: signer.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "get"],
          ["x", sha256],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      await signer.sign(myAuthorization);
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

  Future<List<BlobDescriptor>> listBlobs({
    required String pubkey,
    List<String>? serverUrls,
    bool useAuth = true,
    DateTime? since,
    DateTime? until,
  }) async {
    Nip01Event? myAuthorization;

    if (useAuth) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      myAuthorization = Nip01Event(
        content: "List Blobs",
        pubKey: signer.getPublicKey(),
        kind: kBlossom,
        createdAt: now,
        tags: [
          ["t", "list"],
          ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
        ],
      );

      await signer.sign(myAuthorization);
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

  Future<List<BlobDeleteResult>> delteBlob({
    required String sha256,
    List<String>? serverUrls,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final Nip01Event myAuthorization = Nip01Event(
      content: "delete",
      pubKey: signer.getPublicKey(),
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", "delete"],
        ["x", sha256],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inMilliseconds}"],
      ],
    );

    await signer.sign(myAuthorization);

    /// fetch user server list from nostr
    serverUrls ??= await userServerList
        .getUserServerList(pubkeys: [signer.getPublicKey()]);

    if (serverUrls == null) {
      throw "User has no server list";
    }
    return blossomImpl.deleteBlob(
      sha256: sha256,
      authorization: myAuthorization,
      serverUrls: serverUrls,
    );
  }
}
