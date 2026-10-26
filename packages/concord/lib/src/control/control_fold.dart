import 'package:meta/meta.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../core/concord_constants.dart';
import '../core/encoding.dart';
import '../core/permissions.dart';
import '../model/metadata.dart';
import '../model/role.dart';
import '../roster/roster.dart';
import 'control_edition.dart';
import 'entity_chain.dart';

/// The folded Control Plane state of one Community (CORD-04).
@immutable
class ControlState {
  final String owner;
  final Roster roster;
  final CommunityMetadata? metadata;
  final Map<String, ChannelMetadata> channels;
  final List<String> banlist;

  /// Every entity head, keyed by `eid` — the `prev`/`ev` source for the
  /// next edition.
  final Map<String, FoldedEntity> heads;

  /// Entities suspended for an unresolvable `prev` (tracking-client fail
  /// closed). Refetch before trusting them.
  final Set<String> suspended;

  const ControlState({
    required this.owner,
    required this.roster,
    required this.metadata,
    required this.channels,
    required this.banlist,
    required this.heads,
    required this.suspended,
  });

  /// A banned member: their control editions are ignored and their chat is
  /// dropped.
  bool isBanned(String member) => banlist.contains(member);

  /// Next `ev` for a successor edition of [eid] (1 when there is no head).
  int nextVersion(String eid) => (heads[eid]?.version ?? 0) + 1;

  /// `ep` for a successor edition of [eid] (null when there is no head).
  String? prevHash(String eid) => heads[eid]?.hash;
}

/// The Control Plane fold: every entity chain, resolved against a roster
/// that is itself built from the Role and Grant chains.
///
/// Resolution order (CORD-04 §5): start at the owner, resolve outward. The
/// roster and the Role/Grant folds depend on each other, so they are solved
/// together by a fixpoint iteration bounded by the number of authorities.
class ControlFold {
  final String owner;

  final Map<String, EntityChain> _chains = {};

  /// Rumor ids dropped by a NIP-09 delete.
  final Set<String> _dropped = {};

  ControlFold({required this.owner});

  /// Ingests a Control edition. Returns false when the rumor is malformed
  /// and must be dropped.
  bool ingest(ControlEdition edition) {
    _chains
        .putIfAbsent(edition.eid, () => EntityChain(edition.eid))
        .ingest(edition);
    return true;
  }

  /// Parses and ingests a kind 3308 rumor.
  bool ingestRumor(Nip01Event rumor) {
    final edition = ControlEdition.tryParse(rumor);
    if (edition == null) return false;
    return ingest(edition);
  }

  /// Honors a NIP-09 delete: editions whose rumor id is named are dropped
  /// from every chain.
  void dropRumor(String rumorId) {
    _dropped.add(rumorId);
    for (final chain in _chains.values) {
      chain.drop(_dropped);
    }
  }

  /// Folds everything. Runs once with no ban filter to learn the banlist,
  /// then a final pass dropping editions authored by banned members.
  ControlState build({bool allowReanchor = true}) {
    final provisional = _fold(allowReanchor: allowReanchor, banned: const {});
    final banned = provisional.banlist.toSet();
    if (banned.isEmpty) return provisional;
    return _fold(allowReanchor: allowReanchor, banned: banned);
  }

  ControlState _fold({
    required bool allowReanchor,
    required Set<String> banned,
  }) {
    final vskOfEid = <String, int>{};
    for (final chain in _chains.values) {
      for (final edition in chain.editions) {
        vskOfEid[chain.eid] = edition.vsk;
        break;
      }
    }

    bool isLive(ControlEdition e) =>
        !_dropped.contains(e.id) && !banned.contains(e.author);

    Roster roster = Roster(owner: owner);
    Map<String, Role> roles = {};
    Map<String, Grant> grants = {};

    for (var round = 0; round < 64; round++) {
      final rankOf = roster.rankOf;
      final newRoles = <String, Role>{};
      final newGrants = <String, Grant>{};

      for (final chain in _chains.values) {
        final vsk = vskOfEid[chain.eid];
        if (vsk == Vsk.role) {
          final res = chain.resolve(
            rankOf: rankOf,
            isAuthorized: (e) => isLive(e) && _canEditRole(e, roster),
            allowReanchor: allowReanchor,
          );
          final head = res.head;
          if (head == null) continue;
          final role = Role.tryParse(head.content);
          if (role == null || role.roleId != head.eid) continue;
          newRoles[head.eid] = role;
        } else if (vsk == Vsk.grant) {
          final res = chain.resolve(
            rankOf: rankOf,
            isAuthorized: (e) => isLive(e) && _canEditGrant(e, roster),
            allowReanchor: allowReanchor,
          );
          final head = res.head;
          if (head == null) continue;
          final grant = Grant.tryParse(
            head.content,
            version: head.version,
            hash: head.hash,
          );
          if (grant == null) continue;
          newGrants[grant.member] = grant;
        }
      }

      final stable = _sameMap(newRoles, roles) && _sameMap(newGrants, grants);
      roles = newRoles;
      grants = newGrants;
      if (stable) break;
      roster = Roster(owner: owner, roles: roles, grants: grants);
    }

    final finalRoster = Roster(owner: owner, roles: roles, grants: grants);

    // --- Remaining entity types, resolved against the final roster. ---
    final heads = <String, FoldedEntity>{};
    final suspended = <String>{};
    final channels = <String, ChannelMetadata>{};
    CommunityMetadata? metadata;
    var banlist = const <String>[];

    bool canEditGeneric(ControlEdition e, {String? channelId}) {
      if (e.author == owner) return true;
      if (banned.contains(e.author)) return false;
      if (!_vacOk(e, finalRoster)) return false;
      final int bit;
      if (channelId != null) {
        // Channel ops: either a server-wide channel manager, or a
        // channel-scoped role carrying the bit for that channel.
        final server = finalRoster.holds(e.author, Permissions.manageChannels);
        final scoped = finalRoster.holds(
          e.author,
          Permissions.manageChannels,
          channelId: channelId,
        );
        return server || scoped;
      }
      bit = switch (e.vsk) {
        Vsk.communityMetadata => Permissions.manageMetadata,
        Vsk.banlist => Permissions.ban,
        _ => 0,
      };
      return finalRoster.can(e.author, bit);
    }

    for (final chain in _chains.values) {
      final vsk = vskOfEid[chain.eid];
      if (vsk == Vsk.role || vsk == Vsk.grant) continue;

      final bool Function(ControlEdition) authorized;
      switch (vsk) {
        case Vsk.communityMetadata:
          authorized = (e) => isLive(e) && canEditGeneric(e);
          break;
        case Vsk.banlist:
          authorized = (e) => isLive(e) && canEditGeneric(e);
          break;
        case Vsk.channelMetadata:
          authorized = (e) =>
              isLive(e) && canEditGeneric(e, channelId: chain.eid);
          break;
        default:
          // Reserved entity types (pin list, invite registry): kept with
          // structural checks only, so a future client sees the head.
          authorized = isLive;
      }

      final res = chain.resolve(
        rankOf: finalRoster.rankOf,
        isAuthorized: authorized,
        allowReanchor: allowReanchor,
      );
      final head = res.head;
      if (res.outcome == ChainOutcome.suspended) {
        suspended.add(chain.eid);
        continue;
      }
      if (head == null) continue;
      heads[chain.eid] = res.folded!;

      switch (vsk) {
        case Vsk.communityMetadata:
          metadata = CommunityMetadata.tryParse(head.content);
          break;
        case Vsk.channelMetadata:
          final channel = ChannelMetadata.tryParse(head.content);
          if (channel != null) channels[chain.eid] = channel;
          break;
        case Vsk.banlist:
          banlist = _parseBanlist(head.content);
          break;
        default:
          break;
      }
    }

    // Role and grant heads are also part of the entity picture — resolved
    // with the same authorization the roster converged on.
    for (final chain in _chains.values) {
      final vsk = vskOfEid[chain.eid];
      final bool Function(ControlEdition)? authorized;
      if (vsk == Vsk.role) {
        authorized = (e) => isLive(e) && _canEditRole(e, finalRoster);
      } else if (vsk == Vsk.grant) {
        authorized = (e) => isLive(e) && _canEditGrant(e, finalRoster);
      } else {
        authorized = null;
      }
      if (authorized == null) continue;
      final res = chain.resolve(
        rankOf: finalRoster.rankOf,
        isAuthorized: authorized,
        allowReanchor: allowReanchor,
      );
      if (res.folded != null) heads[chain.eid] = res.folded!;
    }

    return ControlState(
      owner: owner,
      roster: finalRoster,
      metadata: metadata,
      channels: Map.unmodifiable(channels),
      banlist: List.unmodifiable(banlist),
      heads: Map.unmodifiable(heads),
      suspended: suspended,
    );
  }

  // --- Authority predicates -------------------------------------------------

  bool _canEditRole(ControlEdition e, Roster roster) {
    final role = Role.tryParse(e.content);
    if (role == null || role.roleId != e.eid) return false;
    // No role exists at position 0 — the owner's rank — for any actor.
    if (role.position <= Roster.ownerRank) return false;
    if (e.author == owner) return true;
    if (roster.rankOf(e.author) == Roster.rolelessRank) return false;
    if (!_vacOk(e, roster)) return false;
    if (!roster.holds(e.author, Permissions.manageRoles)) return false;
    // No edition may claim a position at or above its own signer.
    if (role.position <= roster.rankOf(e.author)) return false;
    return true;
  }

  bool _canEditGrant(ControlEdition e, Roster roster) {
    if (e.author == owner) return true;
    if (roster.rankOf(e.author) == Roster.rolelessRank) return false;
    if (!_vacOk(e, roster)) return false;
    if (!roster.holds(e.author, Permissions.manageRoles)) return false;

    final target = Grant.tryParse(e.content, version: e.version, hash: e.hash);
    if (target == null) return false;
    final actorRank = roster.rankOf(e.author);
    if (target.isRevoke) {
      // A revoke acts on the member: strictly outrank them.
      return roster.strictlyOutranks(e.author, target.member);
    }
    // Honored only if the signer outranks every Role it hands out.
    for (final roleId in target.roleIds) {
      final role = roster.roles[roleId];
      if (role == null) return false;
      if (actorRank >= role.position) return false;
    }
    return true;
  }

  /// Block-until-synced (CORD-04 §1): an edition citing a `vac` is not
  /// honored until we hold a Grant at that coordinate whose version is at
  /// least the cited one and whose hash matches.
  bool _vacOk(ControlEdition e, Roster roster) {
    final citation = e.vacEid;
    if (citation == null) return true;
    final grant = roster.grants[e.author];
    if (grant == null) return false;
    return grant.version >= e.vacVersion! && grant.hash == e.vacHash;
  }

  // --- helpers --------------------------------------------------------------

  static List<String> _parseBanlist(Object? content) {
    if (content is! List) return const [];
    final out = <String>[];
    for (final entry in content) {
      if (entry is! String) continue;
      try {
        checkHex32(entry, 'banlist member');
      } catch (_) {
        continue;
      }
      out.add(entry);
      if (out.length >= Caps.banlistNpubs) break;
    }
    return out;
  }

  static bool _sameMap<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (identical(other, entry.value)) continue;
      if (other == null || other != entry.value) return false;
    }
    return true;
  }
}
