part of 'cache_manager_test_suite.dart';

const _hiddenAuthor = 'hidden_event_author';

Nip01Event _article({
  required String dTag,
  required int createdAt,
  required String content,
}) {
  return Nip01Event(
    pubKey: _hiddenAuthor,
    kind: 30023,
    tags: [
      ['d', dTag],
    ],
    content: content,
    createdAt: createdAt,
  );
}

void _runHiddenEventTests(CacheManager Function() getCacheManager) {
  test('loadHiddenEvents returns previous versions, newest first', () async {
    final cacheManager = getCacheManager();

    final v1 = _article(dTag: 'article-a', createdAt: 100, content: 'draft');
    final v2 = _article(dTag: 'article-a', createdAt: 200, content: 'revised');
    final v3 = _article(dTag: 'article-a', createdAt: 300, content: 'final');
    await cacheManager.saveEvents([v1, v2, v3]);

    final hidden = await cacheManager.loadHiddenEvents(
      coordinates: ['30023:$_hiddenAuthor:article-a'],
    );

    expect(hidden.map((e) => e.event.content), equals(['revised', 'draft']));
    expect(
      hidden.every((e) => e.reasons.single == HiddenEventReason.superseded),
      isTrue,
    );
    expect(hidden.every((e) => !e.state.isCurrent), isTrue);

    final visible = await cacheManager.loadEvents(
      pubKeys: [_hiddenAuthor],
      kinds: [30023],
    );
    expect(visible.map((e) => e.content), equals(['final']));
  });

  test('a limited read falls back to the newest visible event', () async {
    final cacheManager = getCacheManager();

    final v1 = _article(dTag: 'article-a', createdAt: 100, content: 'kept');
    final v2 = _article(dTag: 'article-a', createdAt: 200, content: 'deleted');
    final deletion = Nip01Event(
      pubKey: _hiddenAuthor,
      kind: 5,
      tags: [
        ['e', v2.id],
      ],
      content: 'gone',
      createdAt: 250,
    );
    await cacheManager.saveEvents([v1, v2, deletion]);

    // A limit must not be spent on events the visibility rules then remove.
    final visible = await cacheManager.loadEvents(
      pubKeys: [_hiddenAuthor],
      kinds: [30023],
      limit: 1,
    );

    expect(visible.map((e) => e.content), equals(['kept']));
  });

  test('loadEvents hides a superseded version queried by id', () async {
    final cacheManager = getCacheManager();

    final v1 = _article(dTag: 'article-a', createdAt: 100, content: 'draft');
    final v2 = _article(dTag: 'article-a', createdAt: 200, content: 'final');
    await cacheManager.saveEvents([v1, v2]);

    expect(await cacheManager.loadEvents(ids: [v1.id]), isEmpty);
    expect((await cacheManager.loadEvents(ids: [v2.id])).single.id, v2.id);
    // The raw read by id stays the escape hatch for callers that hold an id.
    expect(await cacheManager.loadEvent(v1.id), isNotNull);
  });

  test('coordinates filter selects a single conflict domain', () async {
    final cacheManager = getCacheManager();

    await cacheManager.saveEvents([
      _article(dTag: 'article-a', createdAt: 100, content: 'a old'),
      _article(dTag: 'article-a', createdAt: 200, content: 'a new'),
      _article(dTag: 'article-b', createdAt: 100, content: 'b old'),
      _article(dTag: 'article-b', createdAt: 200, content: 'b new'),
    ]);

    final hidden = await cacheManager.loadHiddenEvents(
      coordinates: ['30023:$_hiddenAuthor:article-b'],
    );

    expect(hidden.map((e) => e.event.content), equals(['b old']));
  });

  test('coordinates accept an a tag value for a replaceable kind', () async {
    final cacheManager = getCacheManager();

    await cacheManager.saveEvents([
      Nip01Event(
        pubKey: _hiddenAuthor,
        kind: Metadata.kKind,
        tags: [],
        content: '{"name":"old"}',
        createdAt: 100,
      ),
      Nip01Event(
        pubKey: _hiddenAuthor,
        kind: Metadata.kKind,
        tags: [],
        content: '{"name":"new"}',
        createdAt: 200,
      ),
    ]);

    final withoutDTag = await cacheManager.loadHiddenEvents(
      coordinates: ['${Metadata.kKind}:$_hiddenAuthor'],
    );
    final withEmptyDTag = await cacheManager.loadHiddenEvents(
      coordinates: ['${Metadata.kKind}:$_hiddenAuthor:'],
    );
    // A kind with no d-tag has no domain named by a non empty third segment.
    final withJunkDTag = await cacheManager.loadHiddenEvents(
      coordinates: ['${Metadata.kKind}:$_hiddenAuthor:unexpected'],
    );

    expect(withoutDTag.map((e) => e.event.content), equals(['{"name":"old"}']));
    expect(
      withEmptyDTag.map((e) => e.event.id),
      equals(withoutDTag.map((e) => e.event.id)),
    );
    expect(withJunkDTag, isEmpty);
  });

  test('reasons filter separates deleted from superseded', () async {
    final cacheManager = getCacheManager();

    final supersededArticle = _article(
      dTag: 'article-a',
      createdAt: 100,
      content: 'a old',
    );
    final currentArticle = _article(
      dTag: 'article-a',
      createdAt: 200,
      content: 'a new',
    );
    final deletedArticle = _article(
      dTag: 'article-b',
      createdAt: 100,
      content: 'b deleted',
    );
    final deletion = Nip01Event(
      pubKey: _hiddenAuthor,
      kind: 5,
      tags: [
        ['a', '30023:$_hiddenAuthor:article-b'],
      ],
      content: 'gone',
      createdAt: 150,
    );
    await cacheManager.saveEvents([
      supersededArticle,
      currentArticle,
      deletedArticle,
      deletion,
    ]);

    final superseded = await cacheManager.loadHiddenEvents(
      kinds: [30023],
      reasons: {HiddenEventReason.superseded},
    );
    final deleted = await cacheManager.loadHiddenEvents(
      kinds: [30023],
      reasons: {HiddenEventReason.deleted},
    );

    expect(superseded.map((e) => e.event.id), equals([supersededArticle.id]));
    expect(deleted.map((e) => e.event.id), equals([deletedArticle.id]));
    expect(deleted.single.deletedByEventId, equals(deletion.id));
    expect(deleted.single.isDeleted, isTrue);
  });

  test('loadHiddenEvents returns a deleted regular event', () async {
    final cacheManager = getCacheManager();

    final note = Nip01Event(
      pubKey: _hiddenAuthor,
      kind: 1,
      tags: [],
      content: 'deleted note',
      createdAt: 100,
    );
    final deletion = Nip01Event(
      pubKey: _hiddenAuthor,
      kind: 5,
      tags: [
        ['e', note.id],
      ],
      content: 'gone',
      createdAt: 150,
    );
    await cacheManager.saveEvents([note, deletion]);

    final hidden = await cacheManager.loadHiddenEvents(kinds: [1]);

    expect(hidden.single.event.content, equals('deleted note'));
    expect(hidden.single.reasons, equals({HiddenEventReason.deleted}));
    expect(hidden.single.deletedByEventId, equals(deletion.id));
  });

  test('loadHiddenEvents reports an expired event', () async {
    final cacheManager = getCacheManager();

    final expired = Nip01Event(
      pubKey: _hiddenAuthor,
      kind: 1,
      tags: [
        ['expiration', '1'],
      ],
      content: 'expired note',
      createdAt: 100,
    );
    await cacheManager.saveEvent(expired);

    final hidden = await cacheManager.loadHiddenEvents(
      reasons: {HiddenEventReason.expired},
    );

    expect(hidden.single.event.id, equals(expired.id));
    expect(hidden.single.isExpired, isTrue);
    expect(await cacheManager.loadEvents(ids: [expired.id]), isEmpty);
  });

  test('limit applies after hidden events are selected', () async {
    final cacheManager = getCacheManager();

    await cacheManager.saveEvents([
      _article(dTag: 'article-a', createdAt: 100, content: 'oldest'),
      _article(dTag: 'article-a', createdAt: 200, content: 'middle'),
      _article(dTag: 'article-a', createdAt: 300, content: 'current'),
    ]);

    final hidden = await cacheManager.loadHiddenEvents(
      coordinates: ['30023:$_hiddenAuthor:article-a'],
      limit: 1,
    );

    expect(hidden.map((e) => e.event.content), equals(['middle']));
  });

  test('loadHiddenEvents ignores visible events', () async {
    final cacheManager = getCacheManager();

    await cacheManager.saveEvents([
      Nip01Event(
        pubKey: _hiddenAuthor,
        kind: 1,
        tags: [],
        content: 'visible note',
        createdAt: 100,
      ),
      _article(dTag: 'article-a', createdAt: 100, content: 'only version'),
    ]);

    expect(await cacheManager.loadHiddenEvents(), isEmpty);
  });
}
