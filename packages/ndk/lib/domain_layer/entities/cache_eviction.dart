import 'contact_list.dart';
import 'metadata.dart';
import 'nip_51_list.dart';
import 'nip_65.dart';
import '../../shared/nips/nip28/channel_metadata.dart';

/// Policy used by [CacheManager.evict] and by the background eviction scheduler.
///
/// The policy is split into two conceptual phases:
/// - structural cleanup:
///   - expired events
///   - author-deleted events
///   - superseded replaceable/addressable events
/// - cap-based cleanup:
///   - keep at most N visible events for some kinds
///
/// Protection applies to cap-based cleanup, not to structural cleanup. This is
/// deliberate: protected metadata or contact list kinds should still have old
/// superseded versions removed.
class EvictionPolicy {
  // TODO doc this
  final bool sweepExpired;
  final bool sweepDeleted;
  final bool sweepSuperseded;
  final Map<int, int> kindCaps;
  final Set<int> protectedKinds;
  final Set<String> protectedEventIds;
  final Set<String> protectedPubKeys;
  final Set<String> protectedCoordinates;

  const EvictionPolicy({
    this.sweepExpired = true,
    this.sweepDeleted = true,
    this.sweepSuperseded = true,
    this.kindCaps = const {},
    this.protectedKinds = kDefaultProtectedKinds,
    this.protectedEventIds = const {},
    this.protectedPubKeys = const {},
    this.protectedCoordinates = const {},
  });

  const EvictionPolicy.safeSweep()
      : sweepExpired = true,
        sweepDeleted = true,
        sweepSuperseded = true,
        kindCaps = const {},
        protectedKinds = kDefaultProtectedKinds,
        protectedEventIds = const {},
        protectedPubKeys = const {},
        protectedCoordinates = const {};

  static const Set<int> kDefaultProtectedKinds = {
    Metadata.kKind,
    ContactList.kKind,
    Nip65.kKind,
    ChannelMetadata.kKind,
    Nip51List.kMute,
    Nip51List.kPin,
    Nip51List.kBookmarks,
    Nip51List.kCommunities,
    Nip51List.kPublicChats,
    Nip51List.kBlockedRelays,
    Nip51List.kSearchRelays,
    Nip51List.kInterests,
    Nip51List.kEmojis,
    Nip51List.kDmRelays,
    Nip51List.kFollowSet,
    Nip51List.kRelaySet,
    Nip51List.kBookmarksSet,
    Nip51List.kCurationSet,
    Nip51List.kCurationVideoSet,
    Nip51List.kKindMuteSet,
    Nip51List.kInterestsSet,
    Nip51List.kEmojisSet,
    Nip51List.kReleaseArtifactSet,
    Nip51List.kAppCurationSet,
    Nip51List.kCalendar,
    Nip51List.kStarterPacks,
    Nip51List.kStarterPacksMedia,
  };
}

/// Summary returned from one eviction run.
class EvictionResult {
  final int removedEvents;
  final int removedExpired;
  final int removedDeleted;
  final int removedSuperseded;
  final int removedByKindCap;
  final int keptDueToDeliveryState;
  final int keptProtected;

  const EvictionResult({
    required this.removedEvents,
    this.removedExpired = 0,
    this.removedDeleted = 0,
    this.removedSuperseded = 0,
    this.removedByKindCap = 0,
    this.keptDueToDeliveryState = 0,
    this.keptProtected = 0,
  });

  static const empty = EvictionResult(removedEvents: 0);
}
