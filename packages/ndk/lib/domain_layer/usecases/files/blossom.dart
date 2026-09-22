import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../config/blossom_config.dart';
import '../../../shared/nips/nip01/bip340.dart';
import '../../entities/account.dart';
import '../../entities/auth_policy.dart';
import '../../entities/blob_upload_progress.dart';
import '../../entities/blossom_authorization.dart';
import '../../entities/blossom_blobs.dart';
import '../../entities/blossom_strategies.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/blossom.dart';
import '../../repositories/event_signer.dart';
import '../accounts/accounts.dart';
import 'blossom_exceptions.dart';
import 'blossom_user_server_list.dart';

/// What one blossom operation does about its authorization, and whose kind
/// 10063 list it falls back to when no servers were named.
class _BlossomAuthPlan {
  final BlossomAuthorization authorization;

  /// pubkey the policy names, null when it names nobody
  final String? listOwner;

  const _BlossomAuthPlan(this.authorization, this.listOwner);
}

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
  final LocalEventSignerFactory _eventSignerFactory;

  Blossom({
    required BlossomUserServerList blossomUserServerList,
    required BlossomRepository blossomRepository,
    required Accounts accounts,
    required LocalEventSignerFactory eventSignerFactory,
  })  : _accounts = accounts,
        _userServerList = blossomUserServerList,
        _blossomImpl = blossomRepository,
        _eventSignerFactory = eventSignerFactory;

  /// The kind 24242 event an operation authorises itself with. Built when it
  /// is needed rather than when the call is made, so an event signed after a
  /// refusal is not already ageing.
  Nip01Event _blossomAuthEvent({
    required String content,
    required String pubkey,
    required String type,
    String? blobSha256,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Nip01Event(
      content: content,
      pubKey: pubkey,
      kind: kBlossom,
      createdAt: now,
      tags: [
        ["t", type],
        if (blobSha256 != null) ["x", blobSha256],
        ["expiration", "${now + BLOSSOM_AUTH_EXPIRATION.inSeconds}"],
      ],
    );
  }

  /// The account a bare signer stands for, keeping the logged-in one whole so
  /// it does not lose its type on the way.
  Account _accountFor(EventSigner signer) {
    final logged = _accounts.getLoggedAccount();
    if (logged != null && identical(logged.signer, signer)) return logged;

    return Account(
      type: AccountType.privateKey,
      pubkey: signer.getPublicKey(),
      signer: signer,
    );
  }

  /// The policy the deprecated [useAuth] and [customSigner] pair stands for.
  AuthPolicy _legacyPolicy(bool useAuth, EventSigner? customSigner) => useAuth
      ? AuthPolicy.require(_accountFor(_getSigner(customSigner)))
      : const AuthPolicy.never();

  /// Turns the caller's intent into what the repository does about the
  /// `Authorization` header.
  ///
  /// [auth] wins over [useAuth] and [customSigner]. [legacyDefault] is what
  /// the operation did before [auth] existed, for callers that pass neither.
  /// [buildEvent] makes the kind 24242 event, because only the operation knows
  /// its `t` and `x` tags.
  ///
  /// Throws [BlossomAuthUnavailableException], before anything is sent, when
  /// [auth] requires an identity that cannot sign.
  Future<_BlossomAuthPlan> _planAuth({
    required AuthPolicy? auth,
    required bool? useAuth,
    required EventSigner? customSigner,
    required bool legacyDefault,
    required String operation,
    required Nip01Event Function(String pubkey) buildEvent,
  }) async {
    final policy =
        auth ?? _legacyPolicy(useAuth ?? legacyDefault, customSigner);

    switch (policy) {
      case AuthPolicyNever():
        return const _BlossomAuthPlan(BlossomAuthorization.none(), null);

      case AuthPolicyRequire(:final account):
        if (!account.signer.canSign()) {
          throw BlossomAuthUnavailableException(account.pubkey, operation);
        }
        final signed = await account.signer.sign(buildEvent(account.pubkey));
        return _BlossomAuthPlan(
          BlossomAuthorization.upfront(signed),
          account.pubkey,
        );

      case AuthPolicyAllow(:final account):
        // allow never promised a signature, so an account that cannot give one
        // behaves as never() rather than failing the operation
        if (!account.signer.canSign()) {
          return _BlossomAuthPlan(
            const BlossomAuthorization.none(),
            account.pubkey,
          );
        }
        return _BlossomAuthPlan(
          BlossomAuthorization.onRefusal(
            () => account.signer.sign(buildEvent(account.pubkey)),
          ),
          account.pubkey,
        );
    }
  }

  /// The four read operations authorise the same way: a `get` event naming the
  /// blob, and anonymous unless the caller asked otherwise.
  Future<_BlossomAuthPlan> _readAuthPlan({
    required AuthPolicy? auth,
    required bool? useAuth,
    required EventSigner? customSigner,
    required String sha256,
  }) =>
      _planAuth(
        auth: auth,
        useAuth: useAuth,
        customSigner: customSigner,
        legacyDefault: false,
        operation: "get",
        buildEvent: (pubkey) => _blossomAuthEvent(
          content: "get",
          pubkey: pubkey,
          type: "get",
          blobSha256: sha256,
        ),
      );

  /// The servers a write talks to: an explicit list, else an explicit pubkey's
  /// kind 10063 list, else the identity the policy names, else the logged-in
  /// account's.
  ///
  /// That last fallback applies even under [AuthPolicy.never]. Reading a
  /// public kind 10063 from relays tells the blossom servers nothing, and
  /// never() is a statement about the `Authorization` header, not about which
  /// nostr list may be read.
  Future<List<String>> _resolveWriteServers({
    required List<String>? serverUrls,
    required String? explicitPubkey,
    required String? listOwner,
  }) async {
    if (serverUrls != null) return serverUrls;

    final owner = explicitPubkey ?? listOwner ?? _accounts.getPublicKey();
    if (owner == null) {
      throw Exception(
        "No server list to use: pass serverUrls, or "
        "pubkeyToFetchUserServerList, or an account in auth, or log in",
      );
    }

    final resolved = await _userServerList.getUserServerList(pubkeys: [owner]);
    if (resolved == null) {
      throw Exception("User has no server list");
    }
    return resolved;
  }

  /// The servers a read talks to. Unlike a write, a read is about somebody
  /// else's blob as often as not, so it never guesses.
  Future<List<String>> _resolveReadServers({
    required List<String>? serverUrls,
    required String? pubkeyToFetchUserServerList,
  }) async {
    if (serverUrls != null) return serverUrls;

    if (pubkeyToFetchUserServerList == null) {
      throw Exception(
        "pubkeyToFetchUserServerList is null and serverUrls is null",
      );
    }

    final resolved = await _userServerList.getUserServerList(
      pubkeys: [pubkeyToFetchUserServerList],
    );
    if (resolved == null) {
      throw Exception("User has no server list");
    }
    return resolved;
  }

  /// Gets the signer to use for blossom operations
  /// Priority: customSigner > logged in account signer > temporary signer
  EventSigner _getSigner(EventSigner? customSigner) {
    if (customSigner != null) return customSigner;

    if (_accounts.canSign) {
      return _accounts.getLoggedAccount()!.signer;
    }

    return _throwawaySigner();
  }

  /// A fresh key, for something that has to be signed but names nobody.
  EventSigner _throwawaySigner() {
    final keyPair = Bip340.generatePrivateKey();
    return _eventSignerFactory.create(
      privateKey: keyPair.privateKey!,
      publicKey: keyPair.publicKey,
    );
  }

  /// upload a blob to the server
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error \
  /// the current signer is used to sign the request, or [customSigner] if provided \
  /// if no signer is available, a temporary signer is created \
  /// [strategy] is the upload strategy, default is mirrorAfterSuccess \
  /// [serverMediaOptimisation] is whether the server should optimise the media [BUD-05], IMPORTANT: the server hash will be different \
  /// [precomputedSha256] optional hex sha256 of [data]; if provided, skips local hashing. \
  /// Caller is responsible for correctness: a mismatched hash will cause the server to reject the upload.
  /// [auth] says which identity the upload may be attributed to, see
  /// [AuthPolicy]. Without it the upload authorises as the logged-in account,
  /// or as a throwaway key when none is.
  ///
  /// Throws [BlossomAuthUnavailableException], before anything is sent, if
  /// [auth] requires an identity that cannot sign.
  Future<List<BlobUploadResult>> uploadBlob({
    required Uint8List data,
    List<String>? serverUrls,
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool serverMediaOptimisation = false,
    AuthPolicy? auth,
    String? pubkeyToFetchUserServerList,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
    String? precomputedSha256,
  }) async {
    /// sha256 of the data
    final dataSha256 = precomputedSha256 ?? sha256.convert(data).toString();

    final authType = serverMediaOptimisation ? "media" : "upload";

    final plan = await _planAuth(
      auth: auth,
      useAuth: null,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      legacyDefault: true,
      operation: authType,
      buildEvent: (pubkey) => _blossomAuthEvent(
        content: authType,
        pubkey: pubkey,
        type: authType,
        blobSha256: dataSha256,
      ),
    );

    final servers = await _resolveWriteServers(
      serverUrls: serverUrls,
      explicitPubkey: pubkeyToFetchUserServerList,
      listOwner: plan.listOwner,
    );

    final stream = _blossomImpl.uploadBlob(
      dataStreamFactory: () => Stream.value(data),
      contentLength: data.length,
      serverUrls: servers,
      authorization: plan.authorization,
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
  /// the current signer is used to sign the request, or [customSigner] if provided \
  /// if no signer is available, a temporary signer is created \
  /// [strategy] is the upload strategy, default is mirrorAfterSuccess \
  /// [serverMediaOptimisation] is whether the server should optimise the media [BUD-05], IMPORTANT: the server hash will be different \
  /// [precomputedSha256] optional hex sha256 of the file; if provided, skips the [UploadPhase.hashing] phase entirely. \
  /// Caller is responsible for correctness: a mismatched hash will cause the server to reject the upload.
  /// [auth] says which identity the upload may be attributed to, see
  /// [AuthPolicy]. Without it the upload authorises as the logged-in account,
  /// or as a throwaway key when none is.
  Stream<BlobUploadProgress> uploadBlobFromFile({
    required String filePath,
    List<String>? serverUrls,
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool serverMediaOptimisation = false,
    AuthPolicy? auth,
    String? pubkeyToFetchUserServerList,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
    String? precomputedSha256,
  }) async* {
    String? fileHash = precomputedSha256;

    if (fileHash == null) {
      // Compute file hash without loading entire file into memory
      await for (final hashProgress in _blossomImpl.computeFileHash(filePath)) {
        yield BlobUploadProgress(
          currentServer: '',
          sentBytes: hashProgress.processedBytes,
          totalBytes: hashProgress.totalBytes,
          completedUploads: const [],
          phase: UploadPhase.hashing,
          progressPhase: hashProgress.progress,
        );

        if (hashProgress.isComplete && hashProgress.hash != null) {
          fileHash = hashProgress.hash;
        }
      }

      if (fileHash == null) {
        throw Exception('Failed to compute file hash');
      }
    }

    final authType = serverMediaOptimisation ? "media" : "upload";

    final plan = await _planAuth(
      auth: auth,
      useAuth: null,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      legacyDefault: true,
      operation: authType,
      buildEvent: (pubkey) => _blossomAuthEvent(
        content: authType,
        pubkey: pubkey,
        type: authType,
        blobSha256: fileHash,
      ),
    );

    final servers = await _resolveWriteServers(
      serverUrls: serverUrls,
      explicitPubkey: pubkeyToFetchUserServerList,
      listOwner: plan.listOwner,
    );

    yield* _blossomImpl.uploadBlobFromFile(
      filePath: filePath,
      serverUrls: servers,
      authorization: plan.authorization,
      contentType: contentType,
      strategy: strategy,
      mediaOptimisation: serverMediaOptimisation,
    );
  }

  /// Mirror a blob from a blossom URL to specified servers using the blossom /mirror endpoint
  ///
  /// [blossomUrl] is the source URL of the blob to mirror (e.g., https://cdn.example.com/[sha256].jpg)
  ///   The URL must contain a 64-character SHA256 hash
  /// [targetServerUrls] is the list of servers to mirror the blob to
  /// the current signer is used to sign the mirror request, or [customSigner] if provided \
  /// if no signer is available, a temporary signer is created
  ///
  /// Throws an [Exception] if no SHA256 hash is detected in the URL
  Future<List<BlobUploadResult>> mirrorToServers({
    required Uri blossomUrl,
    required List<String> targetServerUrls,
    AuthPolicy? auth,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
  }) async {
    // Extract sha256 from the URL
    final sha256Match = sha256Regex.firstMatch(blossomUrl.toString());
    if (sha256Match == null) {
      throw Exception(
        "No SHA256 hash detected in URL: ${blossomUrl.toString()}",
      );
    }

    final sha256 = sha256Match.group(1)!;

    final plan = await _planAuth(
      auth: auth,
      useAuth: null,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      legacyDefault: true,
      operation: "upload",
      buildEvent: (pubkey) => _blossomAuthEvent(
        content: "upload",
        pubkey: pubkey,
        type: "upload",
        blobSha256: sha256,
      ),
    );

    // Mirror to all target servers
    final results = await Future.wait(
      targetServerUrls.map(
        (serverUrl) => _blossomImpl.mirrorToServer(
          fileUrl: blossomUrl.toString(),
          serverUrl: serverUrl,
          sha256: sha256,
          authorization: plan.authorization,
        ),
      ),
    );

    return results;
  }

  /// Gets a blob by trying servers sequentially until success (fallback) \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  /// [auth] says which identity the download may be attributed to, see
  /// [AuthPolicy]. Without it the download stays anonymous.
  Future<BlobResponse> getBlob({
    required String sha256,
    AuthPolicy? auth,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
    @Deprecated(
      'Use auth instead. useAuth will be removed in a future version.',
    )
    bool? useAuth,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
  }) async {
    final plan = await _readAuthPlan(
      auth: auth,
      // ignore: deprecated_member_use_from_same_package
      useAuth: useAuth,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      sha256: sha256,
    );

    final servers = await _resolveReadServers(
      serverUrls: serverUrls,
      pubkeyToFetchUserServerList: pubkeyToFetchUserServerList,
    );

    return _blossomImpl.getBlob(
      sha256: sha256,
      authorization: plan.authorization,
      serverUrls: servers,
    );
  }

  /// Downloads a blob directly to a file path (without loading into memory)
  /// For native platforms (Windows, macOS, Linux, Android, iOS): uses actual file system paths
  /// For web: triggers browser download dialog to save the file
  ///
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pubkey has no UserServerList (kind: 10063), throws an error
  /// [auth] says which identity the download may be attributed to, see
  /// [AuthPolicy]. Without it the download stays anonymous.
  Future<void> downloadBlobToFile({
    required String sha256,
    required String outputPath,
    AuthPolicy? auth,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
    @Deprecated(
      'Use auth instead. useAuth will be removed in a future version.',
    )
    bool? useAuth,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
  }) async {
    final plan = await _readAuthPlan(
      auth: auth,
      // ignore: deprecated_member_use_from_same_package
      useAuth: useAuth,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      sha256: sha256,
    );

    final servers = await _resolveReadServers(
      serverUrls: serverUrls,
      pubkeyToFetchUserServerList: pubkeyToFetchUserServerList,
    );

    return _blossomImpl.downloadBlobToFile(
      sha256: sha256,
      outputPath: outputPath,
      authorization: plan.authorization,
      serverUrls: servers,
    );
  }

  /// checks if the blob exists on the server without downloading, useful to check before streaming a video via url \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  ///
  /// returns the url of one server that has the blob e.g. https://myserver.com/hash.pdf \
  /// otherwise  throws an error
  /// [auth] says which identity the check may be attributed to, see
  /// [AuthPolicy]. Without it the check stays anonymous.
  Future<String> checkBlob({
    required String sha256,
    AuthPolicy? auth,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
    @Deprecated(
      'Use auth instead. useAuth will be removed in a future version.',
    )
    bool? useAuth,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
  }) async {
    final plan = await _readAuthPlan(
      auth: auth,
      // ignore: deprecated_member_use_from_same_package
      useAuth: useAuth,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      sha256: sha256,
    );

    final servers = await _resolveReadServers(
      serverUrls: serverUrls,
      pubkeyToFetchUserServerList: pubkeyToFetchUserServerList,
    );

    return _blossomImpl.checkBlob(
      sha256: sha256,
      authorization: plan.authorization,
      serverUrls: servers,
    );
  }

  /// downloads a blob as a stream, useful for large files like videos \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  /// [auth] says which identity the download may be attributed to, see
  /// [AuthPolicy]. Without it the download stays anonymous.
  Future<Stream<BlobResponse>> getBlobStream({
    required String sha256,
    AuthPolicy? auth,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
    int chunkSize = 1024 * 1024, // 1MB chunks,
    @Deprecated(
      'Use auth instead. useAuth will be removed in a future version.',
    )
    bool? useAuth,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
  }) async {
    final plan = await _readAuthPlan(
      auth: auth,
      // ignore: deprecated_member_use_from_same_package
      useAuth: useAuth,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      sha256: sha256,
    );

    final servers = await _resolveReadServers(
      serverUrls: serverUrls,
      pubkeyToFetchUserServerList: pubkeyToFetchUserServerList,
    );

    return _blossomImpl.getBlobStream(
      sha256: sha256,
      authorization: plan.authorization,
      serverUrls: servers,
      chunkSize: chunkSize,
    );
  }

  /// list the [pubkey] blobs \
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error
  ///
  /// [auth] says which identity the listing may be attributed to, see
  /// [AuthPolicy]. Without it the listing authorises as the logged-in account,
  /// since a server rarely lists a pubkey's blobs to a stranger.
  Future<List<BlobDescriptor>> listBlobs({
    required String pubkey,
    List<String>? serverUrls,
    AuthPolicy? auth,
    DateTime? since,
    DateTime? until,
    @Deprecated(
      'Use auth instead. useAuth will be removed in a future version.',
    )
    bool? useAuth,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
  }) async {
    final plan = await _planAuth(
      auth: auth,
      // ignore: deprecated_member_use_from_same_package
      useAuth: useAuth,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      legacyDefault: true,
      operation: "list",
      buildEvent: (owner) => _blossomAuthEvent(
        content: "List Blobs",
        pubkey: owner,
        type: "list",
      ),
    );

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
      authorization: plan.authorization,
    );
  }

  /// delete a blob
  /// if [serverUrls] is null, the userServerList is fetched from nostr. \
  /// if the pukey has no UserServerList (kind: 10063), throws an error \
  /// the current signer is used to sign the request, or [customSigner] if provided \
  /// if no signer is available, a temporary signer is created
  /// [auth] says which identity the deletion may be attributed to, see
  /// [AuthPolicy]. Without it the deletion authorises as the logged-in
  /// account.
  Future<List<BlobDeleteResult>> deleteBlob({
    required String sha256,
    List<String>? serverUrls,
    AuthPolicy? auth,
    String? pubkeyToFetchUserServerList,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
  }) async {
    final plan = await _planAuth(
      auth: auth,
      useAuth: null,
      // ignore: deprecated_member_use_from_same_package
      customSigner: customSigner,
      legacyDefault: true,
      operation: "delete",
      buildEvent: (pubkey) => _blossomAuthEvent(
        content: "delete",
        pubkey: pubkey,
        type: "delete",
        blobSha256: sha256,
      ),
    );

    final servers = await _resolveWriteServers(
      serverUrls: serverUrls,
      explicitPubkey: pubkeyToFetchUserServerList,
      listOwner: plan.listOwner,
    );

    return _blossomImpl.deleteBlob(
      sha256: sha256,
      authorization: plan.authorization,
      serverUrls: servers,
    );
  }

  /// Directly downloads a blob from the url, without blossom
  Future<BlobResponse> directDownload({required Uri url}) {
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
  /// [customSigner] optional custom signer to use for signing the report, if not provided uses the current logged in signer or creates a temporary one
  ///
  /// returns the http status code of the rcv server
  /// [auth] says which identity signs the report, see [AuthPolicy]. The
  /// endpoint takes a signed event as its body, so there is nothing to
  /// withhold: [AuthPolicy.never] signs with a throwaway key, which is what an
  /// anonymous report is.
  ///
  /// Throws [BlossomAuthUnavailableException] if [auth] requires an identity
  /// that cannot sign.
  Future<int> report({
    required String sha256,
    required String eventId,
    required String reportType,
    required String reportMsg,
    required String serverUrl,
    AuthPolicy? auth,
    @Deprecated(
      'Use auth: AuthPolicy.require(account) instead. '
      'customSigner will be removed in a future version.',
    )
    EventSigner? customSigner,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final EventSigner signer;
    switch (auth) {
      case null:
        // ignore: deprecated_member_use_from_same_package
        signer = _getSigner(customSigner);

      case AuthPolicyNever():
        signer = _throwawaySigner();

      case AuthPolicyRequire(:final account):
        if (!account.signer.canSign()) {
          throw BlossomAuthUnavailableException(account.pubkey, "report");
        }
        signer = account.signer;

      case AuthPolicyAllow(:final account):
        // allow never promised a signature, so an account that cannot give one
        // reports anonymously rather than as whoever happens to be logged in
        signer = account.signer.canSign() ? account.signer : _throwawaySigner();
    }

    final Nip01Event reportEvent = Nip01Event(
      content: reportMsg,
      pubKey: signer.getPublicKey(),
      kind: kReport,
      createdAt: now,
      tags: [
        ["x", sha256, reportType.toLowerCase()],
        ["e", eventId, reportType.toLowerCase()],
        ["server", serverUrl],
      ],
    );

    final signedReport = await signer.sign(reportEvent);

    return _blossomImpl.report(
      sha256: sha256,
      reportEvent: signedReport,
      serverUrl: serverUrl,
    );
  }
}
