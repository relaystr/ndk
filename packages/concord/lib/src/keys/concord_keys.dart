import 'dart:typed_data';

import '../core/concord_constants.dart';
import '../core/derivations.dart' as deriv;
import '../core/encoding.dart';
import '../stream/stream_envelope.dart';

/// One Channel's key material (CORD-03).
///
/// A **Public** Channel derives its stream key from the `community_root`
/// ([private] is false, [key] unused). A **Private** Channel has its own
/// random 32-byte [key], cryptographically unrelated to the root, and
/// rotates on its own [epoch].
class ChannelKey {
  final String channelId;
  final bool private;
  final int epoch;

  /// The Private Channel key (32 bytes). Null for a Public Channel.
  final Uint8List? key;

  const ChannelKey({
    required this.channelId,
    required this.private,
    required this.epoch,
    this.key,
  });

  ChannelKey next(Uint8List newKey) => ChannelKey(
    channelId: channelId,
    private: private,
    epoch: epoch + 1,
    key: newKey,
  );
}

/// Everything a member needs to read and write a Community (CORD-02 §2,
/// §7).
///
/// Holding this *is* membership. It carries the base [communityRoot], the
/// held [controlPk] (never derived by a non-staffer — it is delivered), and
/// the Private Channel keys the member was granted. Staff additionally hold
/// [controlRoot].
class CommunityKeys {
  final String communityId;

  /// The owner's x-only pubkey, verifiable against [ownerSalt] through
  /// `community_id` (CORD-02 §1).
  final String owner;

  /// Not secret; travels in invites so any member can confirm the founder.
  final Uint8List ownerSalt;

  /// The base epoch attached to [communityRoot].
  final int rootEpoch;

  /// The private access key. Rotates at every Refounding.
  final Uint8List communityRoot;

  /// The current Control Plane address. Held, never derived (§2).
  final String controlPk;

  /// The epoch [controlPk] belongs to.
  final int controlEpoch;

  /// Staff write secret. Null for a regular member.
  final Uint8List? controlRoot;

  final Map<String, ChannelKey> channels;

  final List<String> relays;

  /// A display-name snapshot from the invite (the fold is the authority).
  final String? name;

  const CommunityKeys({
    required this.communityId,
    required this.owner,
    required this.ownerSalt,
    required this.rootEpoch,
    required this.communityRoot,
    required this.controlPk,
    required this.controlEpoch,
    this.controlRoot,
    this.channels = const {},
    this.relays = const [],
    this.name,
  });

  bool get isStaff => controlRoot != null;

  CommunityKeys copyWith({
    int? rootEpoch,
    Uint8List? communityRoot,
    String? controlPk,
    int? controlEpoch,
    Uint8List? controlRoot,
    Map<String, ChannelKey>? channels,
    List<String>? relays,
    String? name,
  }) => CommunityKeys(
    communityId: communityId,
    owner: owner,
    ownerSalt: ownerSalt,
    rootEpoch: rootEpoch ?? this.rootEpoch,
    communityRoot: communityRoot ?? this.communityRoot,
    controlPk: controlPk ?? this.controlPk,
    controlEpoch: controlEpoch ?? this.controlEpoch,
    controlRoot: controlRoot ?? this.controlRoot,
    channels: channels ?? this.channels,
    relays: relays ?? this.relays,
    name: name ?? this.name,
  );

  ChannelKey? channel(String channelId) => channels[channelId];

  /// Recomputes the community id and compares — the invite's self-check.
  bool verifiesOwner() =>
      communityId == deriv.communityId(ownerXonly: owner, ownerSalt: ownerSalt);

  /// The join material of CORD-05 §1 / CORD-02 §8: the membership subset a
  /// bundle and the Community List both carry (never the icon or link
  /// fields). `control_root` rides along only when the holder has it.
  Map<String, Object?> toJoinMaterial() => {
    'community_id': communityId,
    'owner': owner,
    'owner_salt': bytesToHex(ownerSalt),
    'community_root': bytesToHex(communityRoot),
    'root_epoch': rootEpoch,
    if (controlPk.isNotEmpty) 'control_pk': controlPk,
    'channels': [
      for (final c in channels.values)
        {
          'id': c.channelId,
          if (c.key != null) 'key': bytesToHex(c.key!),
          'epoch': c.epoch,
        },
    ],
    'relays': relays,
    if (name != null) 'name': name,
    if (controlRoot != null) 'control_root': bytesToHex(controlRoot!),
  };

  /// Parses join material, applying the owner self-check. When
  /// [expectedCommunityId] is given it must match.
  static CommunityKeys? fromJoinMaterial(
    Object? raw, {
    String? expectedCommunityId,
  }) {
    if (raw is! Map) return null;
    final communityId = raw['community_id'];
    final owner = raw['owner'];
    final ownerSaltRaw = raw['owner_salt'];
    final rootRaw = raw['community_root'];
    final rootEpochRaw = raw['root_epoch'];
    if (communityId is! String ||
        owner is! String ||
        ownerSaltRaw is! String ||
        rootRaw is! String ||
        rootEpochRaw is! int) {
      return null;
    }
    if (expectedCommunityId != null && communityId != expectedCommunityId) {
      return null;
    }
    try {
      checkHex32(communityId, 'community_id');
      checkHex32(owner, 'owner');
    } catch (_) {
      return null;
    }
    final Uint8List ownerSalt;
    final Uint8List communityRoot;
    try {
      ownerSalt = hexToBytes(ownerSaltRaw);
      communityRoot = hexToBytes(rootRaw);
    } catch (_) {
      return null;
    }
    if (ownerSalt.length != 32 || communityRoot.length != 32) return null;
    if (rootEpochRaw < 0) return null;

    final controlPk = raw['control_pk'];
    if (controlPk != null) {
      if (controlPk is! String) return null;
      try {
        checkHex32(controlPk, 'control_pk');
      } catch (_) {
        return null;
      }
    }
    Uint8List? controlRoot;
    final controlRootRaw = raw['control_root'];
    if (controlRootRaw != null) {
      if (controlRootRaw is! String) return null;
      try {
        controlRoot = hexToBytes(controlRootRaw);
      } catch (_) {
        return null;
      }
      if (controlRoot.length != 32) return null;
    }

    final channels = <String, ChannelKey>{};
    final channelsRaw = raw['channels'];
    if (channelsRaw is List) {
      if (channelsRaw.length > Caps.inviteBundleChannels) return null;
      for (final entry in channelsRaw) {
        if (entry is! Map) return null;
        final id = entry['id'];
        if (id is! String) return null;
        try {
          checkHex32(id, 'channel id');
        } catch (_) {
          return null;
        }
        Uint8List? key;
        final keyRaw = entry['key'];
        if (keyRaw != null) {
          if (keyRaw is! String) return null;
          try {
            key = hexToBytes(keyRaw);
          } catch (_) {
            return null;
          }
          if (key.length != 32) return null;
        }
        final epochRaw = entry['epoch'];
        final epoch = epochRaw is int ? epochRaw : tryParseDecimal('$epochRaw');
        if (epoch == null || epoch < 0) return null;
        channels[id] = ChannelKey(
          channelId: id,
          private: key != null,
          epoch: epoch,
          key: key,
        );
      }
    }

    final relaysRaw = raw['relays'];
    final relays = relaysRaw is List
        ? relaysRaw.whereType<String>().take(Caps.communityRelays).toList()
        : const <String>[];
    final name = raw['name'];

    final keys = CommunityKeys(
      communityId: communityId,
      owner: owner,
      ownerSalt: ownerSalt,
      rootEpoch: rootEpochRaw,
      communityRoot: communityRoot,
      controlPk: controlPk as String? ?? '',
      controlEpoch: rootEpochRaw,
      controlRoot: controlRoot,
      channels: channels,
      relays: relays,
      name: name is String ? name : null,
    );
    if (!keys.verifiesOwner()) return null;
    return keys;
  }
}

/// All plane derivations a member performs (CORD-02 §5, Appendix A.6).
class Planes {
  const Planes._();

  /// `control_pk = group_key("concord/control-signer", control_root,
  /// community_id, epoch).pk` — the address a staff member derives.
  static String controlSignerPk({
    required Uint8List controlRoot,
    required String communityId,
    required int epoch,
  }) => deriv
      .groupKey(
        secret: controlRoot,
        label: Labels.controlSigner,
        id: hexToBytes(communityId),
        epoch: epoch,
      )
      .pk;

  /// The stripped Control Plane *read* key every member derives.
  static deriv.GroupKey controlReadKey({
    required Uint8List communityRoot,
    required String communityId,
    required int epoch,
  }) => deriv.groupKey(
    secret: communityRoot,
    label: Labels.control,
    id: hexToBytes(communityId),
    epoch: epoch,
  );

  /// The pre-split Control Plane key: address and signer *and* encryption
  /// all in one (CORD-02 §5 "Legacy epochs"). Retained for reading.
  static deriv.GroupKey legacyControlKey({
    required Uint8List communityRoot,
    required String communityId,
    required int epoch,
  }) => controlReadKey(
    communityRoot: communityRoot,
    communityId: communityId,
    epoch: epoch,
  );

  /// The write keys for the Control Plane: the staff signer + the member
  /// read key. Throws when the member holds no `control_root`.
  static PlaneKeys controlWriteKeys(CommunityKeys keys, {int? epoch}) {
    final controlRoot = keys.controlRoot;
    if (controlRoot == null) {
      throw StateError('no control_root: this member cannot write to Control');
    }
    final e = epoch ?? keys.controlEpoch;
    final signer = deriv.groupKey(
      secret: controlRoot,
      label: Labels.controlSigner,
      id: hexToBytes(keys.communityId),
      epoch: e,
    );
    final read = controlReadKey(
      communityRoot: keys.communityRoot,
      communityId: keys.communityId,
      epoch: e,
    );
    return PlaneKeys(
      signerSk: signer.sk,
      signerPk: signer.pk,
      convKey: read.convKey,
    );
  }

  /// The read-side keys for the Control Plane. [heldControlPk] is the
  /// address the member subscribes at (from an invite, the List or a base
  /// rekey); [legacy] selects the pre-split derivation.
  static PlaneKeys controlReadKeys(
    CommunityKeys keys, {
    required String heldControlPk,
    bool legacy = false,
    int? epoch,
  }) {
    final e = epoch ?? keys.controlEpoch;
    final read = legacy
        ? legacyControlKey(
            communityRoot: keys.communityRoot,
            communityId: keys.communityId,
            epoch: e,
          )
        : controlReadKey(
            communityRoot: keys.communityRoot,
            communityId: keys.communityId,
            epoch: e,
          );
    return PlaneKeys(
      signerSk: read.sk,
      signerPk: legacy ? read.pk : heldControlPk,
      convKey: read.convKey,
    );
  }

  /// A Channel's group key (CORD-03, A.6): Private Channels derive from
  /// their own key, Public Channels from the `community_root`.
  static deriv.GroupKey channelKey(CommunityKeys keys, String channelId) {
    final channel = keys.channels[channelId];
    final secret = (channel != null && channel.private)
        ? channel.key!
        : keys.communityRoot;
    final epoch = channel?.epoch ?? keys.rootEpoch;
    return deriv.groupKey(
      secret: secret,
      label: Labels.channel,
      id: hexToBytes(channelId),
      epoch: epoch,
    );
  }

  /// The Guestbook Plane group key (CORD-02 §5).
  static deriv.GroupKey guestbookKey(CommunityKeys keys, {int? epoch}) =>
      deriv.groupKey(
        secret: keys.communityRoot,
        label: Labels.guestbook,
        id: hexToBytes(keys.communityId),
        epoch: epoch ?? keys.rootEpoch,
      );

  /// The next base-rotation address (CORD-06 §2).
  static String nextBaseRekeyAddress(CommunityKeys keys) => deriv
      .groupKey(
        secret: keys.communityRoot,
        label: Labels.baseRekeyPseudonym,
        id: hexToBytes(keys.communityId),
        epoch: keys.rootEpoch + 1,
      )
      .pk;

  /// The next Channel-rotation address for a Private Channel (CORD-06 §2).
  static String nextChannelRekeyAddress(
    CommunityKeys keys,
    ChannelKey channel,
  ) => deriv
      .groupKey(
        secret: keys.communityRoot,
        label: Labels.rekeyPseudonym,
        id: hexToBytes(channel.channelId),
        epoch: channel.epoch + 1,
      )
      .pk;
}
