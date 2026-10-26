import 'dart:convert';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';

// ndk's NIP-44 is marked experimental upstream; the wire format is frozen by
// the NIP itself.
// ignore_for_file: experimental_member_use

import '../core/concord_constants.dart';
import '../core/encoding.dart';
import '../keys/concord_keys.dart';
import '../stream/stream_envelope.dart';

/// One Community membership in the Community List (CORD-02 §8).
///
/// [seed] holds the earliest epoch the member ever held (the backfill
/// anchor, only ever moving *backward*); [current] the freshest snapshot
/// (only ever moving *forward*).
class CommunityListEntry {
  final String communityId;
  final CommunityKeys seed;
  final CommunityKeys current;

  /// Unix **milliseconds**; tiebreaks against a tombstone.
  final int addedAt;

  const CommunityListEntry({
    required this.communityId,
    required this.seed,
    required this.current,
    required this.addedAt,
  });

  CommunityListEntry copyWith({
    CommunityKeys? seed,
    CommunityKeys? current,
    int? addedAt,
  }) => CommunityListEntry(
    communityId: communityId,
    seed: seed ?? this.seed,
    current: current ?? this.current,
    addedAt: addedAt ?? this.addedAt,
  );

  /// Merges two snapshots of the same membership: seed keeps the **lower**
  /// epoch, current the **higher**; an epoch tie breaks on the
  /// lexicographically lowest canonical bytes of the whole snapshot (a total
  /// order, so devices never flap).
  CommunityListEntry mergeWith(CommunityListEntry other) {
    final newSeed = other.seed.rootEpoch < seed.rootEpoch
        ? other.seed
        : (other.seed.rootEpoch > seed.rootEpoch
              ? seed
              : _lowerCanonical(seed, other.seed));
    final newCurrent = other.current.rootEpoch > current.rootEpoch
        ? other.current
        : (other.current.rootEpoch < current.rootEpoch
              ? current
              : _lowerCanonical(current, other.current));
    return CommunityListEntry(
      communityId: communityId,
      seed: newSeed,
      current: newCurrent,
      addedAt: addedAt > other.addedAt ? addedAt : other.addedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'community_id': communityId,
    'seed': seed.toJoinMaterial(),
    'current': current.toJoinMaterial(),
    'added_at': addedAt,
  };

  static CommunityListEntry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final communityId = raw['community_id'];
    final addedAt = raw['added_at'];
    if (communityId is! String || addedAt is! int) return null;
    final seed = CommunityKeys.fromJoinMaterial(
      raw['seed'],
      expectedCommunityId: communityId,
    );
    final current = CommunityKeys.fromJoinMaterial(
      raw['current'],
      expectedCommunityId: communityId,
    );
    if (seed == null || current == null) return null;
    return CommunityListEntry(
      communityId: communityId,
      seed: seed,
      current: current,
      addedAt: addedAt,
    );
  }

  static CommunityKeys _lowerCanonical(CommunityKeys a, CommunityKeys b) {
    final ja = encodeJson(a.toJoinMaterial());
    final jb = encodeJson(b.toJoinMaterial());
    return ja.compareTo(jb) <= 0 ? a : b;
  }
}

/// A permanent departure record (CORD-02 §8). Kept in the document so merges
/// never depend on gossip order.
class CommunityListTombstone {
  final String communityId;

  /// Unix **milliseconds**.
  final int removedAt;

  const CommunityListTombstone({
    required this.communityId,
    required this.removedAt,
  });

  Map<String, Object?> toJson() => {
    'community_id': communityId,
    'removed_at': removedAt,
  };

  static CommunityListTombstone? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final communityId = raw['community_id'];
    final removedAt = raw['removed_at'];
    if (communityId is! String || removedAt is! int) return null;
    try {
      checkHex32(communityId, 'community_id');
    } catch (_) {
      return null;
    }
    return CommunityListTombstone(
      communityId: communityId,
      removedAt: removedAt,
    );
  }
}

/// A member's memberships (CORD-02 §8): every Community they are in and
/// every one they have left. NIP-44 self-encrypted as one kind 13302
/// replaceable document.
class CommunityList {
  final List<CommunityListEntry> entries;
  final List<CommunityListTombstone> tombstones;

  const CommunityList({this.entries = const [], this.tombstones = const []});

  static const int maxMemberships = Caps.communityListMemberships;

  Map<String, Object?> toJson() => {
    'entries': [for (final e in entries) e.toJson()],
    'tombstones': [for (final t in tombstones) t.toJson()],
  };

  String toJsonString() {
    final json = encodeJson(toJson());
    // NIP-44 hard-caps one plaintext; a List that does not fit refuses to
    // publish rather than silently truncating memberships (CORD-02 §8).
    if (utf8.encode(json).length > Caps.nip44Plaintext) {
      throw SizeError('the Community List exceeds the NIP-44 plaintext cap');
    }
    return json;
  }

  static CommunityList? tryParse(String jsonString) {
    final Object? raw;
    try {
      raw = jsonDecode(jsonString);
    } catch (_) {
      return null;
    }
    if (raw is! Map) return null;

    final entries = <CommunityListEntry>[];
    final rawEntries = raw['entries'];
    if (rawEntries is List) {
      if (rawEntries.length > maxMemberships * 4) return null;
      for (final entry in rawEntries) {
        final parsed = CommunityListEntry.tryParse(entry);
        if (parsed == null) return null;
        entries.add(parsed);
      }
    }
    if (entries.length > maxMemberships) {
      entries.removeRange(maxMemberships, entries.length);
    }

    final tombstones = <CommunityListTombstone>[];
    final rawTombs = raw['tombstones'];
    if (rawTombs is List) {
      for (final entry in rawTombs) {
        final parsed = CommunityListTombstone.tryParse(entry);
        if (parsed == null) continue; // round-trip-safe: drop malformed graves
        tombstones.add(parsed);
      }
    }

    return CommunityList(entries: entries, tombstones: tombstones);
  }

  /// Merges another device's List. Tombstones union (newest wins) and are
  /// permanent; an entry survives a tombstone only when its `added_at` is
  /// strictly newer.
  CommunityList merge(CommunityList other) {
    final byId = <String, CommunityListEntry>{
      for (final e in entries) e.communityId: e,
    };
    for (final o in other.entries) {
      final existing = byId[o.communityId];
      byId[o.communityId] = existing == null ? o : existing.mergeWith(o);
    }

    final tombById = <String, CommunityListTombstone>{
      for (final t in tombstones) t.communityId: t,
    };
    for (final t in other.tombstones) {
      final existing = tombById[t.communityId];
      if (existing == null || t.removedAt > existing.removedAt) {
        tombById[t.communityId] = t;
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return CommunityList(
      entries: merged.take(maxMemberships).toList(),
      tombstones: tombById.values.toList(),
    );
  }

  /// Whether [communityId] is currently present (a tombstone newer than the
  /// entry's `added_at` removes it).
  bool isMember(String communityId) {
    final entry = _entryOf(communityId);
    if (entry == null) return false;
    final tomb = _tombOf(communityId);
    if (tomb == null) return true;
    return entry.addedAt > tomb.removedAt;
  }

  CommunityListEntry? entryOf(String communityId) =>
      isMember(communityId) ? _entryOf(communityId) : null;

  CommunityListEntry? _entryOf(String communityId) {
    for (final e in entries) {
      if (e.communityId == communityId) return e;
    }
    return null;
  }

  CommunityListTombstone? _tombOf(String communityId) {
    for (final t in tombstones) {
      if (t.communityId == communityId) return t;
    }
    return null;
  }

  CommunityList addOrUpdate(CommunityKeys keys, {required int addedAt}) {
    final existing = _entryOf(keys.communityId);
    final entry = existing == null
        ? CommunityListEntry(
            communityId: keys.communityId,
            seed: keys,
            current: keys,
            addedAt: addedAt,
          )
        : existing.copyWith(
            current: keys,
            // Re-adding after a tombstone must advance `added_at` past the
            // grave, or the membership stays removed (CORD-02 §8).
            addedAt: existing.addedAt > addedAt ? existing.addedAt : addedAt,
          );
    final next = [
      for (final e in entries)
        if (e.communityId != keys.communityId) e,
      entry,
    ];
    return CommunityList(entries: next, tombstones: tombstones);
  }

  CommunityList remove(String communityId, {required int removedAt}) {
    final tombs = [
      for (final t in tombstones)
        if (t.communityId != communityId) t,
      CommunityListTombstone(communityId: communityId, removedAt: removedAt),
    ];
    return CommunityList(entries: entries, tombstones: tombs);
  }
}

/// The kind 13302 document build/parse, self-encrypted with the member's real
/// signer (CORD-02 §8).
class CommunityListDocument {
  const CommunityListDocument._();

  static const int kind = RumorKinds.communityList;

  static Future<Nip01Event> build({
    required EventSigner signer,
    required CommunityList list,
    int? createdAt,
  }) async {
    final me = signer.getPublicKey();
    checkHex32(me, 'community list author');
    final plaintext = list.toJsonString();
    final content = await signer.encryptNip44(
      plaintext: plaintext,
      recipientPubKey: me,
    );
    if (content == null) {
      throw StateError('the signer refused to encrypt the Community List');
    }
    final t = createdAt ?? Nip01Event.secondsSinceEpoch();
    final id = canonicalEventId(
      pubkey: me,
      createdAt: t,
      kind: kind,
      tags: const [],
      content: content,
    );
    return signer.sign(
      Nip01Event(
        id: id,
        pubKey: me,
        kind: kind,
        tags: const [],
        content: content,
        sig: null,
        createdAt: t,
      ),
    );
  }

  static Future<CommunityList?> parse({
    required Nip01Event event,
    required EventSigner signer,
  }) async {
    if (event.kind != kind) return null;
    final me = signer.getPublicKey();
    if (event.pubKey != me) return null;
    final String plaintext;
    try {
      plaintext = (await signer.decryptNip44(
        ciphertext: event.content,
        senderPubKey: me,
      ))!;
    } catch (_) {
      return null;
    }
    return CommunityList.tryParse(plaintext);
  }
}
