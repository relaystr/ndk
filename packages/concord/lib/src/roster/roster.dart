import 'package:meta/meta.dart';

import '../core/permissions.dart';
import '../model/role.dart';

/// Who may do what (CORD-04 §3, §5).
///
/// Authority is **positional**: the owner is position 0; a roleless member
/// ranks last. An actor needs the required bit *and* must strictly outrank
/// the target — an equal rank can never act on a member.
@immutable
class Roster {
  /// The owner's position; no role may claim it (CORD-04 §2).
  static const int ownerRank = 0;

  /// The rank handed to a member holding no role: below everyone.
  static const int rolelessRank = 1 << 30;

  final String owner;

  /// Folded roles, keyed by role_id.
  final Map<String, Role> roles;

  /// Folded grants, keyed by member npub. A member with no entry is
  /// roleless.
  final Map<String, Grant> grants;

  const Roster({
    required this.owner,
    this.roles = const {},
    this.grants = const {},
  });

  Roster copyWith({
    String? owner,
    Map<String, Role>? roles,
    Map<String, Grant>? grants,
  }) => Roster(
    owner: owner ?? this.owner,
    roles: roles ?? this.roles,
    grants: grants ?? this.grants,
  );

  /// Every role a member holds, in the order carried by their Grant,
  /// dropping ids without a folded Role.
  List<Role> rolesOf(String member) {
    final grant = grants[member];
    if (grant == null) return const [];
    return [
      for (final id in grant.roleIds)
        if (roles[id] != null) roles[id]!,
    ];
  }

  /// A member's effective rank: the **lowest** position among their roles.
  /// The owner is always 0; a roleless member is [rolelessRank].
  int rankOf(String member) {
    if (member == owner) return ownerRank;
    var best = rolelessRank;
    for (final role in rolesOf(member)) {
      if (role.position < best) best = role.position;
    }
    return best;
  }

  /// The union of the bits a member holds, scoped for an optional channel:
  /// server-scoped roles always count, a channel-scoped role counts only
  /// for its own channel (CORD-04 §2).
  int permissionsOf(String member, {String? channelId}) {
    if (member == owner) return Permissions.ownerPermissions;
    return Permissions.union([
      for (final role in rolesOf(member))
        if (role.scope.isServer || role.scope.channelId == channelId)
          role.permissions,
    ]);
  }

  /// Whether [actor] holds [bit] in the given channel scope.
  bool holds(String actor, int bit, {String? channelId}) =>
      actor == owner ||
      Permissions.has(permissionsOf(actor, channelId: channelId), bit);

  /// The strict-outrank gate: neither the owner nor an equal-ranked member
  /// can be acted upon (CORD-04 §5 — "strictly outrank").
  bool strictlyOutranks(String actor, String target) {
    if (actor == owner) return target != owner;
    if (target == owner) return false;
    return rankOf(actor) < rankOf(target);
  }

  /// The full authority check: holds [bit], and — when a [target] is named
  /// — strictly outranks it.
  bool can(String actor, int bit, {String? target, String? channelId}) {
    if (!holds(actor, bit, channelId: channelId)) return false;
    if (target != null && !strictlyOutranks(actor, target)) return false;
    return true;
  }
}
