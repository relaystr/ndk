import '../core/concord_constants.dart';
import '../core/encoding.dart';
import '../core/permissions.dart';

/// A Role's scope (CORD-04 §2): server-wide or one Channel.
class RoleScope {
  final String? channelId;

  const RoleScope.server() : channelId = null;
  const RoleScope.channel(String this.channelId);

  bool get isServer => channelId == null;

  Map<String, Object?> toJson() => isServer
      ? {'kind': 'server'}
      : {'kind': 'channel', 'channel_id': channelId};

  static RoleScope? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final kind = raw['kind'];
    if (kind == 'server') return const RoleScope.server();
    if (kind == 'channel') {
      final id = raw['channel_id'];
      if (id is! String) return null;
      try {
        checkHex32(id, 'role scope channel_id');
      } catch (_) {
        return null;
      }
      return RoleScope.channel(id);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is RoleScope && other.channelId == channelId;
  @override
  int get hashCode => channelId.hashCode;
}

/// A Role (CORD-04 §2, vsk 1). Mints no key: granting it hands a member
/// *rank*, never a secret.
class Role {
  final String roleId;
  final String name;
  final int position; // lower is higher; 0 is the owner's, never a Role
  final int permissions; // bit union, Permissions constants
  final RoleScope scope;
  final int color;

  /// Unknown top-level fields, round-tripped untouched (checklist:
  /// "Round-trip fields you do not understand").
  final Map<String, Object?> extra;

  Role({
    required this.roleId,
    required this.name,
    required this.position,
    required this.permissions,
    required this.scope,
    this.color = 0,
    this.extra = const {},
  });

  /// Parses a vsk 1 edition content. Returns null when malformed.
  static Role? tryParse(Object? content) {
    if (content is! Map) return null;
    final roleId = content['role_id'];
    final name = content['name'];
    final position = content['position'];
    final scope = RoleScope.tryParse(content['scope']);
    if (roleId is! String ||
        name is! String ||
        position is! int ||
        scope == null) {
      return null;
    }
    try {
      checkHex32(roleId, 'role_id');
    } catch (_) {
      return null;
    }
    if (utf8Length(name) > Caps.nameBytes) return null;
    if (position < 0) return null;
    final permissions = Permissions.parse(content['permissions']);
    final color = content['color'] is int ? content['color'] as int : 0;
    return Role(
      roleId: roleId,
      name: name,
      position: position,
      permissions: permissions,
      scope: scope,
      color: color,
      extra: {
        for (final entry in content.entries)
          if (!_knownKeys.contains(entry.key)) '${entry.key}': entry.value,
      },
    );
  }

  static const Set<String> _knownKeys = {
    'role_id',
    'name',
    'position',
    'permissions',
    'scope',
    'color',
  };

  String toContentJson() => encodeJson({
    'role_id': roleId,
    'name': name,
    'position': position,
    'permissions': Permissions.serialize(permissions),
    'scope': scope.toJson(),
    'color': color,
    ...extra,
  });

  @override
  String toString() => 'Role($name, pos: $position, perms: $permissions)';

  @override
  bool operator ==(Object other) =>
      other is Role &&
      other.roleId == roleId &&
      other.name == name &&
      other.position == position &&
      other.permissions == permissions &&
      other.scope == scope &&
      other.color == color;

  @override
  int get hashCode =>
      Object.hash(roleId, name, position, permissions, scope, color);
}

/// A Grant (CORD-04 §2, vsk 3): maps a member's npub to their Roles.
/// Honored only if its signer outranks every Role it hands out; an empty
/// `role_ids` is a revoke.
class Grant {
  final String member;
  final List<String> roleIds;

  /// Optional staff write key delivery: NIP-44 ciphertext (under the
  /// granter↔member pairwise key) of `epoch_be[8] ‖ control_root[32]`.
  final String? controlWrap;

  /// The folded edition's version and hash — what a `vac` cites.
  final int version;
  final String hash;

  final Map<String, Object?> extra;

  Grant({
    required this.member,
    required this.roleIds,
    this.controlWrap,
    this.version = 0,
    this.hash = '',
    this.extra = const {},
  });

  bool get isRevoke => roleIds.isEmpty;

  Grant copyWith({int? version, String? hash, String? controlWrap}) => Grant(
    member: member,
    roleIds: roleIds,
    controlWrap: controlWrap ?? this.controlWrap,
    version: version ?? this.version,
    hash: hash ?? this.hash,
    extra: extra,
  );

  static Grant? tryParse(Object? content, {int version = 0, String hash = ''}) {
    if (content is! Map) return null;
    final member = content['member'];
    final roleIdsRaw = content['role_ids'];
    if (member is! String || roleIdsRaw is! List) return null;
    try {
      checkHex32(member, 'grant member');
    } catch (_) {
      return null;
    }
    final roleIds = <String>[];
    for (final id in roleIdsRaw) {
      if (id is! String) return null;
      try {
        checkHex32(id, 'role_id');
      } catch (_) {
        return null;
      }
      roleIds.add(id);
    }
    if (roleIds.length > Caps.memberRoles) return null;
    final wrap = content['control_wrap'];
    return Grant(
      member: member,
      roleIds: roleIds,
      controlWrap: wrap is String ? wrap : null,
      version: version,
      hash: hash,
      extra: {
        for (final entry in content.entries)
          if (entry.key != 'member' &&
              entry.key != 'role_ids' &&
              entry.key != 'control_wrap')
            '${entry.key}': entry.value,
      },
    );
  }

  String toContentJson() => encodeJson({
    'member': member,
    'role_ids': roleIds,
    if (controlWrap != null) 'control_wrap': controlWrap,
    ...extra,
  });

  @override
  bool operator ==(Object other) =>
      other is Grant &&
      other.member == member &&
      _sameList(other.roleIds, roleIds) &&
      other.controlWrap == controlWrap &&
      other.version == version &&
      other.hash == hash;

  @override
  int get hashCode =>
      Object.hash(member, Object.hashAll(roleIds), controlWrap, version, hash);

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
