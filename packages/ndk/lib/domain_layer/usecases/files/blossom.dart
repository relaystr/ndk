import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../../config/blossom_config.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/blossom.dart';
import '../../repositories/event_signer.dart';

/// direct access usecase to blossom \
/// use files usecase for a more convinent way to manage files
class Blossom {
  /// kind for all most of blossom
  static const kBlossom = 24242;

  /// kind for blossom user server list
  static const kBlossomUserServerList = 10063;

  final BlossomRepository repository;
  final EventSigner signer;

  Blossom(
    this.repository,
    this.signer,
  );

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

    // todo: fetch user server list from nostr

    if (serverUrls == null) {
      throw UnimplementedError();
    }

    return repository.uploadBlob(
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

    // todo: fetch user server list from nostr for user [pubkeyToFetchUserServerList]

    if (serverUrls == null) {
      throw UnimplementedError();
    }

    return repository.getBlob(
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

    // todo: fetch user server list from nostr for user [pubkeyToFetchUserServerList]

    if (serverUrls == null) {
      throw UnimplementedError();
    }

    return repository.listBlobs(
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

    // todo: fetch user server list from nostr for user [pubkeyToFetchUserServerList]

    if (serverUrls == null) {
      throw UnimplementedError();
    }

    return repository.deleteBlob(
      sha256: sha256,
      authorization: myAuthorization,
      serverUrls: serverUrls,
    );
  }
}
