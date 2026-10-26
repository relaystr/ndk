import 'dart:convert';
import 'dart:typed_data';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/pending_signer_request.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';

// The ndk NIP-44 implementation is marked experimental upstream; the wire
// format it produces is frozen by the NIP itself.
// ignore_for_file: experimental_member_use

import '../core/concord_constants.dart';
import '../core/derivations.dart';
import '../core/encoding.dart';

/// NIP-44 encrypt under an explicit conversation key (the stream
/// construction: conv_key is a self-ECDH or a plane read key, never a
/// `p`-tagged recipient).
Future<String> nip44EncryptWithKey(String plaintext, Uint8List convKey) =>
    Nip44.encryptMessage(plaintext, '', '', customConversationKey: convKey);

/// NIP-44 decrypt under an explicit conversation key.
Future<String> nip44DecryptWithKey(String payload, Uint8List convKey) =>
    Nip44.decryptMessage(payload, '', '', customConversationKey: convKey);

/// Which seal form a plane uses. A fixed property of the protocol layered
/// over the stream, **never** a per-message choice (CORD-01).
enum SealForm {
  /// Kind 20013: the rumor is NIP-44-encrypted inside the already-encrypted
  /// wrap (Chat, Guestbook, rekey planes).
  encrypted,

  /// Kind 20014: the seal's content holds the rumor's serialized JSON
  /// verbatim, so a compaction can re-wrap the signed rumor with its
  /// signature intact (Control Plane only).
  plaintext,
}

/// The keys one plane's envelope needs.
///
/// For a normal plane the three values come from one `group_key`. The
/// Control Plane splits them (CORD-01 "Write-Restricted Streams",
/// CORD-02 §5): the signer keypair derives from the staff-held
/// `control_root`, while [convKey] derives from the member-held
/// `community_root`.
class PlaneKeys {
  /// Secret that signs the wrap (stream key).
  final String signerSk;

  /// Public stream address the wrap carries in `pubkey`.
  final String signerPk;

  /// NIP-44 conversation key that encrypts wrap content.
  final Uint8List convKey;

  const PlaneKeys({
    required this.signerSk,
    required this.signerPk,
    required this.convKey,
  });

  PlaneKeys.fromGroupKey(GroupKey key)
    : this(signerSk: key.sk, signerPk: key.pk, convKey: key.convKey);

  /// The Control Plane read side only: every member holds this, nobody
  /// outside the community can derive it.
  PlaneKeys.readOnly(GroupKey readKey) : this.fromGroupKey(readKey);
}

/// A built stream wrap plus the ephemeral `p` key's secret (CORD-01: keep
/// it if you later want to NIP-09-delete your own wrap by its `p` tag).
class WrappedStreamEvent {
  final Nip01Event event;
  final String ephemeralSk;

  const WrappedStreamEvent({required this.event, required this.ephemeralSk});
}

/// A parsed, verified stream event: the three nesting layers.
class StreamEvent {
  final Nip01Event wrap;
  final Nip01Event seal;
  final Nip01Event rumor;

  /// The author's real pubkey — proven by the seal's signature.
  String get author => seal.pubKey;

  /// The rumor's millisecond time basis (`created_at * 1000` plus its `ms`
  /// tag) if the rumor carries one.
  int get createdAtMs => rumor.createdAt * 1000;

  const StreamEvent({
    required this.wrap,
    required this.seal,
    required this.rumor,
  });
}

/// CORD-01: build and parse Stream events.
///
/// The wrap reverses NIP-59: **fixed author** (the derived stream key
/// signs it), **ephemeral `p`**. `created_at` is never tweaked, at any
/// layer.
class StreamEnvelope {
  /// Builds the unsigned rumor for a plane event: an NIP-01-shaped event
  /// with a canonically computed id and no signature.
  static Nip01Event makeRumor({
    required String pubkey,
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  }) {
    checkHex32(pubkey, 'rumor author');
    final t = createdAt ?? Nip01Event.secondsSinceEpoch();
    final id = canonicalEventId(
      pubkey: pubkey,
      createdAt: t,
      kind: kind,
      tags: tags,
      content: content,
    );
    return Nip01Event(
      id: id,
      pubKey: pubkey,
      kind: kind,
      tags: tags,
      content: content,
      sig: null,
      createdAt: t,
    );
  }

  /// The rumor's serialized JSON — the exact bytes a plaintext seal carries
  /// and an encrypted seal encrypts. Key order is fixed here so two clients
  /// serialize identically.
  static String rumorJson(Nip01Event rumor) => canonicalEventJson(
    id: rumor.id,
    kind: rumor.kind,
    pubkey: rumor.pubKey,
    content: rumor.content,
    tags: rumor.tags,
    createdAt: rumor.createdAt,
  );

  /// Wraps [rumor] at a plane address.
  ///
  /// [signSeal] signs the seal with the actor's real identity — it receives
  /// the unsigned seal and returns it with a signature (a local signer or a
  /// NIP-46 remote signer both fit).
  static Future<WrappedStreamEvent> wrapRumor({
    required Nip01Event rumor,
    required PlaneKeys keys,
    required SealForm form,
    required Future<Nip01Event> Function(Nip01Event unsignedSeal) signSeal,
    List<List<String>> extraWrapTags = const [],
    int? wrapCreatedAt,
    String? ephemeralSk,
  }) async {
    final author = rumor.pubKey;

    // Layer 2 — the seal. created_at mirrors the rumor: untweaked.
    final rumorPlain = rumorJson(rumor);
    _enforceCap(rumorPlain, 'rumor plaintext');

    final int sealKind;
    final String sealContent;
    if (form == SealForm.encrypted) {
      sealKind = Kinds.encryptedSeal;
      sealContent = await nip44EncryptWithKey(rumorPlain, keys.convKey);
    } else {
      sealKind = Kinds.plaintextSeal;
      sealContent = rumorPlain;
    }

    final unsignedSeal = Nip01Event(
      id: canonicalEventId(
        pubkey: author,
        createdAt: rumor.createdAt,
        kind: sealKind,
        tags: const [],
        content: sealContent,
      ),
      pubKey: author,
      kind: sealKind,
      tags: const [],
      content: sealContent,
      sig: null,
      createdAt: rumor.createdAt,
    );
    final seal = await signSeal(unsignedSeal);
    if (seal.sig == null || seal.sig!.isEmpty) {
      throw StateError('signSeal returned an unsigned seal');
    }

    final sealJson = canonicalEventJson(
      id: seal.id,
      kind: seal.kind,
      pubkey: seal.pubKey,
      content: seal.content,
      tags: seal.tags,
      createdAt: seal.createdAt,
      sig: seal.sig,
    );
    _enforceCap(sealJson, 'seal plaintext');

    // Layer 1 — the wrap. Fresh ephemeral `p`, untweaked created_at.
    final eph = _ephemeralKeyPair(ephemeralSk);
    final wrapContent = await nip44EncryptWithKey(sealJson, keys.convKey);

    final wrapTags = <List<String>>[
      ['p', eph.pubkey],
      ...extraWrapTags,
    ];

    final wrapTime = wrapCreatedAt ?? rumor.createdAt;
    final wrapId = canonicalEventId(
      pubkey: keys.signerPk,
      createdAt: wrapTime,
      kind: Kinds.streamWrap,
      tags: wrapTags,
      content: wrapContent,
    );

    return WrappedStreamEvent(
      event: Nip01Event(
        id: wrapId,
        pubKey: keys.signerPk,
        kind: Kinds.streamWrap,
        tags: wrapTags,
        content: wrapContent,
        sig: Bip340.sign(wrapId, keys.signerSk),
        createdAt: wrapTime,
      ),
      ephemeralSk: eph.sk,
    );
  }

  /// Parses and verifies a stream wrap. Throws [FormatException] on any
  /// failure — callers drop the event.
  static Future<StreamEvent> unwrap({
    required Nip01Event wrap,
    required String expectedStreamPk,
    required Uint8List convKey,
    SealForm? expectedForm,
    bool ephemeral = false,
    bool verifySignatures = true,
  }) async {
    final wantedKind = ephemeral ? Kinds.ephemeralStreamWrap : Kinds.streamWrap;
    if (wrap.kind != wantedKind) {
      throw FormatException('not a stream wrap (kind ${wrap.kind})');
    }
    if (wrap.pubKey.toLowerCase() != expectedStreamPk.toLowerCase()) {
      throw FormatException('wrap is not at the expected stream address');
    }
    if (verifySignatures) {
      if (wrap.sig == null || !_sigValid(wrap.id, wrap.sig!, wrap.pubKey)) {
        throw FormatException('invalid stream wrap signature');
      }
    }

    final String sealJson;
    try {
      sealJson = await nip44DecryptWithKey(wrap.content, convKey);
    } catch (e) {
      throw FormatException('cannot open wrap: $e');
    }
    final sealMap = _parseEventJson(sealJson, what: 'seal');
    final sealKind = sealMap.event.kind;
    if (sealKind != Kinds.encryptedSeal && sealKind != Kinds.plaintextSeal) {
      throw FormatException('unexpected seal kind $sealKind');
    }
    if (expectedForm != null) {
      final wanted = expectedForm == SealForm.encrypted
          ? Kinds.encryptedSeal
          : Kinds.plaintextSeal;
      if (sealKind != wanted) {
        throw FormatException('seal form violation: expected $wanted');
      }
    }

    final String rumorJsonString;
    try {
      rumorJsonString = sealKind == Kinds.plaintextSeal
          ? sealMap.event.content
          : await nip44DecryptWithKey(sealMap.event.content, convKey);
    } catch (e) {
      throw FormatException('cannot open seal: $e');
    }

    final rumor = _parseEventJson(rumorJsonString, what: 'rumor').event;

    // NIP-59 impersonation check: renderers display rumor fields, so the
    // rumor's author must be the seal's signer.
    if (rumor.pubKey != sealMap.event.pubKey) {
      throw FormatException('rumor author does not match the seal signer');
    }

    if (verifySignatures) {
      if (sealMap.event.sig == null ||
          !_sigValid(sealMap.id, sealMap.event.sig!, sealMap.event.pubKey)) {
        throw FormatException('invalid seal signature');
      }
    }

    return StreamEvent(wrap: wrap, seal: sealMap.event, rumor: rumor);
  }

  /// Verifies a Schnorr signature, treating malformed input (wrong length,
  /// non-hex) as invalid rather than letting it throw — wraps arrive from
  /// untrusted relays.
  static bool _sigValid(String id, String sig, String pubkey) {
    try {
      return Bip340.verify(id, sig, pubkey);
    } catch (_) {
      return false;
    }
  }

  /// Enforces the NIP-44 65,535-byte plaintext cap for one nesting layer.
  /// Libraries are lenient; a lenient publisher mints events a strict
  /// reader cannot decrypt (checklist).
  static void _enforceCap(String plaintext, String layer) {
    final bytes = utf8.encode(plaintext);
    if (bytes.length > Caps.nip44Plaintext) {
      throw SizeError(
        '$layer exceeds the NIP-44 plaintext cap (${bytes.length} > ${Caps.nip44Plaintext} bytes)',
      );
    }
  }

  static ({String sk, String pubkey}) _ephemeralKeyPair(String? skOrNull) {
    if (skOrNull != null) {
      checkHex32(skOrNull, 'ephemeral key');
      return (sk: skOrNull, pubkey: Bip340.getPublicKey(skOrNull));
    }
    final kp = Bip340.generatePrivateKey();
    return (sk: kp.privateKey!, pubkey: kp.publicKey);
  }

  /// Parses one NIP-01 event JSON string, **recomputing** the id from the
  /// bytes and refusing an embedded id that disagrees. An embedded `id` is
  /// never trusted (checklist: "Pins").
  static ({Nip01Event event, String id}) _parseEventJson(
    String jsonString, {
    required String what,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw FormatException('unreadable $what JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$what is not an event object');
    }
    final m = decoded;
    final pubkey = m['pubkey'] as String?;
    final content = m['content'] as String?;
    final kind = m['kind'];
    final createdAt = m['created_at'];
    final tagsRaw = m['tags'];
    if (pubkey == null ||
        content == null ||
        kind is! int ||
        createdAt is! int ||
        tagsRaw is! List) {
      throw FormatException('malformed $what fields');
    }
    final tags = tagsRaw
        .whereType<List<dynamic>>()
        .map((t) => t.map((e) => '$e').toList())
        .toList();

    final id = canonicalEventId(
      pubkey: pubkey,
      createdAt: createdAt,
      kind: kind,
      tags: tags,
      content: content,
    );
    final embedded = m['id'];
    if (embedded != id) {
      throw FormatException('$what id does not match its content');
    }
    final sig = m['sig'];
    return (
      id: id,
      event: Nip01Event(
        id: id,
        pubKey: pubkey,
        kind: kind,
        tags: tags,
        content: content,
        sig: sig is String && sig.isNotEmpty ? sig : null,
        validSig: null,
        createdAt: createdAt,
      ),
    );
  }
}

/// Thrown when a plaintext exceeds the NIP-44 cap at some nesting layer.
class SizeError extends Error {
  final String message;
  SizeError(this.message);

  @override
  String toString() => 'SizeError: $message';
}

/// Signs a NIP-01 event with a raw local secret key — used for derived
/// plane keys and for the identity seal when the app has a local key.
Future<Nip01Event> signWithLocalKey(Nip01Event event, String privateKey) async {
  final id = canonicalEventId(
    pubkey: event.pubKey,
    createdAt: event.createdAt,
    kind: event.kind,
    tags: event.tags,
    content: event.content,
  );
  return event.copyWith(id: id, sig: Bip340.sign(id, privateKey));
}

/// An [EventSigner] wrapper that signs with any raw secret key — handy for
/// derived plane keys where the app has no [EventSigner].
class LocalSecretSigner implements EventSigner {
  final String privateKey;

  LocalSecretSigner({required this.privateKey});

  /// The x-only public key of [privateKey].
  String get xOnlyPubKey => Bip340.getPublicKey(privateKey);

  @override
  Future<Nip01Event> sign(Nip01Event event) =>
      signWithLocalKey(event, privateKey);

  @override
  bool canSign() => true;

  @override
  Future<void> dispose() async {}

  @override
  String getPublicKey() => xOnlyPubKey;

  @override
  Future<String?> decrypt(String msg, String destPubKey) =>
      throw UnimplementedError('nip04 is not used by concord');

  @override
  Future<String?> encrypt(String msg, String destPubKey) =>
      throw UnimplementedError('nip04 is not used by concord');

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) => Nip44.encryptMessage(plaintext, privateKey, recipientPubKey);

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) => Nip44.decryptMessage(ciphertext, privateKey, senderPubKey);

  @override
  List<PendingSignerRequest> get pendingRequests => const [];

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      const Stream.empty();

  @override
  bool cancelRequest(String requestId) => false;

  @override
  bool get requiresInteractiveSigning => false;

  @override
  bool get requiresSignerNetwork => false;

  @override
  Iterable<String> get signerTransportRelayUrls => const [];
}
