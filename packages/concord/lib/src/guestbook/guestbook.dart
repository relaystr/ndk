import 'dart:convert';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../core/concord_constants.dart';
import '../core/concord_time.dart';
import '../core/encoding.dart';
import '../core/permissions.dart';
import '../roster/roster.dart';

/// A Guestbook motion (CORD-02 §5). One of Join, Leave, Kick or Snapshot.
sealed class GuestbookEvent {
  final String id;
  final String author;
  final int at;

  const GuestbookEvent({
    required this.id,
    required this.author,
    required this.at,
  });

  /// Parses any Guestbook rumor (Join/Leave, Kick, Snapshot).
  static GuestbookEvent? tryParseAny(Nip01Event rumor) {
    switch (rumor.kind) {
      case RumorKinds.joinLeave:
        return GuestbookVerb.tryParse(rumor);
      case RumorKinds.kick:
        return GuestbookKick.tryParse(rumor);
      case RumorKinds.snapshot:
        return GuestbookSnapshot.tryParse(rumor);
      default:
        return null;
    }
  }
}

/// A self-signed Join or Leave (kind 3306). The content is the verb.
class GuestbookVerb extends GuestbookEvent {
  /// "join" or "leave".
  final String verb;

  /// Optional invite attribution (Joins only).
  final String? inviteCreator;
  final String? inviteLabel;

  const GuestbookVerb({
    required super.id,
    required super.author,
    required super.at,
    required this.verb,
    this.inviteCreator,
    this.inviteLabel,
  });

  bool get isJoin => verb == 'join';

  static GuestbookVerb? tryParse(Nip01Event rumor) {
    if (rumor.kind != RumorKinds.joinLeave) return null;
    final at = Millis.of(rumor);
    if (at == null) return null;
    final verb = rumor.content;
    if (verb != 'join' && verb != 'leave') return null;
    String? creator;
    String? label;
    for (final tag in rumor.tags) {
      if (tag.length >= 3 && tag[0] == 'invite') {
        creator = tag[1];
        label = tag[2];
      }
    }
    return GuestbookVerb(
      id: rumor.id,
      author: rumor.pubKey,
      at: at,
      verb: verb,
      inviteCreator: creator,
      inviteLabel: label,
    );
  }
}

/// An admin-signed Kick (kind 3309).
class GuestbookKick extends GuestbookEvent {
  final String target;
  final String? vacEid;
  final int? vacVersion;
  final String? vacHash;

  const GuestbookKick({
    required super.id,
    required super.author,
    required super.at,
    required this.target,
    this.vacEid,
    this.vacVersion,
    this.vacHash,
  });

  static GuestbookKick? tryParse(Nip01Event rumor) {
    if (rumor.kind != RumorKinds.kick) return null;
    final at = Millis.of(rumor);
    if (at == null) return null;
    String? target;
    String? vacEid;
    int? vacVersion;
    String? vacHash;
    for (final tag in rumor.tags) {
      if (tag.length >= 2 && tag[0] == 'p') target = tag[1];
      if (tag.length >= 4 && tag[0] == 'vac') {
        vacEid = tag[1];
        vacVersion = tryParseDecimal(tag[2]);
        vacHash = tag[3];
        if (vacVersion == null) return null;
      }
    }
    if (target == null) return null;
    try {
      checkHex32(target, 'kick target');
    } catch (_) {
      return null;
    }
    return GuestbookKick(
      id: rumor.id,
      author: rumor.pubKey,
      at: at,
      target: target,
      vacEid: vacEid,
      vacVersion: vacVersion,
      vacHash: vacHash,
    );
  }
}

/// A refounder-signed Snapshot chunk (kind 3312). Present members only.
class GuestbookSnapshot extends GuestbookEvent {
  final String snapshotId;
  final int part;
  final int total;
  final List<String> members;

  const GuestbookSnapshot({
    required super.id,
    required super.author,
    required super.at,
    required this.snapshotId,
    required this.part,
    required this.total,
    required this.members,
  });

  static GuestbookSnapshot? tryParse(Nip01Event rumor) {
    if (rumor.kind != RumorKinds.snapshot) return null;
    final at = Millis.of(rumor);
    if (at == null) return null;
    String? snapshotId;
    int? part;
    int? total;
    for (final tag in rumor.tags) {
      if (tag.length >= 4 && tag[0] == 'snap') {
        snapshotId = tag[1];
        part = tryParseDecimal(tag[2]);
        total = tryParseDecimal(tag[3]);
      }
    }
    if (snapshotId == null || part == null || total == null) return null;
    if (part < 0 || total < 1 || part >= total) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(rumor.content);
    } catch (_) {
      return null;
    }
    if (decoded is! List) return null;
    final members = <String>[];
    for (final entry in decoded) {
      if (entry is! String) continue;
      try {
        checkHex32(entry, 'snapshot member');
      } catch (_) {
        continue;
      }
      members.add(entry);
    }
    return GuestbookSnapshot(
      id: rumor.id,
      author: rumor.pubKey,
      at: at,
      snapshotId: snapshotId,
      part: part,
      total: total,
      members: members,
    );
  }
}

/// The result of folding the Guestbook: the Complete Memberlist
/// (CORD-02 §5).
class GuestbookState {
  /// Every member present: coalesced Joins minus Leaves/Kicks, merged with
  /// observed authors, minus the Banlist.
  final Set<String> members;

  /// The verb/state that decided each member's presence.
  final Map<String, GuestbookEvent> decisions;

  const GuestbookState({required this.members, required this.decisions});
}

/// Folds the Guestbook flat (CORD-02 §5).
///
/// One final state per npub: the latest Join/Leave/Kick wins, ties break by
/// the lower rumor id, entries more than an hour ahead are dropped, Kicks
/// are honored only when their signer holds `KICK` and strictly outranks the
/// target (CORD-04), and a snapshot merely seeds an npub's state.
class GuestbookFold {
  final String owner;
  final Roster roster;

  final Map<String, GuestbookVerb> _verbByAuthor = {};
  final Map<String, GuestbookKick> _latestKick = {};
  final Map<String, int> _kickAt = {};

  /// Observed authors with their newest activity time — presence evidence.
  final Map<String, int> _observedAt = {};

  /// Latest Leave per author.
  final Map<String, int> _leaveAt = {};

  /// Snapshot seeds: author -> (at, snapshotId).
  final Map<String, int> _seedAt = {};

  GuestbookFold({required this.owner, required this.roster});

  /// Ingests any Guestbook rumor. [nowSeconds] enforces the one-hour
  /// future bound. Returns true when accepted.
  bool ingest(Nip01Event rumor, {required int nowSeconds}) {
    final event = GuestbookEvent.tryParseAny(rumor);
    if (event == null) return false;
    if (event.at > (nowSeconds + 3600) * 1000) return false; // > 1h ahead

    switch (event) {
      case GuestbookVerb verb:
        _verbByAuthor[verb.author] = verb;
        if (!verb.isJoin) _leaveAt[verb.author] = verb.at;
        return true;
      case GuestbookKick kick:
        // Honor only authorized Kicks.
        if (!roster.can(kick.author, Permissions.kick, target: kick.target)) {
          return false;
        }
        final existing = _kickAt[kick.target];
        if (existing == null || kick.at > existing) {
          _latestKick[kick.target] = kick;
          _kickAt[kick.target] = kick.at;
        }
        return true;
      case GuestbookSnapshot snapshot:
        for (final member in snapshot.members) {
          final seed = _seedAt[member];
          if (seed == null || snapshot.at > seed) {
            _seedAt[member] = snapshot.at;
          }
        }
        return true;
    }
  }

  /// Records an observed author (any decrypted event from them) with its
  /// true time. Observation only counts *forward* (§5).
  void observe(String author, int at) {
    final existing = _observedAt[author];
    if (existing == null || at > existing) {
      _observedAt[author] = at;
    }
  }

  GuestbookState fold({required Set<String> banned}) {
    final members = <String>{};
    final decisions = <String, GuestbookEvent>{};

    // Everyone ever seen: the owner (always present), verb authors, kicked
    // targets, snapshot members, observed authors.
    final everyone = <String>{
      owner,
      ..._verbByAuthor.keys,
      ..._latestKick.keys,
      ..._seedAt.keys,
      ..._observedAt.keys,
    };

    for (final member in everyone) {
      // The owner is always a member and can never be banned (CORD-04 §2).
      if (member == owner) {
        members.add(member);
        continue;
      }
      if (banned.contains(member)) continue;

      // Candidate "present" times: latest join/observation/seed.
      final verb = _verbByAuthor[member];
      final leave = _leaveAt[member];
      final observed = _observedAt[member];
      final seed = _seedAt[member];
      final kickAt = _kickAt[member];

      // Absence: a Kick or Leave after all presence evidence keeps them out.
      final presentEvidence = <int>[
        if (verb != null && verb.isJoin) verb.at,
        ?observed,
        ?seed,
      ];
      final absenceEvidence = <int>[?leave, ?kickAt];

      final latestPresent = presentEvidence.isEmpty
          ? null
          : presentEvidence.reduce((a, b) => a > b ? a : b);
      final latestAbsent = absenceEvidence.isEmpty
          ? null
          : absenceEvidence.reduce((a, b) => a > b ? a : b);

      // Present when the newest presence evidence exists and nothing
      // absenting is strictly newer. On a time tie, presence wins (the rule
      // is "newer than the latest Leave/Kick").
      final bool present =
          latestPresent != null &&
          (latestAbsent == null || latestPresent >= latestAbsent);

      if (present) {
        members.add(member);
        final kick = _latestKick[member];
        if (kick != null && kickAt != null && kickAt >= (latestPresent)) {
          decisions[member] = kick;
        } else if (verb != null) {
          decisions[member] = verb;
        }
      }
    }

    return GuestbookState(members: members, decisions: decisions);
  }
}
