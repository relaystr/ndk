import 'event_cache_records.dart';
import 'nip_01_event.dart';

/// Why a cached event is not returned by visible cache reads.
enum HiddenEventReason {
  /// A newer event won the replaceable/addressable conflict domain.
  superseded,

  /// The author published a NIP-09 deletion covering this event.
  deleted,

  /// The NIP-40 `expiration` timestamp has passed.
  expired,
}

/// Every reason, the default for hidden event queries.
const kAllHiddenEventReasons = <HiddenEventReason>{
  HiddenEventReason.superseded,
  HiddenEventReason.deleted,
  HiddenEventReason.expired,
};

/// A cached event that visible reads hide, paired with the cache state that
/// explains why it is hidden.
///
/// `reasons` is never empty. `superseded` is reported only when the event is
/// neither deleted nor expired, because those two answer the question better:
/// a deleted or expired event never wins its conflict domain, so it is always
/// non-current as well.
class HiddenEvent {
  final Nip01Event event;
  final EventCacheStateRecord state;
  final Set<HiddenEventReason> reasons;

  const HiddenEvent({
    required this.event,
    required this.state,
    required this.reasons,
  });

  bool get isSuperseded => reasons.contains(HiddenEventReason.superseded);

  bool get isDeleted => reasons.contains(HiddenEventReason.deleted);

  bool get isExpired => reasons.contains(HiddenEventReason.expired);

  /// Id of the NIP-09 event that deleted this one, when [isDeleted].
  String? get deletedByEventId => state.deletedByEventId;

  @override
  String toString() {
    final names = reasons.map((reason) => reason.name).toList()..sort();
    return 'HiddenEvent{id: ${event.id}, kind: ${event.kind}, '
        'reasons: ${names.join(',')}}';
  }
}
