import 'dart:math' as math;

import 'control_edition.dart';

/// One entity's folded head.
class FoldedEntity {
  final String eid;
  final int vsk;
  final int version;
  final String hash;
  final ControlEdition edition;

  /// True when the head was accepted as a fresh joiner's baseline despite a
  /// dangling `prev` (CORD-06 compaction / first sync).
  final bool reanchored;

  const FoldedEntity({
    required this.eid,
    required this.vsk,
    required this.version,
    required this.hash,
    required this.edition,
    this.reanchored = false,
  });
}

/// The result of resolving one entity's per-version editions into a head.
enum ChainOutcome { intact, reanchored, suspended, empty }

class ChainResolution {
  final ChainOutcome outcome;
  final ControlEdition? head;
  final FoldedEntity? folded;

  const ChainResolution(this.outcome, this.head, [this.folded]);
}

/// Per-entity chain fold (CORD-04 §1).
///
/// Keeps one **canonical** edition per version — ties broken by authority
/// first, then the lower rumor id, never the author-settable timestamp —
/// and resolves the highest version whose chain is intact.
class EntityChain {
  final String eid;

  /// version -> every edition seen at that version.
  final Map<int, List<ControlEdition>> _byVersion = {};

  EntityChain(this.eid);

  Iterable<ControlEdition> get editions =>
      _byVersion.values.expand((list) => list);

  int get highestVersion =>
      _byVersion.isEmpty ? 0 : _byVersion.keys.reduce(math.max);

  /// Ingests an edition. Same-version duplicates accumulate; the canonical
  /// one is chosen at resolve time against the current roster.
  void ingest(ControlEdition edition) =>
      _byVersion.putIfAbsent(edition.version, () => []).add(edition);

  /// Removes every edition whose rumor id is in [ids] (NIP-09 delete).
  void drop(Set<String> ids) {
    final versions = _byVersion.keys.toList();
    for (final version in versions) {
      final kept = _byVersion[version]!
          .where((e) => !ids.contains(e.id))
          .toList();
      if (kept.isEmpty) {
        _byVersion.remove(version);
      } else {
        _byVersion[version] = kept;
      }
    }
  }

  /// Picks the canonical edition at [version] among those that pass
  /// [isAuthorized]: highest authority wins, then the lower rumor id.
  ControlEdition? _canonical(
    int version,
    int Function(String) rankOf,
    bool Function(ControlEdition) isAuthorized,
  ) {
    ControlEdition? best;
    for (final edition in _byVersion[version]!) {
      if (!isAuthorized(edition)) continue;
      if (best == null) {
        best = edition;
        continue;
      }
      final newRank = rankOf(edition.author);
      final bestRank = rankOf(best.author);
      if (newRank < bestRank ||
          (newRank == bestRank && edition.id.compareTo(best.id) < 0)) {
        best = edition;
      }
    }
    return best;
  }

  bool _isIntactUpTo(int version, Map<int, ControlEdition> canonical) {
    var current = canonical[version]!;
    while (current.version > 1) {
      final prev = canonical[current.version - 1];
      if (prev == null) return false;
      if (current.prev != prev.hash) return false;
      current = prev;
    }
    return current.version == 1 && current.prev == null;
  }

  /// Resolves the head over the editions that pass [isAuthorized].
  ///
  /// * A **fresh joiner** ([allowReanchor] true) accepts the highest
  ///   authority-verified head even with a dangling `prev` — the signature
  ///   plus the current-authority check is the whole test.
  /// * A **tracking client** treats an unresolvable `prev` as a gap and
  ///   fails closed *for that entity*: [ChainOutcome.suspended], so it
  ///   neither downgrades nor accepts the gap.
  ChainResolution resolve({
    required int Function(String) rankOf,
    required bool Function(ControlEdition) isAuthorized,
    required bool allowReanchor,
  }) {
    if (_byVersion.isEmpty) {
      return const ChainResolution(ChainOutcome.empty, null);
    }

    final canonical = <int, ControlEdition>{};
    for (final version in _byVersion.keys) {
      final edition = _canonical(version, rankOf, isAuthorized);
      if (edition != null) canonical[version] = edition;
    }
    if (canonical.isEmpty) {
      return const ChainResolution(ChainOutcome.empty, null);
    }

    final maxV = canonical.keys.reduce(math.max);
    int? intactVersion;
    for (var v = maxV; v >= 1; v--) {
      if (canonical[v] != null && _isIntactUpTo(v, canonical)) {
        intactVersion = v;
        break;
      }
    }

    if (intactVersion == maxV) {
      final edition = canonical[maxV]!;
      return ChainResolution(
        ChainOutcome.intact,
        edition,
        FoldedEntity(
          eid: eid,
          vsk: edition.vsk,
          version: edition.version,
          hash: edition.hash,
          edition: edition,
        ),
      );
    }

    // Higher versions exist whose chain does not reach a known baseline.
    // A fresh joiner re-anchors on the top; a tracking client fails closed
    // for this entity — it neither downgrades nor accepts the gap.
    if (allowReanchor) {
      final top = canonical[maxV]!;
      return ChainResolution(
        ChainOutcome.reanchored,
        top,
        FoldedEntity(
          eid: eid,
          vsk: top.vsk,
          version: top.version,
          hash: top.hash,
          edition: top,
          reanchored: true,
        ),
      );
    }
    return const ChainResolution(ChainOutcome.suspended, null);
  }
}
