import 'package:drift/drift.dart';
import 'package:ndk/ndk.dart' show EventCacheStateRecord, Nip01Event;
import 'package:ndk/shared/nips/nip09/deletion.dart';

import 'database.dart';

int? eventExpiration(Nip01Event event) {
  final expiration = event.getFirstTag('expiration');
  return expiration == null ? null : int.tryParse(expiration);
}

/// Adds the tag and deletion target rows of [event] to [batch], after its
/// row in `events`.
void insertEventIndex(Batch batch, NdkCacheDatabase db, Nip01Event event) {
  batch.insertAll(db.eventTags, [
    for (final tag in event.tags)
      if (tag.isNotEmpty)
        EventTagsCompanion.insert(
          eventId: event.id,
          name: tag[0],
          value: Value(tag.length > 1 ? tag[1].trim().toLowerCase() : null),
        ),
  ]);
  if (event.kind != Deletion.kKind) return;

  final targets = <DeletionTargetsCompanion>[];
  void addTarget({String? eventId, String? conflictKey}) {
    targets.add(
      DeletionTargetsCompanion.insert(
        deletionId: event.id,
        pubKey: event.pubKey,
        createdAt: event.createdAt,
        eventId: Value(eventId),
        conflictKey: Value(conflictKey),
      ),
    );
  }

  // the same normalization as EventCacheStateRecord._findDeletingEvent
  for (final tag in event.tags) {
    if (tag.length < 2) continue;
    if (tag[0] == 'e') {
      addTarget(eventId: tag[1].trim().toLowerCase());
    } else if (tag[0] == 'a') {
      final conflictKey = EventCacheStateRecord.normalizeConflictKey(tag[1]);
      if (conflictKey != null) addTarget(conflictKey: conflictKey);
    }
  }
  batch.insertAll(db.deletionTargets, targets);
}
