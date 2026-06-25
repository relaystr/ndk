import '../../../shared/helpers/mutex_simple.dart';
import '../../entities/event_cache_records.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';

typedef EventPayloadDecryptor = Future<String?> Function();
typedef DecryptedPayloadFailureClassifier = DecryptedPayloadStatus? Function(
  Object error,
  StackTrace stackTrace,
);

class DecryptedEventPayloads {
  final CacheManager _cacheManager;
  final Map<String, MutexSimple> _recordMutexes = {};

  DecryptedEventPayloads({
    required CacheManager cacheManager,
  }) : _cacheManager = cacheManager;

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
