import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/hidden_event.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip01/event_visibility_resolver.dart';

const _offerKind = 38383;

Nip01Event _event(
  String id, {
  String author = 'alice',
  int kind = _offerKind,
  int time = 100,
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

// Match ObjectBox's normalized, any-tag lookup. The resolver must use the
// exact first d-tag when deciding which events share a conflict domain.
class _RawCache {
  _RawCache(this.events);

  final List<Nip01Event> events;
  int loaded = 0;
  final limits = <int?>[];
  final queries = <({
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
  })>[];

  Future<List<Nip01Event>> load({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
  }) async {
    limits.add(limit);
    queries.add((authors: pubKeys, kinds: kinds, tags: tags));
    var result = events.where((event) {
      if (ids != null && !ids.contains(event.id)) return false;
      if (pubKeys != null && !pubKeys.contains(event.pubKey)) return false;
      if (kinds != null && !kinds.contains(event.kind)) return false;
      if (since != null && event.createdAt < since) return false;
      if (until != null && event.createdAt > until) return false;
      if (search != null && !event.content.contains(search)) return false;
      for (final entry in (tags ?? <String, List<String>>{}).entries) {
        final values = entry.value
            .map((v) => v.trim().toLowerCase())
            .where((v) => v.isNotEmpty)
            .toSet();
        if (!event.tags.any(
          (tag) =>
              tag.length > 1 &&
              tag[0] == entry.key &&
              values.contains(tag[1].trim().toLowerCase()),
        )) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit != null && limit > 0) result = result.take(limit).toList();
    loaded += result.length;
    return result;
  }
}

void main() {
  test(
    'large candidate reads bound tag query size without losing winners',
    () async {
      final candidates = [
        for (var i = 0; i < 250; i++) _event('current-$i', d: 'offer-$i'),
      ];
      final cache = _RawCache(candidates);
      expect(
        await EventVisibilityResolver(
          cache.load,
        ).filterVisible(candidates, now: 300),
        candidates,
      );
      expect(cache.loaded, 250);
      final contextQueries =
          cache.queries.where((q) => q.tags != null).toList();
      expect(contextQueries, hasLength(3));
      expect(contextQueries.every((q) => q.tags!['d']!.length <= 100), isTrue);
    },
  );

  test(
    'singleton offer read loads its coordinate, not 5000 other offers',
    () async {
      final old = _event('old');
      final current = _event('current', time: 200);
      final cache = _RawCache([
        old,
        current,
        for (var i = 0; i < 5000; i++) _event('other-$i', d: 'other-$i'),
      ]);
      final resolver = EventVisibilityResolver(cache.load);

      for (var i = 0; i < 100; i++) {
        expect(await resolver.filterVisible([old], now: 300), isEmpty);
      }
      expect(cache.loaded, 200);
      expect(await resolver.filterVisible([current], now: 300), [current]);
      expect(cache.loaded, 202);
      expect(
        cache.queries
            .where((q) => q.kinds!.contains(_offerKind))
            .every((q) => q.tags?['d']?.single == 'offer'),
        isTrue,
      );
    },
  );

  test(
    'hidden ID read finds successor excluded by candidate filters',
    () async {
      final old = _event(
        'old',
        tags: [
          ['t', 'old'],
        ],
        content: 'old content',
      );
      final current = _event('current', time: 200);
      final cache = _RawCache([
        old,
        current,
        for (var i = 0; i < 5000; i++) _event('other-$i', d: 'other-$i'),
      ]);
      final hidden = await EventVisibilityResolver(cache.load).loadHiddenEvents(
        ids: ['old'],
        tags: {
          't': ['old'],
        },
        until: 150,
        search: 'old content',
        now: 300,
      );
      expect(hidden.single.event.id, 'old');
      expect(hidden.single.reasons, {HiddenEventReason.superseded});
      expect(cache.loaded, 3);
    },
  );

  test(
    'replacement context respects author, kind, and first exact d-tag',
    () async {
      final current = _event('current', d: ' MiXeD:offer ');
      final cache = _RawCache([
        current,
        _event('case-mismatch', d: 'mixed:offer', time: 200),
        _event(
          'second-d',
          d: 'another',
          time: 200,
          tags: [
            ['d', ' MiXeD:offer '],
          ],
        ),
        _event('other-author', author: 'bob', d: ' MiXeD:offer ', time: 200),
        _event('other-kind', kind: 38384, d: ' MiXeD:offer ', time: 200),
      ]);
      expect(
        await EventVisibilityResolver(
          cache.load,
        ).filterVisible([current], now: 300),
        [current],
      );
      expect(cache.loaded, 3);
    },
  );

  test(
    'missing and empty d-tags share coordinate, whitespace stays distinct',
    () async {
      final missing = _event('missing', d: null);
      final empty = _event('empty', d: '', time: 200);
      final whitespace = _event('whitespace', d: ' ', time: 400);
      final oldWhitespace = _event('old-whitespace', d: ' ', time: 100);
      final resolver = EventVisibilityResolver(
        _RawCache([missing, empty, whitespace, oldWhitespace]).load,
      );
      expect(await resolver.filterVisible([missing], now: 500), isEmpty);
      expect(await resolver.filterVisible([empty], now: 500), [empty]);
      expect(await resolver.filterVisible([oldWhitespace], now: 500), isEmpty);
      expect(await resolver.filterVisible([whitespace], now: 500), [
        whitespace,
      ]);
    },
  );

  test(
    'regular replaceable kinds ignore d-tag and scope to author/kind',
    () async {
      final old = _event('old', kind: 0, d: 'one');
      final current = _event('current', kind: 0, d: 'two', time: 200);
      final cache = _RawCache([
        old,
        current,
        _event('other', kind: 0, author: 'bob', time: 300),
        _event('other-kind', kind: 3, time: 400),
      ]);
      expect(
        await EventVisibilityResolver(
          cache.load,
        ).filterVisible([old], now: 500),
        isEmpty,
      );
      expect(cache.loaded, 2);
      expect(cache.queries.last.tags, isNull);
    },
  );

  test('deleted successor does not hide previous version', () async {
    final old = _event('old');
    final deleted = _event('deleted', time: 200);
    final deletion = _event(
      'deletion',
      kind: 5,
      time: 300,
      tags: [
        ['e', 'deleted'],
      ],
    );
    final resolver = EventVisibilityResolver(
      _RawCache([old, deleted, deletion]).load,
    );
    expect(await resolver.filterVisible([old], now: 400), [old]);
    final hidden = await resolver.loadHiddenEvents(ids: ['deleted'], now: 400);
    expect(hidden.single.reasons, {HiddenEventReason.deleted});
  });

  test(
    'coordinate deletion hides past versions but not newer successor',
    () async {
      final old = _event('old');
      final current = _event('current', time: 300);
      final deletion = _event(
        'deletion',
        kind: 5,
        time: 200,
        tags: [
          ['a', '38383:alice:offer'],
        ],
      );
      final foreign = _event(
        'foreign-deletion',
        author: 'bob',
        kind: 5,
        time: 400,
        tags: [
          ['e', 'current'],
          ['a', '38383:alice:offer'],
        ],
      );
      final resolver = EventVisibilityResolver(
        _RawCache([old, current, deletion, foreign]).load,
      );
      expect(await resolver.filterVisible([old, current], now: 500), [current]);
      final hidden = await resolver.loadHiddenEvents(ids: ['old'], now: 500);
      expect(hidden.single.reasons, {HiddenEventReason.deleted});
    },
  );

  test(
    'expiration uses requested time when choosing current version',
    () async {
      final old = _event('old');
      final expiring = _event(
        'expiring',
        time: 200,
        tags: [
          ['expiration', '400'],
        ],
      );
      final resolver = EventVisibilityResolver(_RawCache([old, expiring]).load);
      expect(await resolver.filterVisible([old], now: 300), isEmpty);
      expect(await resolver.filterVisible([old], now: 400), [old]);
      final hidden = await resolver.loadHiddenEvents(
        ids: ['expiring'],
        now: 400,
      );
      expect(hidden.single.reasons, {HiddenEventReason.expired});
    },
  );

  test('same-time tie chooses lexicographically smallest event id', () async {
    final winner = _event('aaa');
    final loser = _event('bbb');
    final resolver = EventVisibilityResolver(_RawCache([winner, loser]).load);
    expect(await resolver.filterVisible([loser, winner], now: 300), [winner]);
    final hidden = await resolver.loadHiddenEvents(ids: ['bbb'], now: 300);
    expect(hidden.single.reasons, {HiddenEventReason.superseded});
  });

  test('hidden limit applies after visibility and reason filtering', () async {
    final old = _event('old');
    final current = _event('current', time: 300);
    final expired = _event(
      'expired',
      d: 'other',
      time: 200,
      tags: [
        ['expiration', '250'],
      ],
    );
    final cache = _RawCache([old, current, expired]);
    final hidden = await EventVisibilityResolver(cache.load).loadHiddenEvents(
      kinds: [_offerKind],
      now: 400,
      limit: 1,
      reasons: {HiddenEventReason.superseded},
    );
    expect(hidden.single.event.id, 'old');
    expect(cache.limits, everyElement(isNull));
  });

  test(
    'hidden coordinate filter preserves colons and exact d-tag bytes',
    () async {
      final old = _event('old', d: ' X:y ');
      final current = _event('current', d: ' X:y ', time: 200);
      final other = _event('other', d: 'x:y');
      final otherNew = _event('other-new', d: 'x:y', time: 200);
      final resolver = EventVisibilityResolver(
        _RawCache([old, current, other, otherNew]).load,
      );
      final hidden = await resolver.loadHiddenEvents(
        coordinates: ['38383:alice: X:y '],
        now: 300,
      );
      expect(hidden.map((e) => e.event.id), ['old']);
    },
  );
}
