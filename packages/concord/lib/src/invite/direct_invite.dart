import 'dart:convert';
import 'dart:math';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';

// ndk's NIP-44 is marked experimental upstream; the wire format is frozen by
// the NIP itself.
// ignore_for_file: experimental_member_use

import '../core/concord_constants.dart';
import '../core/encoding.dart';
import 'community_invite.dart';

/// A parsed Direct Invite (CORD-05 §6): the standard NIP-59 wrap plus the
/// CommunityInvite bundle inside it.
class DirectInvite {
  final Nip01Event wrap;
  final Nip01Event seal;
  final Nip01Event rumor;
  final CommunityInvite invite;

  const DirectInvite({
    required this.wrap,
    required this.seal,
    required this.rumor,
    required this.invite,
  });

  /// The inviter's real pubkey — proven by the seal's signature.
  String get inviter => seal.pubKey;
}

/// Direct Invites drop the link machinery and hand the bundle straight to a
/// known npub over a **standard** NIP-59 giftwrap (CORD-05 §6) — the
/// person-addressed cousin of the reversed stream wrap, carrying the
/// identifying `k` tag the stream wrap may not.
class DirectInvites {
  static final Random _random = Random.secure();

  /// The `k` tag value that makes invites indexable: `#k: ["3313"]`.
  static const String kTagValue = '3313';

  /// Builds the kind 1059 wrap for [invite] addressed to [recipientPubkey].
  ///
  /// The seal is signed by [senderSigner] (a local key or a NIP-46 remote
  /// signer both fit); the wrap is signed by a single-use ephemeral key.
  /// [sealCreatedAt]/[wrapCreatedAt] are exposed for deterministic tests;
  /// when null they carry NIP-59's timestamp tweak (randomized into the two
  /// days before the rumor).
  static Future<Nip01Event> build({
    required CommunityInvite invite,
    required EventSigner senderSigner,
    required String recipientPubkey,
    int? rumourCreatedAt,
    int? sealCreatedAt,
    int? wrapCreatedAt,
    String? ephemeralSk,
  }) async {
    checkHex32(recipientPubkey, 'recipient pubkey');
    final senderPubkey = senderSigner.getPublicKey();
    checkHex32(senderPubkey, 'sender pubkey');

    final rumorTime = rumourCreatedAt ?? Nip01Event.secondsSinceEpoch();
    final inviteJson = invite.toJsonString();

    // Layer 3 — the rumor (unsigned, kind 3313).
    final rumorId = canonicalEventId(
      pubkey: senderPubkey,
      createdAt: rumorTime,
      kind: RumorKinds.directInvite,
      tags: const [],
      content: inviteJson,
    );

    // Layer 2 — the seal (kind 13), NIP-44 from sender to recipient.
    final rumorJson = canonicalEventJson(
      id: rumorId,
      kind: RumorKinds.directInvite,
      pubkey: senderPubkey,
      content: inviteJson,
      tags: const [],
      createdAt: rumorTime,
    );
    final sealContent = await senderSigner.encryptNip44(
      plaintext: rumorJson,
      recipientPubKey: recipientPubkey,
    );
    if (sealContent == null) {
      throw StateError('the signer refused to encrypt the seal');
    }
    final sealTime = sealCreatedAt ?? _tweaked(rumorTime);
    final sealId = canonicalEventId(
      pubkey: senderPubkey,
      createdAt: sealTime,
      kind: Kinds.nip59Seal,
      tags: const [],
      content: sealContent,
    );
    final seal = await senderSigner.sign(
      Nip01Event(
        id: sealId,
        pubKey: senderPubkey,
        kind: Kinds.nip59Seal,
        tags: const [],
        content: sealContent,
        sig: null,
        createdAt: sealTime,
      ),
    );
    if (seal.sig == null || seal.sig!.isEmpty) {
      throw StateError('the signer returned an unsigned seal');
    }

    // Layer 1 — the wrap (kind 1059), NIP-44 from the ephemeral key.
    final eph = _ephemeralKeyPair(ephemeralSk);
    final sealJson = canonicalEventJson(
      id: seal.id,
      kind: seal.kind,
      pubkey: seal.pubKey,
      content: seal.content,
      tags: seal.tags,
      createdAt: seal.createdAt,
      sig: seal.sig,
    );
    final wrapContent = await Nip44.encryptMessage(
      sealJson,
      eph.sk,
      recipientPubkey,
    );
    final wrapTime = wrapCreatedAt ?? _tweaked(sealTime);
    final wrapTags = <List<String>>[
      ['p', recipientPubkey],
      ['k', kTagValue],
    ];
    final wrapId = canonicalEventId(
      pubkey: eph.pubkey,
      createdAt: wrapTime,
      kind: Kinds.streamWrap,
      tags: wrapTags,
      content: wrapContent,
    );
    return Nip01Event(
      id: wrapId,
      pubKey: eph.pubkey,
      kind: Kinds.streamWrap,
      tags: wrapTags,
      content: wrapContent,
      sig: Bip340.sign(wrapId, eph.sk),
      createdAt: wrapTime,
    );
  }

  /// Unwraps a kind 1059 Direct Invite with the recipient's signer. Throws
  /// [FormatException] on any failure — the caller drops the event.
  static Future<DirectInvite> unwrap({
    required Nip01Event wrap,
    required EventSigner recipientSigner,
    bool verifySignatures = true,
  }) async {
    if (wrap.kind != Kinds.streamWrap) {
      throw FormatException('not a giftwrap (kind ${wrap.kind})');
    }
    final me = recipientSigner.getPublicKey();
    final pTag = _tag(wrap, 'p');
    if (pTag != null && pTag != me) {
      throw FormatException('giftwrap is not addressed to this key');
    }
    if (verifySignatures &&
        (wrap.sig == null || !_sigValid(wrap.id, wrap.sig!, wrap.pubKey))) {
      throw FormatException('invalid giftwrap signature');
    }

    final String sealJson;
    try {
      sealJson = (await recipientSigner.decryptNip44(
        ciphertext: wrap.content,
        senderPubKey: wrap.pubKey,
      ))!;
    } catch (e) {
      throw FormatException('cannot open giftwrap: $e');
    }
    final seal = _parseEvent(sealJson, what: 'seal');
    if (seal.kind != Kinds.nip59Seal) {
      throw FormatException('unexpected seal kind ${seal.kind}');
    }
    if (verifySignatures &&
        (seal.sig == null || !_sigValid(seal.id, seal.sig!, seal.pubKey))) {
      throw FormatException('invalid seal signature');
    }

    final String rumorJson;
    try {
      rumorJson = (await recipientSigner.decryptNip44(
        ciphertext: seal.content,
        senderPubKey: seal.pubKey,
      ))!;
    } catch (e) {
      throw FormatException('cannot open seal: $e');
    }
    final rumor = _parseEvent(rumorJson, what: 'rumor');
    if (rumor.kind != RumorKinds.directInvite) {
      throw FormatException('not a direct invite (kind ${rumor.kind})');
    }
    // NIP-59 impersonation check.
    if (rumor.pubKey != seal.pubKey) {
      throw FormatException('invite author does not match the seal signer');
    }

    final invite = CommunityInvite.tryParse(rumor.content);
    if (invite == null) {
      throw FormatException('invite bundle refused (bounds or owner check)');
    }
    return DirectInvite(wrap: wrap, seal: seal, rumor: rumor, invite: invite);
  }

  /// Parses a NIP-01 event JSON string, recomputing its id.
  static Nip01Event _parseEvent(String jsonString, {required String what}) {
    final Object? raw;
    try {
      raw = jsonDecode(jsonString);
    } catch (_) {
      throw FormatException('unreadable $what JSON');
    }
    if (raw is! Map) throw FormatException('$what is not an event object');
    final decoded = raw;
    final pubkey = decoded['pubkey'];
    final content = decoded['content'];
    final kind = decoded['kind'];
    final createdAt = decoded['created_at'];
    final tagsRaw = decoded['tags'];
    if (pubkey is! String ||
        content is! String ||
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
    if (decoded['id'] != id) {
      throw FormatException('$what id does not match its content');
    }
    final sig = decoded['sig'];
    return Nip01Event(
      id: id,
      pubKey: pubkey,
      kind: kind,
      tags: tags,
      content: content,
      sig: sig is String && sig.isNotEmpty ? sig : null,
      createdAt: createdAt,
    );
  }

  static String? _tag(Nip01Event event, String name) {
    for (final tag in event.tags) {
      if (tag.length >= 2 && tag[0] == name) return tag[1];
    }
    return null;
  }

  /// Verifies a Schnorr signature, treating malformed input (wrong length,
  /// non-hex) as invalid rather than letting it throw — events arrive from
  /// untrusted relays.
  static bool _sigValid(String id, String sig, String pubkey) {
    try {
      return Bip340.verify(id, sig, pubkey);
    } catch (_) {
      return false;
    }
  }

  /// NIP-59's timestamp tweak: a random time in the two days before
  /// [reference].
  static int _tweaked(int reference) => reference - _random.nextInt(172800) - 1;

  static ({String sk, String pubkey}) _ephemeralKeyPair(String? skOrNull) {
    if (skOrNull != null) {
      checkHex32(skOrNull, 'ephemeral key');
      return (sk: skOrNull, pubkey: Bip340.getPublicKey(skOrNull));
    }
    final kp = Bip340.generatePrivateKey();
    return (sk: kp.privateKey!, pubkey: kp.publicKey);
  }
}
