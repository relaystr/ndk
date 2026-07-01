import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/event_eviction_planner.dart';
import 'package:ndk/shared/nips/nip09/deletion.dart';
import 'package:test/test.dart';

void main() {
  // NIP-09 deletions can target addressable/replaceable events by coordinate
  // (`a` tag = `kind:pubkey:d-tag`) instead of by event id (`e` tag). These
  // tests exercise that path, which is currently unhandled.
  const author =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const addressableKind = 30023; // long-form content, addressable
  const dTag = 'my-article';
  const coordinate = '$addressableKind:$author:$dTag';

  Nip01Event addressableEvent({required int createdAt, String content = 'v'}) {
    return Nip01Event(
      pubKey: author,
      kind: addressableKind,
      tags: const [
        ['d', dTag],
      ],
      content: content,
      createdAt: createdAt,
    );
  }

  Nip01Event coordinateDeletion({required int createdAt}) {
    return Nip01Event(
      pubKey: author,
      kind: Deletion.kKind,
      tags: const [
        ['a', coordinate],
        ['k', '$addressableKind'],
      ],
      content: 'delete by coordinate',
      createdAt: createdAt,
    );
  }

  group('EventEvictionPlanner addressable (a-tag) deletion', () {
    test('sweeps an addressable event deleted by coordinate', () {
      final target = addressableEvent(createdAt: 1700000000);
      final deletion = coordinateDeletion(createdAt: 1700000001);

      final plan = EventEvictionPlanner.plan(
        rawEvents: [target, deletion],
        lockedEventIds: const {},
        policy: const EvictionPolicy(),
        now: 1700000100,
      );

      expect(
        plan.eventIdsToRemove,
        contains(target.id),
        reason: 'addressable event deleted via `a` tag should be removed',
      );
      expect(plan.removedDeleted, 1);
    });

    test('keeps a newer addressable version published after the deletion', () {
      // NIP-09: a coordinate deletion only removes matches with
      // created_at <= the deletion. A later re-publish must survive.
      final deletion = coordinateDeletion(createdAt: 1700000001);
      final newerVersion = addressableEvent(
        createdAt: 1700000002,
        content: 'republished',
      );

      final plan = EventEvictionPlanner.plan(
        rawEvents: [deletion, newerVersion],
        lockedEventIds: const {},
        policy: const EvictionPolicy(),
        now: 1700000100,
      );

      expect(
        plan.eventIdsToRemove,
        isNot(contains(newerVersion.id)),
        reason: 'a version newer than the deletion must not be swept',
      );
    });

    test('state-record path sweeps an addressable event deleted by coordinate',
        () {
      final target = addressableEvent(createdAt: 1700000000);
      final deletion = coordinateDeletion(createdAt: 1700000001);
      final stateRecords = EventCacheStateRecord.buildForEvents([
        target,
        deletion,
      ], now: 1700000100);

      final plan = EventEvictionPlanner.planFromStateRecords(
        stateRecords: stateRecords,
        lockedEventIds: const {},
        policy: const EvictionPolicy(),
        now: 1700000100,
      );

      expect(plan.eventIdsToRemove, contains(target.id));
      expect(plan.removedDeleted, 1);
    });
  });

  group('MemCacheManager addressable (a-tag) deletion visibility', () {
    test('hides an addressable event deleted by coordinate', () async {
      final cache = MemCacheManager();
      final target = addressableEvent(createdAt: 1700000000);
      final deletion = coordinateDeletion(createdAt: 1700000001);

      await cache.saveEvent(target);
      await cache.saveEvent(deletion);

      final visible = await cache.loadEvents(ids: [target.id]);

      expect(
        visible.map((e) => e.id),
        isNot(contains(target.id)),
        reason:
            'addressable event tombstoned via `a` tag should not be visible',
      );
    });

    test('eviction uses derived state to sweep obsolete replaceable versions',
        () async {
      final cache = MemCacheManager();
      final oldVersion = addressableEvent(
        createdAt: 1700000000,
        content: 'old version',
      );
      final newVersion = addressableEvent(
        createdAt: 1700000001,
        content: 'new version',
      );

      await cache.saveEvents([oldVersion, newVersion]);

      final result =
          await cache.evict(const EvictionPolicy(sweepSuperseded: true));

      expect(result.removedSuperseded, 1);
      final remaining =
          await cache.loadEvents(pubKeys: [author], kinds: [addressableKind]);
      expect(remaining.map((event) => event.id), contains(newVersion.id));
      expect(
          remaining.map((event) => event.id), isNot(contains(oldVersion.id)));
    });
  });
}
