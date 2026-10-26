import 'dart:convert';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../core/concord_constants.dart';
import '../core/concord_time.dart';
import '../core/encoding.dart';

/// One Control Plane edition (CORD-04 §1): a kind `3308` rumor carrying
/// `vsk` (entity type), `eid` (stable coordinate), `ev` (version), `ep`
/// (previous edition hash) and an optional `vac` authority citation.
class ControlEdition {
  /// The underlying rumor (unsigned; the seal carries the signature).
  final Nip01Event rumor;

  /// Entity type (CORD-02 Appendix B).
  final int vsk;

  /// The entity's stable coordinate, 64 lowercase hex.
  final String eid;

  /// Per-entity version, starting at 1, only ever climbing.
  final int version;

  /// Hash of the edition this one supersedes; null on the first edition.
  final String? prev;

  /// The edition's content bytes, verbatim — hashed exactly as carried.
  final String contentRaw;

  /// The decoded content.
  final Object? content;

  /// Authority citation (`vac`): the Grant edition the actor claims their
  /// rank under, pinned by coordinate, version and content hash.
  final String? vacEid;
  final int? vacVersion;
  final String? vacHash;

  /// Millisecond time basis; null when the `ms` tag is malformed (the
  /// edition is then dropped).
  final int? createdAtMs;

  ControlEdition({
    required this.rumor,
    required this.vsk,
    required this.eid,
    required this.version,
    required this.prev,
    required this.contentRaw,
    required this.content,
    required this.createdAtMs,
    this.vacEid,
    this.vacVersion,
    this.vacHash,
  });

  String get id => rumor.id;
  String get author => rumor.pubKey;

  /// `edition_hash = sha256(len64(label) || label || entity_id[32] ||
  /// version_be[8] || (prev ? 0x01 || prev[32] : 0x00 || zero[32]) ||
  /// len64(content) || content)` (CORD-04 §1).
  late final String hash = _computeHash();

  String _computeHash() {
    final label = Labels.editionHash;
    final labelBytesUtf8 = utf8.encode(label);
    final contentBytes = utf8.encode(contentRaw);
    return sha256Hex(
      concatBytes([
        u64Be(labelBytesUtf8.length),
        labelBytesUtf8,
        hexToBytes(eid),
        u64Be(version),
        if (prev != null)
          <int>[0x01, ...hexToBytes(prev!)]
        else
          <int>[0x00, ...List<int>.filled(32, 0)],
        u64Be(contentBytes.length),
        contentBytes,
      ]),
    );
  }

  /// True when this edition cites [other] as its direct predecessor.
  bool cites(ControlEdition other) => prev != null && prev == other.hash;

  /// Parses a kind `3308` rumor. Returns null when any structural
  /// requirement fails — callers drop such editions (fail closed).
  static ControlEdition? tryParse(Nip01Event rumor) {
    if (rumor.kind != RumorKinds.controlEdition) return null;

    final vsk = _tag(rumor, 'vsk');
    final eid = _tag(rumor, 'eid');
    final ev = _tag(rumor, 'ev');
    final ep = _tag(rumor, 'ep');
    if (vsk == null || eid == null || ev == null) return null;

    final vskValue = tryParseDecimal(vsk);
    final version = tryParseDecimal(ev);
    if (vskValue == null || version == null || version < 1) return null;
    try {
      checkHex32(eid, 'edition eid');
    } catch (_) {
      return null;
    }
    if (ep != null) {
      try {
        checkHex32(ep, 'edition ep');
      } catch (_) {
        return null;
      }
    }

    // A chainless tombstone (vsk 10) is exempt from version discipline and
    // carries no ev/ep; the §9 tombstone is parsed separately from a plain
    // 3308 rumor at the dissolved address, so here it is treated as an
    // ordinary edition only if it has ev.
    final ms = Millis.of(rumor);
    if (ms == null) return null;

    Object? content;
    try {
      content = jsonDecode(rumor.content);
    } catch (_) {
      return null;
    }

    String? vacEid;
    int? vacVersion;
    String? vacHash;
    final vac = _tagValues(rumor, 'vac');
    if (vac != null && vac.length >= 4) {
      try {
        checkHex32(vac[1], 'vac eid');
      } catch (_) {
        return null;
      }
      vacEid = vac[1];
      vacVersion = tryParseDecimal(vac[2]);
      vacHash = vac[3];
      if (vacVersion == null) return null;
    }

    return ControlEdition(
      rumor: rumor,
      vsk: vskValue,
      eid: eid,
      version: version,
      prev: ep,
      contentRaw: rumor.content,
      content: content,
      createdAtMs: ms,
      vacEid: vacEid,
      vacVersion: vacVersion,
      vacHash: vacHash,
    );
  }

  /// Builds an edition rumor (unsigned) to be sealed and wrapped.
  static Nip01Event buildRumor({
    required String author,
    required int vsk,
    required String eid,
    required int version,
    required String content,
    String? prev,
    String? vacEid,
    int? vacVersion,
    String? vacHash,
    int? createdAt,
    int? ms,
  }) {
    final tags = <List<String>>[
      ['vsk', decimalTag(vsk)],
      ['eid', eid],
      ['ev', decimalTag(version)],
      if (prev != null) ['ep', prev],
      if (vacEid != null) ['vac', vacEid, decimalTag(vacVersion!), vacHash!],
    ];
    final t = createdAt ?? Nip01Event.secondsSinceEpoch();
    return makeControlRumor(
      author: author,
      tags: tags,
      content: content,
      createdAt: t,
      ms: ms ?? DateTime.now().millisecond,
    );
  }

  static Nip01Event makeControlRumor({
    required String author,
    required List<List<String>> tags,
    required String content,
    required int createdAt,
    required int ms,
  }) {
    final allTags = <List<String>>[
      ...tags,
      [Millis.tag, decimalTag(ms)],
    ];
    final id = canonicalEventId(
      pubkey: author,
      createdAt: createdAt,
      kind: RumorKinds.controlEdition,
      tags: allTags,
      content: content,
    );
    return Nip01Event(
      id: id,
      pubKey: author,
      kind: RumorKinds.controlEdition,
      tags: allTags,
      content: content,
      sig: null,
      createdAt: createdAt,
    );
  }

  static String? _tag(Nip01Event e, String name) {
    final values = _tagValues(e, name);
    return values == null ? null : values[1];
  }

  static List<String>? _tagValues(Nip01Event e, String name) {
    for (final tag in e.tags) {
      if (tag.isNotEmpty && tag[0] == name) return tag;
    }
    return null;
  }

  @override
  String toString() =>
      'ControlEdition(vsk: $vsk, eid: ${eid.substring(0, 8)}…, v: $version, author: ${author.substring(0, 8)}…)';
}
