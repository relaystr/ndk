import '../../entities/event_cache_records.dart';

/// Plaintext sidecars of encrypted events, one per event and viewer.
abstract interface class DecryptedEventPayloadStore {
  /// Persist one plaintext sidecar for an encrypted event.
  Future<void> saveDecryptedEventPayloadRecord(
    DecryptedEventPayloadRecord record,
  );
  Future<void> saveDecryptedEventPayloadRecords(
    List<DecryptedEventPayloadRecord> records,
  );
  Future<DecryptedEventPayloadRecord?> loadDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  });
  Future<List<DecryptedEventPayloadRecord>> loadDecryptedEventPayloadRecords({
    String? eventId,
    String? viewerPubKey,
    DecryptedPayloadStatus? status,
    int? limit,
  });
  Future<void> removeDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  });
  Future<void> removeDecryptedEventPayloadRecords(String eventId);
  Future<void> removeAllDecryptedEventPayloadRecords();
}
