import 'dart:typed_data';

import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';

// The ndk NIP-44 implementation is marked experimental upstream; the wire
// format it produces is frozen by the NIP itself.
// ignore_for_file: experimental_member_use

import 'encoding.dart';
import 'hkdf.dart';

/// secp256k1 group order `n` (frozen constant).
const String _secp256k1OrderHex =
    'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141';

final BigInt _secp256k1Order = BigInt.parse(_secp256k1OrderHex, radix: 16);

/// A derived stream keypair plus its NIP-44 conversation key
/// (CORD-02 A.2 `group_key`).
class GroupKey {
  /// Secret scalar, 64 lowercase hex characters.
  final String sk;

  /// x-only public key — the on-wire stream address.
  final String pk;

  /// `nip44_conversation_key(sk, pk)`: self-ECDH; encrypts stream wraps.
  final Uint8List convKey;

  const GroupKey({required this.sk, required this.pk, required this.convKey});
}

/// Whether [seed] is a valid secp256k1 secret scalar: `1 <= seed < n`.
bool isValidScalar(Uint8List seed) {
  final value = bytesToBigInt(seed);
  return value != BigInt.zero && value < _secp256k1Order;
}

BigInt bytesToBigInt(Uint8List bytes) =>
    bytes.fold<BigInt>(BigInt.zero, (a, b) => (a << 8) | BigInt.from(b));

/// Builds the HKDF info block for a labeled derivation (CORD-02 A.1/A.6).
///
/// `info = utf8(label) || 0x00 || id[32] || epoch_be[8]`, where the epoch is
/// present only for labels that carry one (per A.6). [retryCounter], when
/// non-null, appends the scalar_normalize counter byte (A.3).
Uint8List derivationInfo({
  required String label,
  required Uint8List id,
  int? epoch,
  int? retryCounter,
}) {
  if (id.length != 32) {
    throw ArgumentError('id must be a raw 32-byte value', 'id');
  }
  return concatBytes([
    labelBytes(label),
    const <int>[0x00],
    id,
    if (epoch != null) u64Be(epoch),
    if (retryCounter != null) <int>[retryCounter],
  ]);
}

/// `group_key(label, secret, id, epoch)` (CORD-02 A.2):
///
/// ```text
/// seed     = hkdf(secret, label, id, epoch)
/// sk       = scalar_normalize(seed)          // A.3 retry loop
/// pk       = xonly_pubkey(sk)                // the stream address
/// conv_key = nip44_conversation_key(sk, pk)  // self-ECDH
/// ```
GroupKey groupKey({
  required Uint8List secret,
  required String label,
  required Uint8List id,
  int? epoch,
  Uint8List Function(Uint8List info)? debugHkdf,
}) {
  final sk = scalarNormalize(
    ikm: secret,
    label: label,
    id: id,
    epoch: epoch,
    debugHkdf: debugHkdf,
  );
  final pk = Bip340.getPublicKey(sk);
  final convKey = Nip44.deriveConversationKey(
    Nip44.computeSharedSecret(sk, pk),
  );
  return GroupKey(sk: sk, pk: pk, convKey: convKey);
}

/// `scalar_normalize` (CORD-02 A.3): if the hkdf seed is not a valid
/// secp256k1 scalar, append one incrementing counter byte to the info and
/// retry, the counter starting at 0. Returns the secret as 64 hex chars.
///
/// [debugHkdf] overrides the seed derivation so tests can drive the retry
/// branch (the reject branch is ~2^-128 in production).
String scalarNormalize({
  required Uint8List ikm,
  required String label,
  required Uint8List id,
  int? epoch,
  Uint8List Function(Uint8List info)? debugHkdf,
}) {
  int? counter;
  var guard = 0;
  while (true) {
    final info = derivationInfo(
      label: label,
      id: id,
      epoch: epoch,
      retryCounter: counter,
    );
    final seed = debugHkdf != null
        ? debugHkdf(info)
        : hkdfSha256(ikm: ikm, info: info);
    if (seed.length != 32) {
      throw StateError('hkdf must produce a 32-byte seed');
    }
    if (isValidScalar(seed)) {
      return bytesToHex(seed);
    }
    // A.3: append an incrementing counter byte and retry, starting at 0.
    counter = (counter == null) ? 0 : counter + 1;
    if (++guard > 255) {
      throw StateError('scalar_normalize exhausted its retry counter');
    }
  }
}

/// `community_id = sha256("concord/community" || owner_xonly || owner_salt)`
/// (CORD-02 §1, A.4). The only derivation that is a plain SHA-256
/// commitment, not the hkdf construction.
String communityId({required String ownerXonly, required Uint8List ownerSalt}) {
  checkHex32(ownerXonly, 'owner pubkey');
  if (ownerSalt.length != 32) {
    throw ArgumentError('owner_salt must be 32 bytes', 'ownerSalt');
  }
  return sha256Hex(
    concatBytes([
      labelBytes('concord/community'),
      hexToBytes(ownerXonly),
      ownerSalt,
    ]),
  );
}

/// `prevcommit = sha256("concord/epoch-key-commitment" || prev_epoch_be ||
/// prev_key[32])` (CORD-02 A.5) — the rekey continuity check.
String epochKeyCommitment({required int prevEpoch, required String prevKey}) {
  checkHex32(prevKey, 'prev_key');
  return sha256Hex(
    concatBytes([
      labelBytes('concord/epoch-key-commitment'),
      u64Be(prevEpoch),
      hexToBytes(prevKey),
    ]),
  );
}

/// `locator = hkdf(rotator_xonly ‖ recipient_xonly,
/// "concord/recipient-pseudonym", scope_id, epoch)` (CORD-06 §2).
///
/// Plain hkdf — not `group_key`: the output is an opaque search string,
/// not a keypair.
String recipientLocator({
  required String rotatorXonly,
  required String recipientXonly,
  required Uint8List scopeId,
  required int epoch,
}) {
  checkHex32(rotatorXonly, 'rotator pubkey');
  checkHex32(recipientXonly, 'recipient pubkey');
  if (scopeId.length != 32) {
    throw ArgumentError('scope_id must be 32 bytes', 'scopeId');
  }
  final seed = hkdfSha256(
    ikm: concatBytes([hexToBytes(rotatorXonly), hexToBytes(recipientXonly)]),
    info: derivationInfo(
      label: 'concord/recipient-pseudonym',
      id: scopeId,
      epoch: epoch,
    ),
  );
  return bytesToHex(seed);
}

/// All-zeroes scope id for base (community_root) rotations (CORD-06 §1).
Uint8List baseScopeId() => Uint8List(32);

/// Deterministic entity coordinates (CORD-02 A.6 + CORD-04 §1 table).
class Locators {
  /// Grant coordinate `eid` for a member.
  static String grant(String communityIdHex, String memberXonly) => _eid(
    label: 'concord/grant',
    communityIdHex: communityIdHex,
    id: hexToBytes(memberXonly),
  );

  /// Banlist coordinate `eid`.
  static String banlist(String communityIdHex) => _eid(
    label: 'concord/banlist',
    communityIdHex: communityIdHex,
    id: Uint8List(32),
  );

  /// Pin List coordinate `eid` (reserved, CORD-04 §7).
  static String pins(String communityIdHex, String channelIdHex) => _eid(
    label: 'concord/pins',
    communityIdHex: communityIdHex,
    id: hexToBytes(channelIdHex),
  );

  /// Invite-link registry coordinate `eid` (reserved, CORD-05 §5).
  static String inviteLinks(String communityIdHex, String creatorXonly) => _eid(
    label: 'concord/invite-links',
    communityIdHex: communityIdHex,
    id: hexToBytes(creatorXonly),
  );

  /// The dissolution tombstone plane address (CORD-02 §9) — derives from the
  /// `community_id` with no secret, readable and signable by anyone holding
  /// the id; only the owner's signature counts.
  static String dissolvedPk(String communityIdHex) => groupKey(
    secret: hexToBytes(communityIdHex),
    label: 'concord/dissolved',
    id: Uint8List(32),
  ).pk;

  static String _eid({
    required String label,
    required String communityIdHex,
    required Uint8List id,
  }) {
    checkHex32(communityIdHex, 'community_id');
    return groupKey(
      secret: hexToBytes(communityIdHex),
      label: label,
      id: id,
    ).pk;
  }
}
