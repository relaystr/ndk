import '../../../domain_layer/entities/cache_eviction.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import 'event_kind_classification.dart';

/// Result of planning one eviction pass before the backend removes any rows.
class EventEvictionPlan {
  final Set<String> eventIdsToRemove;
  final int removedExpired;
  final int removedDeleted;
  final int removedSuperseded;
  final int removedByKindCap;
  final int keptDueToDeliveryState;
  final int keptProtected;

  const EventEvictionPlan({
    required this.eventIdsToRemove,
    required this.removedExpired,
    required this.removedDeleted,
    required this.removedSuperseded,
    required this.removedByKindCap,
    required this.keptDueToDeliveryState,
    required this.keptProtected,
  });

  EvictionResult toResult() {
    return EvictionResult(
      removedEvents: eventIdsToRemove.length,
      removedExpired: removedExpired,
      removedDeleted: removedDeleted,
      removedSuperseded: removedSuperseded,
      removedByKindCap: removedByKindCap,
      keptDueToDeliveryState: keptDueToDeliveryState,
      keptProtected: keptProtected,
    );
  }
}

/// Pure planner for cache eviction decisions.
///
/// This class is backend-agnostic: it receives raw events plus a small amount
/// of external state (`lockedEventIds`) and decides what should be removed.
///
/// Important semantics:
/// - structural cleanup runs before kind caps
/// - "visible" means:
///   - not expired
///   - not tombstoned by author delete
///   - latest replaceable/addressable winner for its coordinate
/// - protection only prevents cap-based eviction, not structural cleanup
class EventEvictionPlanner {
  static EventEvictionPlan plan({
    required List<Nip01Event> rawEvents,
    required Set<String> lockedEventIds,
    required EvictionPolicy policy,
    int? now,
  }) {
    final currentTime = now ?? Nip01Event.secondsSinceEpoch();
    final deletionEvents =
        rawEvents.where((event) => event.kind == 5).toList(growable: false);
    final visibleIds = _visibleIds(rawEvents, deletionEvents, currentTime);

    final eventIdsToRemove = <String>{};
    var removedExpired = 0;
    var removedDeleted = 0;
    var removedSuperseded = 0;
    var removedByKindCap = 0;
    var keptDueToDeliveryState = 0;
    var keptProtected = 0;
    final eligibleByKind = <int, List<Nip01Event>>{};

    for (final event in rawEvents) {
      // Delivery-locked events are part of pending background delivery and
      // should not disappear while that state exists.
      if (lockedEventIds.contains(event.id)) {
        keptDueToDeliveryState++;
        continue;
      }

      if (policy.sweepExpired && _isExpired(event, currentTime)) {
        eventIdsToRemove.add(event.id);
        removedExpired++;
        continue;
      }

      if (policy.sweepDeleted && _isDeletedByAuthor(event, deletionEvents)) {
        eventIdsToRemove.add(event.id);
        removedDeleted++;
        continue;
      }

      if (policy.sweepSuperseded &&
          EventKindClassification.isReplaceableKind(event.kind) &&
          !visibleIds.contains(event.id)) {
        eventIdsToRemove.add(event.id);
        removedSuperseded++;
        continue;
      }

      if (visibleIds.contains(event.id)) {
        if (_isCapProtected(event, policy)) {
          keptProtected++;
          continue;
        }
        eligibleByKind.putIfAbsent(event.kind, () => <Nip01Event>[]).add(event);
      }
    }

    for (final entry in policy.kindCaps.entries) {
      final cap = entry.value;
      final eventsForKind = eligibleByKind[entry.key];
      if (eventsForKind == null || cap < 0) continue;

      eventsForKind.sort(_compareNewestFirst);
      final removable = cap >= eventsForKind.length
          ? const <Nip01Event>[]
          : eventsForKind.skip(cap);
      for (final event in removable) {
        if (eventIdsToRemove.add(event.id)) {
          removedByKindCap++;
        }
      }
    }

    return EventEvictionPlan(
      eventIdsToRemove: eventIdsToRemove,
      removedExpired: removedExpired,
      removedDeleted: removedDeleted,
      removedSuperseded: removedSuperseded,
      removedByKindCap: removedByKindCap,
      keptDueToDeliveryState: keptDueToDeliveryState,
      keptProtected: keptProtected,
    );
  }

  static bool _isCapProtected(Nip01Event event, EvictionPolicy policy) {
    if (policy.protectedEventIds.contains(event.id)) return true;
    if (policy.protectedPubKeys.contains(event.pubKey)) return true;
    if (policy.protectedKinds.contains(event.kind)) return true;

    final coordinateKey = _coordinateKey(event);
    if (coordinateKey != null &&
        policy.protectedCoordinates.contains(coordinateKey)) {
      return true;
    }

    return false;
  }

  static Set<String> _visibleIds(
    List<Nip01Event> events,
    List<Nip01Event> deletionEvents,
    int now,
  ) {
    // Visibility is computed independently from the backend so every cache
    // implementation applies the same local-first rules.
    final visible = <String>{};
    final replaceableWinners = <String, Nip01Event>{};

    for (final event in events) {
      if (_isExpired(event, now)) continue;
      if (_isDeletedByAuthor(event, deletionEvents)) continue;

      final coordinateKey = _coordinateKey(event);
      if (coordinateKey == null) {
        visible.add(event.id);
        continue;
      }

      final current = replaceableWinners[coordinateKey];
      if (current == null || _isMoreRecentReplaceable(event, current)) {
        replaceableWinners[coordinateKey] = event;
      }
    }

    visible.addAll(replaceableWinners.values.map((event) => event.id));
    return visible;
  }

  static bool _isDeletedByAuthor(
    Nip01Event target,
    List<Nip01Event> deletionEvents,
  ) {
    if (target.kind == 5) return false;

    // Addressable/replaceable events are deleted by coordinate (`a` tag), so a
    // later version published after the deletion stays visible (NIP-09 only
    // deletes coordinate matches with created_at <= the deletion).
    final coordinate = _coordinateKey(target);

    for (final event in deletionEvents) {
      if (event.pubKey != target.pubKey) continue;
      if (event.getTags('e').contains(target.id.toLowerCase())) {
        return true;
      }
      if (coordinate != null &&
          event.createdAt >= target.createdAt &&
          event.getTags('a').contains(coordinate)) {
        return true;
      }
    }

    return false;
  }

  static bool _isExpired(Nip01Event event, int now) {
    final expirationValue = event.getFirstTag('expiration');
    if (expirationValue == null) return false;
    final expiration = int.tryParse(expirationValue);
    if (expiration == null) return false;
    return expiration <= now;
  }

  static String? _coordinateKey(Nip01Event event) {
    if (!EventKindClassification.isReplaceableKind(event.kind)) return null;
    final dTag = event.getDtag() ?? '';
    return '${event.kind}:${event.pubKey}:$dTag';
  }

  static bool _isMoreRecentReplaceable(
    Nip01Event candidate,
    Nip01Event current,
  ) {
    return _compareNewestFirst(candidate, current) < 0;
  }

  static int _compareNewestFirst(Nip01Event a, Nip01Event b) {
    if (a.createdAt != b.createdAt) {
      return b.createdAt.compareTo(a.createdAt);
    }

    return a.id.compareTo(b.id);
  }
}
