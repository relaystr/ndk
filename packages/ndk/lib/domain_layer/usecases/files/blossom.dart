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

  Future<List<BlobUploadResult>> uploadBlob({
    required Uint8List data,
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

    return repository.uploadBlob(
      data: data,
      authorization: myAuthorization,
      contentType: contentType,
      strategy: strategy,
    );
  }

  Future<Uint8List> getBlob(String sha256, {bool useAuth = false}) async {
    late final Nip01Event myAuthorization;

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

    return repository.getBlob(sha256, authorization: myAuthorization);
  }

  Future<List<BlobDescriptor>> listBlobs(
    String pubkey, {
    DateTime? since,
    DateTime? until,
  }) {
    return repository.listBlobs(pubkey, since: since, until: until);
  }

  Future<List<BlobDeleteResult>> delteBlob(String sha256) async {
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

    return repository.deleteBlob(
      sha256: sha256,
      authorization: myAuthorization,
    );
  }
}
