import 'dart:convert';
import 'dart:typed_data';

import '../core/concord_constants.dart';
import '../core/derivations.dart';
import '../core/encoding.dart';
import '../keys/concord_keys.dart';

/// One granted Channel inside an invite bundle (CORD-05 §1).
class InviteChannel {
  final String id;

  /// The Private Channel key (hex). Absent for a Public Channel, whose key
  /// derives from the `community_root`.
  final String? key;
  final int epoch;
  final String? name;

  const InviteChannel({
    required this.id,
    this.key,
    required this.epoch,
    this.name,
  });

  bool get isPrivate => key != null;

  Map<String, Object?> toJson() => {
    'id': id,
    if (key != null) 'key': key,
    'epoch': epoch,
    if (name != null) 'name': name,
  };

  static InviteChannel? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String) return null;
    try {
      checkHex32(id, 'invite channel id');
    } catch (_) {
      return null;
    }
    final key = raw['key'];
    if (key != null) {
      try {
        checkHex32(key as String, 'invite channel key');
      } catch (_) {
        return null;
      }
    }
    final epochRaw = raw['epoch'];
    final epoch = epochRaw is int ? epochRaw : tryParseDecimal('$epochRaw');
    if (epoch == null || epoch < 0) return null;
    final name = raw['name'];
    return InviteChannel(
      id: id,
      key: key is String ? key : null,
      epoch: epoch,
      name: name is String ? name : null,
    );
  }
}

/// The CommunityInvite bundle (CORD-05 §1) — the keys that make a member.
///
/// The bundle self-certifies its owner: `community_id` must equal
/// `sha256("concord/community" || owner || owner_salt)`. [controlPk] is the
/// one field taken on trust — it names a signer the joiner can never derive.
class CommunityInvite {
  final String communityId;
  final String owner;
  final Uint8List ownerSalt;
  final Uint8List communityRoot;
  final int rootEpoch;

  /// The Control Plane signer pubkey at [rootEpoch]. Null for a legacy
  /// pre-split Community (fold Control at the legacy address).
  final String? controlPk;

  final List<InviteChannel> channels;
  final List<String> relays;
  final String? name;
  final Map<String, Object?>? icon;

  /// Unix **milliseconds**, optional: past it the preview renders but a
  /// join is refused.
  final int? expiresAt;
  final String? creatorNpub;
  final String? label;

  const CommunityInvite({
    required this.communityId,
    required this.owner,
    required this.ownerSalt,
    required this.communityRoot,
    required this.rootEpoch,
    this.controlPk,
    this.channels = const [],
    this.relays = const [],
    this.name,
    this.icon,
    this.expiresAt,
    this.creatorNpub,
    this.label,
  });

  bool isExpired({required int nowMillis}) =>
      expiresAt != null && nowMillis >= expiresAt!;

  /// `community_id == sha256(owner || owner_salt)` — the self-check that
  /// makes a bundle unsmuggable (CORD-05 §1).
  bool verifiesOwner() =>
      communityId == derivCommunityId(ownerXonly: owner, ownerSalt: ownerSalt);

  /// Converts to the member's key material.
  CommunityKeys toKeys() {
    final channels = <String, ChannelKey>{};
    for (final channel in this.channels) {
      channels[channel.id] = ChannelKey(
        channelId: channel.id,
        private: channel.isPrivate,
        epoch: channel.epoch,
        key: channel.key != null ? hexToBytes(channel.key!) : null,
      );
    }
    return CommunityKeys(
      communityId: communityId,
      owner: owner,
      ownerSalt: ownerSalt,
      rootEpoch: rootEpoch,
      communityRoot: communityRoot,
      controlPk: controlPk ?? '',
      controlEpoch: rootEpoch,
      channels: channels,
      relays: relays,
      name: name,
    );
  }

  Map<String, Object?> toJson() => {
    'community_id': communityId,
    'owner': owner,
    'owner_salt': bytesToHex(ownerSalt),
    'community_root': bytesToHex(communityRoot),
    'root_epoch': rootEpoch,
    if (controlPk != null) 'control_pk': controlPk,
    'channels': [for (final c in channels) c.toJson()],
    'relays': relays,
    if (name != null) 'name': name,
    if (icon != null) 'icon': icon,
    if (expiresAt != null) 'expires_at': expiresAt,
    if (creatorNpub != null) 'creator_npub': creatorNpub,
    if (label != null) 'label': label,
  };

  /// Parses a bundle JSON string, applying the §1 bounds and the owner
  /// self-check. Returns null when the bundle is refused.
  static CommunityInvite? tryParse(String jsonString) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      return null;
    }
    return fromJson(decoded);
  }

  static CommunityInvite? fromJson(Object? decoded) {
    if (decoded is! Map) return null;

    final communityId = decoded['community_id'];
    final owner = decoded['owner'];
    final ownerSaltRaw = decoded['owner_salt'];
    final rootRaw = decoded['community_root'];
    final rootEpochRaw = decoded['root_epoch'];
    if (communityId is! String ||
        owner is! String ||
        ownerSaltRaw is! String ||
        rootRaw is! String ||
        rootEpochRaw is! int) {
      return null;
    }
    try {
      checkHex32(communityId, 'community_id');
      checkHex32(owner, 'owner');
      checkHex(ownerSaltRaw, 'owner_salt');
      checkHex(rootRaw, 'community_root');
    } catch (_) {
      return null;
    }
    final ownerSalt = hexToBytes(ownerSaltRaw);
    final communityRoot = hexToBytes(rootRaw);
    if (ownerSalt.length != 32 || communityRoot.length != 32) return null;
    if (rootEpochRaw < 0) return null;

    final controlPk = decoded['control_pk'];
    if (controlPk != null) {
      if (controlPk is! String) return null;
      try {
        checkHex32(controlPk, 'control_pk');
      } catch (_) {
        return null;
      }
    }

    // Bound before allocating (CORD-05 §1).
    final channelsRaw = decoded['channels'];
    final channels = <InviteChannel>[];
    if (channelsRaw is List) {
      if (channelsRaw.length > Caps.inviteBundleChannels) return null;
      for (final entry in channelsRaw) {
        final channel = InviteChannel.tryParse(entry);
        if (channel == null) return null;
        channels.add(channel);
      }
    }

    // Truncate relays to the Community cap rather than refusing.
    final relaysRaw = decoded['relays'];
    final relays = relaysRaw is List
        ? relaysRaw.whereType<String>().take(Caps.communityRelays).toList()
        : const <String>[];

    final expiresRaw = decoded['expires_at'];
    final expiresAt = expiresRaw is int ? expiresRaw : null;
    final name = decoded['name'];
    final creator = decoded['creator_npub'];
    final label = decoded['label'];

    final invite = CommunityInvite(
      communityId: communityId,
      owner: owner,
      ownerSalt: ownerSalt,
      communityRoot: communityRoot,
      rootEpoch: rootEpochRaw,
      controlPk: controlPk as String?,
      channels: channels,
      relays: relays,
      name: name is String ? name : null,
      icon: decoded['icon'] is Map
          ? Map<String, Object?>.from(decoded['icon'] as Map)
          : null,
      expiresAt: expiresAt,
      creatorNpub: creator is String ? creator : null,
      label: label is String ? label : null,
    );

    if (!invite.verifiesOwner()) return null;
    return invite;
  }

  String toJsonString() => encodeJson(toJson());
}

/// Wraps [deriv.communityId] so this file needn't import the derivations
/// library under a prefix in two places.
String derivCommunityId({
  required String ownerXonly,
  required Uint8List ownerSalt,
}) => communityId(ownerXonly: ownerXonly, ownerSalt: ownerSalt);
