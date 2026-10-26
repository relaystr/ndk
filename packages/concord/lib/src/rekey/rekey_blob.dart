import 'dart:convert';
import 'dart:typed_data';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';

// ndk's NIP-44 is marked experimental upstream; the wire format is frozen by
// the NIP itself.
// ignore_for_file: experimental_member_use

import '../core/concord_constants.dart';
import '../core/derivations.dart';
import '../core/encoding.dart';
import '../keys/concord_keys.dart';

/// One located, wrapped key inside a Rekey event (CORD-06 §1).
class RekeyBlob {
  /// Where the recipient finds it: `hkdf(rotator || recipient, …)`.
  final String locator;

  /// Base64 of the NIP-44 ciphertext under the Rotator↔recipient key.
  final String wrapped;

  const RekeyBlob({required this.locator, required this.wrapped});

  Map<String, Object?> toJson() => {'locator': locator, 'wrapped': wrapped};

  static RekeyBlob? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final locator = raw['locator'];
    final wrapped = raw['wrapped'];
    if (locator is! String || wrapped is! String) return null;
    try {
      checkHex32(locator, 'blob locator');
    } catch (_) {
      return null;
    }
    return RekeyBlob(locator: locator, wrapped: wrapped);
  }
}

/// The decrypted key material a blob carries, tagged by its width
/// (CORD-06 §1). The width *is* the form signal — no version field.
sealed class RekeyKeyMaterial {
  final Uint8List scopeId;
  final int epoch;

  const RekeyKeyMaterial({required this.scopeId, required this.epoch});
}

/// A Private Channel's fresh key (72-byte blob).
class ChannelRekeyKey extends RekeyKeyMaterial {
  final Uint8List newKey;

  const ChannelRekeyKey({
    required super.scopeId,
    required super.epoch,
    required this.newKey,
  });
}

/// A base rotation's fresh root (104-byte blob), plus the next epoch's
/// Control Plane keys when present (136-byte staff blob).
class BaseRekeyKey extends RekeyKeyMaterial {
  final Uint8List newRoot;

  /// The Control Plane signer pubkey for the new epoch (104/136-byte forms).
  final Uint8List? newControlPk;

  /// The new `control_root` — staff only (136-byte form).
  final Uint8List? newControlRoot;

  /// True for the legacy 72-byte base blob (pre-split epoch), honored when
  /// reading but never minted.
  final bool legacy;

  const BaseRekeyKey({
    required super.scopeId,
    required super.epoch,
    required this.newRoot,
    this.newControlPk,
    this.newControlRoot,
    this.legacy = false,
  });

  /// A staff blob's `new_control_root` must derive exactly to its
  /// `new_control_pk` (CORD-06 §1) — never adopt a mismatched pair.
  bool controlPairConsistent({required String communityId}) {
    final root = newControlRoot;
    final pk = newControlPk;
    if (root == null || pk == null) return true;
    return Planes.controlSignerPk(
          controlRoot: root,
          communityId: communityId,
          epoch: epoch,
        ) ==
        bytesToHex(pk);
  }
}

/// A parsed Rekey event (kind 3303, CORD-06 §1).
class RekeyEvent {
  final Nip01Event rumor;

  /// The 32-byte rotation scope: a Channel id, or all-zeroes for the base.
  final Uint8List scopeId;
  final int newEpoch;
  final int prevEpoch;
  final String prevCommit;
  final int chunkIndex;
  final int chunkCount;
  final List<RekeyBlob> blobs;

  RekeyEvent({
    required this.rumor,
    required this.scopeId,
    required this.newEpoch,
    required this.prevEpoch,
    required this.prevCommit,
    required this.chunkIndex,
    required this.chunkCount,
    required this.blobs,
  });

  String get rotator => rumor.pubKey;
  bool get isBase => scopeId.every((b) => b == 0);

  /// The rotation's correlation key: `(rotator, newepoch, prevcommit)`.
  String get correlation => '$rotator/$newEpoch/$prevCommit';

  static RekeyEvent? tryParse(Nip01Event rumor) {
    if (rumor.kind != RumorKinds.rekey) return null;

    final scopeHex = _tag(rumor, 'scope');
    final newEpochRaw = _tag(rumor, 'newepoch');
    final prevEpochRaw = _tag(rumor, 'prevepoch');
    final prevCommit = _tag(rumor, 'prevcommit');
    if (scopeHex == null ||
        newEpochRaw == null ||
        prevEpochRaw == null ||
        prevCommit == null) {
      return null;
    }

    final Uint8List scopeId;
    try {
      if (scopeHex.length != 64) return null;
      scopeId = hexToBytes(scopeHex);
      checkHex32(prevCommit, 'prevcommit');
    } catch (_) {
      return null;
    }

    final newEpoch = tryParseDecimal(newEpochRaw);
    final prevEpoch = tryParseDecimal(prevEpochRaw);
    if (newEpoch == null || prevEpoch == null) return null;

    var chunkIndex = 0;
    var chunkCount = 1;
    for (final tag in rumor.tags) {
      if (tag.length >= 3 && tag[0] == 'chunk') {
        final i = tryParseDecimal(tag[1]);
        final n = tryParseDecimal(tag[2]);
        if (i == null || n == null || n < 1 || i < 0 || i >= n) return null;
        chunkIndex = i;
        chunkCount = n;
      }
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(rumor.content);
    } catch (_) {
      return null;
    }
    if (decoded is! List) return null;
    final blobs = <RekeyBlob>[];
    for (final entry in decoded) {
      final blob = RekeyBlob.tryParse(entry);
      if (blob == null) return null;
      blobs.add(blob);
    }

    return RekeyEvent(
      rumor: rumor,
      scopeId: scopeId,
      newEpoch: newEpoch,
      prevEpoch: prevEpoch,
      prevCommit: prevCommit,
      chunkIndex: chunkIndex,
      chunkCount: chunkCount,
      blobs: blobs,
    );
  }

  /// Builds an unsigned kind 3303 rumor for one chunk.
  static Nip01Event buildRumor({
    required String rotator,
    required Uint8List scopeId,
    required int newEpoch,
    required int prevEpoch,
    required String prevCommit,
    required int chunkIndex,
    required int chunkCount,
    required List<RekeyBlob> blobs,
    int? createdAt,
    int? ms,
  }) {
    if (scopeId.length != 32) {
      throw ArgumentError('scope_id must be 32 bytes', 'scopeId');
    }
    final tags = <List<String>>[
      ['scope', bytesToHex(scopeId)],
      ['newepoch', decimalTag(newEpoch)],
      ['prevepoch', decimalTag(prevEpoch)],
      ['prevcommit', prevCommit],
      ['chunk', decimalTag(chunkIndex), decimalTag(chunkCount)],
      if (ms != null) ['ms', decimalTag(ms)],
    ];
    final t = createdAt ?? Nip01Event.secondsSinceEpoch();
    return Nip01Event(
      id: canonicalEventId(
        pubkey: rotator,
        createdAt: t,
        kind: RumorKinds.rekey,
        tags: tags,
        content: encodeJson([for (final b in blobs) b.toJson()]),
      ),
      pubKey: rotator,
      kind: RumorKinds.rekey,
      tags: tags,
      content: encodeJson([for (final b in blobs) b.toJson()]),
      sig: null,
      createdAt: t,
    );
  }

  static String? _tag(Nip01Event e, String name) {
    for (final tag in e.tags) {
      if (tag.length >= 2 && tag[0] == name) return tag[1];
    }
    return null;
  }
}

/// Building and applying rekeys (CORD-06 §1–2).
class Rekeys {
  const Rekeys._();

  /// Builds a Channel rotation: one Rekey event per 120-recipient chunk.
  ///
  /// Each recipient gets a 72-byte blob. The event is sealed and wrapped at
  /// the next Channel-epoch's rekey address by the caller.
  static Future<List<RekeyEvent>> buildChannelRotation({
    required EventSigner rotator,
    required Uint8List scopeId,
    required int newEpoch,
    required int prevEpoch,
    required Uint8List prevKey,
    required Uint8List newKey,
    required List<String> recipients,
    int? createdAt,
  }) async {
    final rotatorPk = rotator.getPublicKey();
    final prevCommit = epochKeyCommitment(
      prevEpoch: prevEpoch,
      prevKey: bytesToHex(prevKey),
    );
    final plaintext = concatBytes([
      scopeId,
      u64Be(newEpoch),
      newKey,
    ]); // 72 bytes
    return _chunkAndWrap(
      rotator: rotator,
      rotatorPk: rotatorPk,
      scopeId: scopeId,
      newEpoch: newEpoch,
      prevEpoch: prevEpoch,
      prevCommit: prevCommit,
      recipients: recipients,
      plaintextFor: (recipient) => plaintext,
      createdAt: createdAt,
    );
  }

  /// Builds a base rotation (Refounding's key roll). Every member receives a
  /// 104-byte blob; staff recipients additionally receive the new
  /// `control_root` (136 bytes).
  static Future<List<RekeyEvent>> buildBaseRotation({
    required EventSigner rotator,
    required int newEpoch,
    required int prevEpoch,
    required Uint8List prevRoot,
    required Uint8List newRoot,
    required Uint8List newControlPk,
    Uint8List? newControlRoot,
    required List<String> members,
    Set<String> staffRecipients = const {},
    int? createdAt,
  }) async {
    final rotatorPk = rotator.getPublicKey();
    final scopeId = baseScopeId();
    final prevCommit = epochKeyCommitment(
      prevEpoch: prevEpoch,
      prevKey: bytesToHex(prevRoot),
    );
    final memberPlain = concatBytes([
      scopeId,
      u64Be(newEpoch),
      newRoot,
      newControlPk,
    ]); // 104 bytes
    final staffPlain = newControlRoot == null
        ? null
        : concatBytes([
            scopeId,
            u64Be(newEpoch),
            newRoot,
            newControlPk,
            newControlRoot,
          ]); // 136 bytes

    return _chunkAndWrap(
      rotator: rotator,
      rotatorPk: rotatorPk,
      scopeId: scopeId,
      newEpoch: newEpoch,
      prevEpoch: prevEpoch,
      prevCommit: prevCommit,
      recipients: members,
      plaintextFor: (recipient) =>
          staffRecipients.contains(recipient) && staffPlain != null
          ? staffPlain
          : memberPlain,
      createdAt: createdAt,
    );
  }

  static Future<List<RekeyEvent>> _chunkAndWrap({
    required EventSigner rotator,
    required String rotatorPk,
    required Uint8List scopeId,
    required int newEpoch,
    required int prevEpoch,
    required String prevCommit,
    required List<String> recipients,
    required Uint8List Function(String recipient) plaintextFor,
    int? createdAt,
  }) async {
    final chunks = <List<String>>[];
    for (var i = 0; i < recipients.length; i += Caps.rekeyBlobRecipients) {
      chunks.add(
        recipients.sublist(
          i,
          (i + Caps.rekeyBlobRecipients).clamp(0, recipients.length),
        ),
      );
    }
    if (chunks.isEmpty) chunks.add(const []);

    final events = <RekeyEvent>[];
    for (var i = 0; i < chunks.length; i++) {
      final blobs = <RekeyBlob>[];
      for (final recipient in chunks[i]) {
        final locator = recipientLocator(
          rotatorXonly: rotatorPk,
          recipientXonly: recipient,
          scopeId: scopeId,
          epoch: newEpoch,
        );
        final ciphertext = await rotator.encryptNip44(
          plaintext: base64.encode(plaintextFor(recipient)),
          recipientPubKey: recipient,
        );
        if (ciphertext == null) {
          throw StateError('the rotator refused to wrap a blob');
        }
        blobs.add(
          RekeyBlob(
            locator: locator,
            wrapped: base64.encode(utf8.encode(ciphertext)),
          ),
        );
      }
      final rumor = RekeyEvent.buildRumor(
        rotator: rotatorPk,
        scopeId: scopeId,
        newEpoch: newEpoch,
        prevEpoch: prevEpoch,
        prevCommit: prevCommit,
        chunkIndex: i,
        chunkCount: chunks.length,
        blobs: blobs,
        createdAt: createdAt,
      );
      events.add(RekeyEvent.tryParse(rumor)!);
    }
    return events;
  }

  /// Finds the locator of [recipient] within [event].
  static RekeyBlob? findMyBlob({
    required RekeyEvent event,
    required String recipientXonly,
  }) {
    final mine = recipientLocator(
      rotatorXonly: event.rotator,
      recipientXonly: recipientXonly,
      scopeId: event.scopeId,
      epoch: event.newEpoch,
    );
    for (final blob in event.blobs) {
      if (blob.locator == mine) return blob;
    }
    return null;
  }

  /// Decrypts and validates a blob. Returns null when the width is malformed
  /// or the embedded scope/epoch disagree with the event (a spliced blob).
  ///
  /// For a staff blob the caller must additionally check that
  /// `new_control_root` derives to `new_control_pk` — see
  /// [BaseRekeyKey.controlPairConsistent].
  static Future<RekeyKeyMaterial?> decryptBlob({
    required RekeyEvent event,
    required RekeyBlob blob,
    required EventSigner recipient,
    bool verifyScope = true,
  }) async {
    final String decrypted;
    try {
      decrypted = (await recipient.decryptNip44(
        ciphertext: utf8.decode(base64.decode(blob.wrapped)),
        senderPubKey: event.rotator,
      ))!;
    } catch (_) {
      return null;
    }
    final Uint8List plain;
    try {
      plain = base64.decode(decrypted);
    } catch (_) {
      return null;
    }
    if (plain.length < 40) return null;

    final scopeId = Uint8List.sublistView(plain, 0, 32);
    final epoch = u64BeDecode(plain, 32);

    if (verifyScope) {
      if (epoch != event.newEpoch) return null;
      if (!_sameBytes(scopeId, event.scopeId)) return null;
    }

    switch (plain.length) {
      case Caps.channelBlobBytes: // 72
        final tail = Uint8List.sublistView(plain, 40, 72);
        if (event.isBase) {
          // Legacy pre-split base blob.
          return BaseRekeyKey(
            scopeId: scopeId,
            epoch: epoch,
            newRoot: tail,
            legacy: true,
          );
        }
        return ChannelRekeyKey(scopeId: scopeId, epoch: epoch, newKey: tail);
      case Caps.baseBlobBytes: // 104
        return BaseRekeyKey(
          scopeId: scopeId,
          epoch: epoch,
          newRoot: Uint8List.sublistView(plain, 40, 72),
          newControlPk: Uint8List.sublistView(plain, 72, 104),
        );
      case Caps.baseBlobStaffBytes: // 136
        return BaseRekeyKey(
          scopeId: scopeId,
          epoch: epoch,
          newRoot: Uint8List.sublistView(plain, 40, 72),
          newControlPk: Uint8List.sublistView(plain, 72, 104),
          newControlRoot: Uint8List.sublistView(plain, 104, 136),
        );
      default:
        return null; // any other width is malformed
    }
  }

  /// Verifies the continuity field: the commitment over the key the receiver
  /// currently holds must equal the event's `prevcommit`.
  static bool continuityHolds({
    required RekeyEvent event,
    required Uint8List heldKey,
  }) =>
      epochKeyCommitment(
        prevEpoch: event.prevEpoch,
        prevKey: bytesToHex(heldKey),
      ) ==
      event.prevCommit;

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
