import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../keys/concord_keys.dart';

/// The persistence the client needs (the plan: an abstract interface plus an
/// in-memory default). Keys are stored as join material, so any backend can
/// serialize them with [CommunityKeys.toJoinMaterial] / `fromJoinMaterial`.
///
/// All methods are keyed by `community_id`, and everything except the keys is
/// plain NIP-01 events — decrypted **rumors** on ingest and encrypted **wraps**
/// in the outbox.
abstract interface class ConcordStore {
  /// Stores (or replaces) the keys for a Community membership.
  Future<void> putCommunity(CommunityKeys keys);

  /// Loads one stored membership, or null.
  Future<CommunityKeys?> getCommunity(String communityId);

  /// Every stored membership.
  Future<List<CommunityKeys>> allCommunities();

  /// Forgets a membership and its events.
  Future<void> deleteCommunity(String communityId);

  /// Appends a decrypted rumor to a Community's log.
  Future<void> appendRumor(String communityId, Nip01Event rumor);

  /// Every decrypted rumor held for a Community (fold order is not
  /// guaranteed — folds are order-independent).
  Future<List<Nip01Event>> rumors(String communityId);

  /// Queues a signed, encrypted wrap to be published.
  Future<void> enqueueWrap(String communityId, Nip01Event wrap);

  /// The wraps still to be published.
  Future<List<Nip01Event>> outbox(String communityId);

  /// Empties the outbox (call after a successful broadcast).
  Future<void> clearOutbox(String communityId);
}

/// The default [ConcordStore], holding everything in process memory.
class InMemoryConcordStore implements ConcordStore {
  final Map<String, CommunityKeys> _communities = {};
  final Map<String, List<Nip01Event>> _rumors = {};
  final Map<String, List<Nip01Event>> _outbox = {};

  @override
  Future<void> putCommunity(CommunityKeys keys) async {
    _communities[keys.communityId] = keys;
  }

  @override
  Future<CommunityKeys?> getCommunity(String communityId) async =>
      _communities[communityId];

  @override
  Future<List<CommunityKeys>> allCommunities() async =>
      List.unmodifiable(_communities.values);

  @override
  Future<void> deleteCommunity(String communityId) async {
    _communities.remove(communityId);
    _rumors.remove(communityId);
    _outbox.remove(communityId);
  }

  @override
  Future<void> appendRumor(String communityId, Nip01Event rumor) async {
    (_rumors[communityId] ??= []).add(rumor);
  }

  @override
  Future<List<Nip01Event>> rumors(String communityId) async =>
      List.unmodifiable(_rumors[communityId] ?? const []);

  @override
  Future<void> enqueueWrap(String communityId, Nip01Event wrap) async {
    (_outbox[communityId] ??= []).add(wrap);
  }

  @override
  Future<List<Nip01Event>> outbox(String communityId) async =>
      List.unmodifiable(_outbox[communityId] ?? const []);

  @override
  Future<void> clearOutbox(String communityId) async {
    _outbox.remove(communityId);
  }
}
