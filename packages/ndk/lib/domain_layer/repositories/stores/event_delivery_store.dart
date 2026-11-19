import '../../entities/event_cache_records.dart';

/// Broadcast delivery state: one record per event, one target per relay.
abstract interface class EventDeliveryStore {
  /// Persist aggregate delivery state for one event.
  Future<void> saveEventDeliveryRecord(EventDeliveryRecord record);
  Future<void> saveEventDeliveryRecords(List<EventDeliveryRecord> records);
  Future<EventDeliveryRecord?> loadEventDeliveryRecord(String eventId);
  Future<List<EventDeliveryRecord>> loadEventDeliveryRecords({
    EventDeliveryStatus? status,
    int? limit,
  });
  Future<void> removeEventDeliveryRecord(String eventId);
  Future<void> removeAllEventDeliveryRecords();

  /// Persist one relay-specific delivery target.
  Future<void> saveRelayDeliveryTarget(RelayDeliveryTarget target);
  Future<void> saveRelayDeliveryTargets(List<RelayDeliveryTarget> targets);
  Future<RelayDeliveryTarget?> loadRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  });
  Future<List<RelayDeliveryTarget>> loadRelayDeliveryTargets({
    String? eventId,
    String? relayUrl,
    RelayDeliveryState? state,
    bool excludeAcked = false,
    int? limit,
  });
  Future<void> removeRelayDeliveryTarget({
    required String eventId,
    required String relayUrl,
  });
  Future<void> removeRelayDeliveryTargets(String eventId);
  Future<void> removeAllRelayDeliveryTargets();
}
