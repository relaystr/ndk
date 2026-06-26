import '../../../shared/helpers/mutex_simple.dart';
import '../../entities/event_cache_records.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';

typedef EventPayloadDecryptor = Future<String?> Function();
typedef DecryptedPayloadFailureClassifier = DecryptedPayloadStatus? Function(
  Object error,
  StackTrace stackTrace,
);

/// Read-through cache for decrypted payload sidecars.
///
/// This usecase is the main app-facing abstraction for caching plaintext of
/// encrypted Nostr events. It intentionally does not rewrite [Nip01Event]
/// content. Instead it stores a viewer-specific sidecar record keyed by
/// `(eventId, viewerPubKey)`.
///
/// Typical flow:
/// 1. caller asks for plaintext
/// 2. cache is checked first
/// 3. if missing, caller-provided decryptor is executed
/// 4. successful plaintext is stored for future reads
///
/// A per-record mutex prevents the same event/viewer pair from being decrypted
/// multiple times concurrently.
class DecryptedEventPayloads {
  final CacheManager _cacheManager;
  final Map<String, MutexSimple> _recordMutexes = {};

  DecryptedEventPayloads({
    required CacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  /// Returns cached plaintext if a ready sidecar already exists.
  Future<String?> loadCachedPlaintext({
    required String eventId,
    required String viewerPubKey,
  }) async {
    final record = await _cacheManager.loadDecryptedEventPayloadRecord(
      eventId: eventId,
      viewerPubKey: viewerPubKey,
    );
    if (record == null ||
        record.status != DecryptedPayloadStatus.ready ||
        record.plaintextContent == null) {
      return null;
    }

    return record.plaintextContent;
  }

  /// Returns plaintext from cache or decrypts and persists it on demand.
  ///
  /// [scheme] describes the encryption family used by the event.
  /// [decrypt] is only executed when no usable plaintext sidecar already
  /// exists.
  ///
  /// If [classifyFailure] returns a status, the failure is also persisted so
  /// callers and tests can distinguish transient from permanent failures.
  Future<String?> loadOrDecrypt({
    required Nip01Event event,
    required String viewerPubKey,
    required DecryptedPayloadScheme scheme,
    required EventPayloadDecryptor decrypt,
    DecryptedPayloadFailureClassifier? classifyFailure,
  }) async {
    final recordKey = '${event.id}|$viewerPubKey';
    final mutex = _recordMutexes.putIfAbsent(recordKey, MutexSimple.new);

    return mutex.synchronized(() async {
      final cached = await loadCachedPlaintext(
        eventId: event.id,
        viewerPubKey: viewerPubKey,
      );
      if (cached != null) {
        return cached;
      }

      final existing = await _cacheManager.loadDecryptedEventPayloadRecord(
        eventId: event.id,
        viewerPubKey: viewerPubKey,
      );
      final now = _now();

      try {
        final plaintext = await decrypt();
        if (plaintext == null) {
          return null;
        }

        await _cacheManager.saveDecryptedEventPayloadRecord(
          DecryptedEventPayloadRecord(
            eventId: event.id,
            viewerPubKey: viewerPubKey,
            scheme: scheme,
            status: DecryptedPayloadStatus.ready,
            plaintextContent: plaintext,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            decryptedAt: now,
            sourceEventPubKey: event.pubKey,
            sourceEventKind: event.kind,
          ),
        );

        return plaintext;
      } catch (error, stackTrace) {
        final status = classifyFailure?.call(error, stackTrace);
        if (status != null) {
          await _cacheManager.saveDecryptedEventPayloadRecord(
            DecryptedEventPayloadRecord(
              eventId: event.id,
              viewerPubKey: viewerPubKey,
              scheme: scheme,
              status: status,
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
              failureReason: error.toString(),
              sourceEventPubKey: event.pubKey,
              sourceEventKind: event.kind,
            ),
          );
        }
        rethrow;
      }
    });
  }

  int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
