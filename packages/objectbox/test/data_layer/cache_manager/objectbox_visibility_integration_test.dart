// Run explicitly with the matching ObjectBox 5.3.2 native library:
// cd packages/objectbox
// RUN_OBJECTBOX_TESTS=1 LD_LIBRARY_PATH=/path/to/objectbox-5.3.2/lib \
//   flutter test test/data_layer/cache_manager/objectbox_visibility_integration_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/domain_layer/entities/hidden_event.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';

const _kind = 38383;
const _author =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _otherAuthor =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

Nip01Event _event(
  String id, {
  String author = _author,
  int kind = _kind,
  required int time,
  String? d = 'offer',
  List<List<String>> tags = const [],
  String content = '',
}) =>
    Nip01Event(
      id: id,
      pubKey: author,
      kind: kind,
      createdAt: time,
      tags: [
        if (d != null) ['d', d],
        ...tags,
      ],
      content: content,
    );

List<String> _ids(Iterable<Nip01Event> events) =>
    events.map((e) => e.id).toList();

void main() {
  group(
    'ObjectBox native visibility',
    () {
      late Directory directory;
      late DbObjectBox db;
      late int now;

      setUp(() async {
        directory = await Directory.systemTemp.createTemp(
          'bitblik-objectbox-test-',
        );
        db = DbObjectBox(directory: directory.path);
        await db.dbRdy;
        now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      });

      tearDown(() async {
        await db.close();
        await directory.delete(recursive: true);
      });

      test(
        'ID-filtered candidate still sees successor in same coordinate',
        () async {
          final old = _event('old', time: now - 200);
          final current = _event('current', time: now - 100);
          await db.saveEvents([
            old,
            current,
            for (var i = 0; i < 500; i++)
              _event('other-$i', d: 'other-$i', time: now - 300),
          ]);

          expect(await db.loadEvents(ids: ['old'], limit: 1), isEmpty);
          expect(_ids(await db.loadEvents(ids: ['current'])), ['current']);
          final hidden = await db.loadHiddenEvents(ids: ['old']);
          expect(hidden.single.event.id, 'old');
          expect(hidden.single.reasons, {HiddenEventReason.superseded});
          expect(
            _ids(
              await db.loadEvents(
                pubKeys: [_author],
                kinds: [_kind],
                tags: {
                  'd': ['offer'],
                },
                limit: 1,
              ),
            ),
            ['current'],
          );
        },
      );

      test(
        'combined author, kind, tag OR and tag AND predicates stay scoped',
        () async {
          await db.saveEvents([
            _event(
              'first',
              d: 'first',
              time: now - 100,
              tags: [
                ['t', 'market'],
              ],
              content: 'match',
            ),
            _event(
              'second',
              d: 'second',
              time: now - 90,
              tags: [
                ['t', 'market'],
              ],
              content: 'match',
            ),
            _event(
              'wrong-author',
              author: _otherAuthor,
              d: 'first',
              time: now - 80,
              tags: [
                ['t', 'market'],
              ],
              content: 'match',
            ),
            _event(
              'wrong-kind',
              kind: 38384,
              d: 'second',
              time: now - 70,
              tags: [
                ['t', 'market'],
              ],
              content: 'match',
            ),
            _event(
              'wrong-tag',
              d: 'third',
              time: now - 60,
              tags: [
                ['t', 'market'],
              ],
              content: 'match',
            ),
            _event(
              'wrong-market',
              d: 'first',
              time: now - 200,
              tags: [
                ['t', 'different'],
              ],
              content: 'match',
            ),
          ]);
          final events = await db.loadEvents(
            pubKeys: [_author],
            kinds: [_kind],
            tags: {
              'd': ['first', 'second'],
              't': ['market'],
            },
            since: now - 150,
            until: now - 85,
            search: 'match',
          );
          expect(_ids(events), ['second', 'first']);
          expect(
            _ids(
              await db.loadEvents(
                ids: ['first', 'wrong-author'],
                pubKeys: [_author],
                kinds: [_kind],
                tags: {
                  'd': ['first'],
                },
              ),
            ),
            ['first'],
          );
          expect(
            await db.loadEvents(
              pubKeys: [_author],
              kinds: [_kind],
              tags: {'d': []},
            ),
            isEmpty,
          );
        },
      );

      test(
        'first d-tag and empty or missing coordinate semantics survive native index',
        () async {
          await db.saveEvents([
            _event('old-mixed', d: ' MiXeD:offer ', time: now - 200),
            _event('current-mixed', d: ' MiXeD:offer ', time: now - 100),
            _event('normalized-other', d: 'mixed:offer', time: now - 50),
            _event(
              'second-d-only',
              d: 'another',
              time: now - 40,
              tags: [
                ['d', ' MiXeD:offer '],
              ],
            ),
            _event('missing', d: null, time: now - 200),
            _event('empty', d: '', time: now - 100),
            _event('old-space', d: ' ', time: now - 200),
            _event('current-space', d: ' ', time: now - 100),
          ]);
          expect(
            await db.loadEvents(ids: ['old-mixed', 'missing', 'old-space']),
            isEmpty,
          );
          expect(_ids(await db.loadEvents(ids: ['current-mixed'])), [
            'current-mixed',
          ]);
          expect(_ids(await db.loadEvents(ids: ['empty'])), ['empty']);
          expect(_ids(await db.loadEvents(ids: ['current-space'])), [
            'current-space',
          ]);
          final hidden = await db.loadHiddenEvents(
            coordinates: ['38383:$_author: MiXeD:offer '],
          );
          expect(hidden.map((e) => e.event.id), ['old-mixed']);
        },
      );

      test(
        'deleted and expired successors cannot replace visible predecessor',
        () async {
          await db.saveEvents([
            _event('old-deleted', d: 'deleted', time: now - 300),
            _event('new-deleted', d: 'deleted', time: now - 200),
            _event(
              'deletion',
              kind: 5,
              time: now - 100,
              tags: [
                ['e', 'new-deleted'],
              ],
            ),
            _event('old-expired', d: 'expired', time: now - 300),
            _event(
              'new-expired',
              d: 'expired',
              time: now - 200,
              tags: [
                ['expiration', '${now - 1}'],
              ],
            ),
            _event('covered', d: 'coordinate', time: now - 300),
            _event(
              'coordinate-deletion',
              kind: 5,
              time: now - 200,
              tags: [
                ['a', '38383:$_author:coordinate'],
              ],
            ),
            _event('after-deletion', d: 'coordinate', time: now - 100),
          ]);
          expect(_ids(await db.loadEvents(ids: ['old-deleted'])), [
            'old-deleted',
          ]);
          expect(_ids(await db.loadEvents(ids: ['old-expired'])), [
            'old-expired',
          ]);
          expect(
            _ids(
              await db.loadEvents(
                tags: {
                  'd': ['coordinate'],
                },
                kinds: [_kind],
              ),
            ),
            ['after-deletion'],
          );
          final deleted = await db.loadHiddenEvents(
            ids: ['new-deleted', 'covered'],
            reasons: {HiddenEventReason.deleted},
          );
          expect(deleted.map((e) => e.event.id), ['new-deleted', 'covered']);
          expect(
            deleted.every((e) => e.reasons.contains(HiddenEventReason.deleted)),
            isTrue,
          );
          final expired = await db.loadHiddenEvents(ids: ['new-expired']);
          expect(expired.single.reasons, {HiddenEventReason.expired});
        },
      );

      test(
        'visible and hidden limits apply after visibility and reason checks',
        () async {
          await db.saveEvents([
            _event(
              'expired-newest',
              d: 'expired',
              time: now - 10,
              tags: [
                ['expiration', '${now - 1}'],
              ],
            ),
            _event('visible', d: 'visible', time: now - 20),
            _event('old', d: 'visible', time: now - 30),
          ]);
          expect(_ids(await db.loadEvents(kinds: [_kind], limit: 1)), [
            'visible',
          ]);
          final hidden = await db.loadHiddenEvents(
            kinds: [_kind],
            limit: 1,
            reasons: {HiddenEventReason.superseded},
          );
          expect(hidden.single.event.id, 'old');
          expect(hidden.single.reasons, {HiddenEventReason.superseded});
        },
      );

      test(
        'reopening same schema preserves raw versions and visibility',
        () async {
          final old = _event('persisted-old', time: now - 200);
          final current = _event('persisted-current', time: now - 100);
          await db.saveEvents([old, current]);
          await db.addEventSource(
            eventId: current.id,
            relayUrl: 'wss://relay.example',
          );
          await db.close();
          db = DbObjectBox(directory: directory.path);
          await db.dbRdy;

          expect(
            _ids(
              await db.loadEvents(
                pubKeys: [_author],
                kinds: [_kind],
                tags: {
                  'd': ['offer'],
                },
              ),
            ),
            ['persisted-current'],
          );
          expect(
            (await db.loadHiddenEvents(ids: [old.id])).single.event.id,
            old.id,
          );
          expect((await db.loadEvent(old.id))?.id, old.id);
          expect(await db.loadEventSources(current.id), [
            'wss://relay.example',
          ]);
          expect(await db.saveEventIfAbsent(current), isFalse);
        },
      );
    },
    skip: Platform.environment['RUN_OBJECTBOX_TESTS'] != '1'
        ? 'Set RUN_OBJECTBOX_TESTS=1 and provide matching ObjectBox native library.'
        : false,
  );
}
