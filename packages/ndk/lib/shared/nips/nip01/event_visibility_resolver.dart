import '../../../domain_layer/entities/event_cache_records.dart';
import '../../../domain_layer/entities/hidden_event.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../nip09/deletion.dart';
import 'event_kind_classification.dart';

/// Raw cache read used by [EventVisibilityResolver].
///
/// Implementations must apply the given filters and nothing else: no visibility
/// rules, no implicit limit.
typedef RawEventLoader = Future<List<Nip01Event>> Function({
  List<String>? ids,
  List<String>? pubKeys,
  List<int>? kinds,
  Map<String, List<String>>? tags,
  int? since,
  int? until,
  String? search,
  int? limit,
});

/// Decides which cached events are visible, and why the others are not.
///
/// Visibility cannot be decided from a query result alone: the winner of a
/// conflict domain and the NIP-09 deletion that covers an event can both sit
/// outside it. Grouping only what a filter returned makes an old version look
/// current whenever the filter excluded its successor, for example a read by
/// event id. So the resolver runs one extra raw read to fetch that context,
/// then classifies the candidates against it.
class EventVisibilityResolver {
  /// Maximum authors per context read, keeping each query scoped without
  /// creating an excessively large `inList`.
  static const _authorBatchSize = 100;

  final RawEventLoader _loadRawEvents;

  EventVisibilityResolver(this._loadRawEvents);

  /// Keeps the candidates that are currently visible, in the given order.
  Future<List<Nip01Event>> filterVisible(
    List<Nip01Event> candidates, {
    int? now,
  }) async {
    if (candidates.isEmpty) return <Nip01Event>[];
    final currentTime = now ?? Nip01Event.secondsSinceEpoch();
    final state = await _resolveState(candidates);

    final visible = <Nip01Event>[];
    for (final event in candidates) {
      final record = state[event.id];
      if (record != null && hiddenReasons(record, currentTime).isNotEmpty) {
        continue;
      }
      visible.add(event);
    }
    return visible;
  }

  /// Implements `CacheManager.loadHiddenEvents` on top of a raw loader.
  Future<List<HiddenEvent>> loadHiddenEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    List<String>? coordinates,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
    Set<HiddenEventReason> reasons = kAllHiddenEventReasons,
    int? now,
  }) async {
    if (reasons.isEmpty) return <HiddenEvent>[];

    Set<String>? wantedConflictKeys;
    var queryPubKeys = pubKeys;
    var queryKinds = kinds;

    if (coordinates != null) {
      wantedConflictKeys = {};
      final coordinateAuthors = <String>{};
      final coordinateKinds = <int>{};
      for (final coordinate in coordinates) {
        final key = EventCacheStateRecord.normalizeConflictKey(coordinate);
        if (key == null) continue;
        wantedConflictKeys.add(key);
        final parts = coordinate.split(':');
        coordinateKinds.add(int.parse(parts[0]));
        coordinateAuthors.add(parts[1]);
      }
      if (wantedConflictKeys.isEmpty) return <HiddenEvent>[];

      // Filters combine with AND, so an explicit pubKeys/kinds is already at
      // least as narrow as the coordinates it is combined with.
      queryPubKeys ??= coordinateAuthors.toList();
      queryKinds ??= coordinateKinds.toList();
    }

    final candidates = await _loadRawEvents(
      ids: ids,
      pubKeys: queryPubKeys,
      kinds: queryKinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
    );
    if (candidates.isEmpty) return <HiddenEvent>[];

    final currentTime = now ?? Nip01Event.secondsSinceEpoch();
    final state = await _resolveState(candidates);

    final hidden = <HiddenEvent>[];
    for (final event in candidates) {
      if (wantedConflictKeys != null &&
          !wantedConflictKeys.contains(
            EventCacheStateRecord.conflictKeyFor(event),
          )) {
        continue;
      }

      final record = state[event.id];
      if (record == null) continue;

      final eventReasons = hiddenReasons(record, currentTime);
      if (eventReasons.isEmpty) continue;
      if (!eventReasons.any(reasons.contains)) continue;

      hidden.add(
        HiddenEvent(event: event, state: record, reasons: eventReasons),
      );
    }

    hidden.sort((a, b) {
      final byTime = b.event.createdAt.compareTo(a.event.createdAt);
      return byTime != 0 ? byTime : a.event.id.compareTo(b.event.id);
    });

    if (limit != null && limit > 0 && hidden.length > limit) {
      return hidden.take(limit).toList();
    }
    return hidden;
  }

  /// Why visible reads hide the event behind [record], empty when they do not.
  ///
  /// `superseded` is reported only for an event that is neither deleted nor
  /// expired: those two exclude an event from winning its conflict domain, so
  /// they would otherwise always come with a redundant `superseded`.
  static Set<HiddenEventReason> hiddenReasons(
    EventCacheStateRecord record,
    int now,
  ) {
    final reasons = <HiddenEventReason>{};
    if (record.isExpiredAt(now)) {
      reasons.add(HiddenEventReason.expired);
    }
    if (record.isDeleted) {
      reasons.add(HiddenEventReason.deleted);
    }
    if (reasons.isEmpty &&
        !record.isCurrent &&
        EventKindClassification.isReplaceableKind(record.kind)) {
      reasons.add(HiddenEventReason.superseded);
    }
    return reasons;
  }

  Future<Map<String, EventCacheStateRecord>> _resolveState(
    List<Nip01Event> candidates,
  ) async {
    final authors = <String>{};
    final contextKinds = <int>{Deletion.kKind};
    for (final event in candidates) {
      authors.add(event.pubKey);
      if (EventKindClassification.isReplaceableKind(event.kind)) {
        contextKinds.add(event.kind);
      }
    }

    final authorList = authors.toList();
    final context = <Nip01Event>[];
    for (var start = 0; start < authorList.length; start += _authorBatchSize) {
      final end = (start + _authorBatchSize).clamp(0, authorList.length);
      context.addAll(
        await _loadRawEvents(
          pubKeys: authorList.sublist(start, end),
          kinds: contextKinds.toList(),
        ),
      );
    }

    final byId = <String, Nip01Event>{};
    for (final event in candidates) {
      byId[event.id] = event;
    }
    for (final event in context) {
      byId[event.id] = event;
    }

    return {
      for (final record
          in EventCacheStateRecord.buildForEvents(byId.values.toList()))
        record.eventId: record,
    };
  }
}
