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
  final bool sweepDeliveredEphemeral;

  /// Remove [EventDeliveryRecord]s (and their [RelayDeliveryTarget]s) that
  /// reached [EventDeliveryStatus.delivered] longer than
  /// [completedDeliveryRetention] ago.
  ///
  /// Delivery records are otherwise cleaned only when their parent event is
  /// physically evicted. Non-ephemeral events usually stay in cache forever, so
  /// without this sweep their delivery records — including the redundant
  /// serialized event copy — accumulate indefinitely.
  final bool sweepCompletedDeliveries;

  /// Minimum age (since `completedAt`) before a delivered record is swept.
  final Duration completedDeliveryRetention;

  /// Remove terminally failed [EventDeliveryRecord]s (status
  /// [EventDeliveryStatus.failed]) older than
  /// [terminalFailedDeliveryRetention].
  ///
  /// Off by default: a failed record may still hold the only local copy of an
  /// event that never reached any relay, so removing it is potential data loss.
  /// A non-acked target also pins its event against eviction, so leaving failed
  /// records around forever keeps the event and its sidecars pinned too. Enable
  /// this to reclaim that space once failures are considered permanent.
  final bool sweepTerminalFailedDeliveries;

  /// Minimum age (since `updatedAt`) before a failed record is swept.
  final Duration terminalFailedDeliveryRetention;

  final Map<int, int> kindCaps;
  final Set<int> protectedKinds;
  final Set<String> protectedEventIds;
  final Set<String> protectedPubKeys;
  final Set<String> protectedCoordinates;

  const EvictionPolicy({
    this.sweepExpired = true,
    this.sweepDeleted = true,
    this.sweepSuperseded = true,
    this.sweepDeliveredEphemeral = true,
    this.sweepCompletedDeliveries = true,
    this.completedDeliveryRetention = const Duration(hours: 8),
    this.sweepTerminalFailedDeliveries = false,
    this.terminalFailedDeliveryRetention = const Duration(hours: 24),
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
        sweepDeliveredEphemeral = true,
        sweepCompletedDeliveries = true,
        completedDeliveryRetention = const Duration(hours: 8),
        sweepTerminalFailedDeliveries = false,
        terminalFailedDeliveryRetention = const Duration(hours: 24),
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
  final int removedDeliveredEphemeral;
  final int removedByKindCap;
  final int keptDueToDeliveryState;
  final int keptProtected;

  /// Standalone delivery records swept because they were delivered and aged
  /// past [EvictionPolicy.completedDeliveryRetention].
  final int removedCompletedDeliveries;

  /// Standalone delivery records swept because they terminally failed and aged
  /// past [EvictionPolicy.terminalFailedDeliveryRetention].
  final int removedTerminalFailedDeliveries;

  const EvictionResult({
    required this.removedEvents,
    this.removedExpired = 0,
    this.removedDeleted = 0,
    this.removedSuperseded = 0,
    this.removedDeliveredEphemeral = 0,
    this.removedByKindCap = 0,
    this.keptDueToDeliveryState = 0,
    this.keptProtected = 0,
    this.removedCompletedDeliveries = 0,
    this.removedTerminalFailedDeliveries = 0,
  });

  static const empty = EvictionResult(removedEvents: 0);

  EvictionResult copyWith({
    int? removedEvents,
    int? removedExpired,
    int? removedDeleted,
    int? removedSuperseded,
    int? removedDeliveredEphemeral,
    int? removedByKindCap,
    int? keptDueToDeliveryState,
    int? keptProtected,
    int? removedCompletedDeliveries,
    int? removedTerminalFailedDeliveries,
  }) {
    return EvictionResult(
      removedEvents: removedEvents ?? this.removedEvents,
      removedExpired: removedExpired ?? this.removedExpired,
      removedDeleted: removedDeleted ?? this.removedDeleted,
      removedSuperseded: removedSuperseded ?? this.removedSuperseded,
      removedDeliveredEphemeral:
          removedDeliveredEphemeral ?? this.removedDeliveredEphemeral,
      removedByKindCap: removedByKindCap ?? this.removedByKindCap,
      keptDueToDeliveryState:
          keptDueToDeliveryState ?? this.keptDueToDeliveryState,
      keptProtected: keptProtected ?? this.keptProtected,
      removedCompletedDeliveries:
          removedCompletedDeliveries ?? this.removedCompletedDeliveries,
      removedTerminalFailedDeliveries: removedTerminalFailedDeliveries ??
          this.removedTerminalFailedDeliveries,
    );
  }
}
