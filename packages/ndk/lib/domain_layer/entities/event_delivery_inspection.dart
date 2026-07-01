import 'event_cache_records.dart';
import 'nip_01_event.dart';

/// Read-only joined view of one locally persisted delivery item.
///
/// This is intended for app-facing inspection of local-first state without
/// requiring callers to manually join cache records and relay targets.
class EventDeliverySnapshot {
  /// Raw event, if it is still present in the event cache.
  final Nip01Event? event;

  /// Aggregate delivery/signing state for the event.
  final EventDeliveryRecord record;

  /// Relay-specific delivery state for each persisted target.
  final List<RelayDeliveryTarget> relayTargets;

  const EventDeliverySnapshot({
    required this.event,
    required this.record,
    required this.relayTargets,
  });

  /// True when the event is still not fully delivered to all known targets.
  bool get isPendingDelivery => record.status != EventDeliveryStatus.delivered;

  /// True when the event still exists only in local cache for at least one
  /// relay target.
  bool get isOnlyLocal =>
      relayTargets.any((target) => target.state != RelayDeliveryState.acked);
}
