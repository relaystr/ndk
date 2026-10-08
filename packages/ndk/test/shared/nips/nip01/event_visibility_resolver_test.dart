import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/event_visibility_resolver.dart';
import 'package:test/test.dart';

void main() {
  test('context reads keep author scope above one batch', () async {
    final candidates = List.generate(
      101,
      (index) => Nip01Event(
        pubKey: 'author-$index',
        kind: 1,
        tags: const [],
        content: 'note-$index',
        createdAt: index,
      ),
    );
    final requestedAuthorBatches = <List<String>>[];
    final resolver = EventVisibilityResolver(({
      ids,
      pubKeys,
      kinds,
      tags,
      since,
      until,
      search,
      limit,
    }) async {
      requestedAuthorBatches.add(pubKeys!);
      return <Nip01Event>[];
    });

    await resolver.filterVisible(candidates, now: 1000);

    expect(requestedAuthorBatches, hasLength(2));
    expect(requestedAuthorBatches.first, hasLength(100));
    expect(requestedAuthorBatches.last, hasLength(1));
    expect(
      requestedAuthorBatches.expand((batch) => batch).toSet(),
      equals(candidates.map((event) => event.pubKey).toSet()),
    );
  });

  test('a padded d-tag still finds the newer version of its event', () async {
    final cache = MemCacheManager();
    Nip01Event article(int createdAt) => Nip01Event(
      pubKey: 'author',
      kind: 30023,
      tags: const [
        ['d', 'article '],
      ],
      content: 'version $createdAt',
      createdAt: createdAt,
    );
    final older = article(100);
    await cache.saveEvents([older, article(200)]);

    // the context read filters on the raw 'article ', tag values are trimmed
    expect(await cache.loadEvents(ids: [older.id]), isEmpty);
  });
}
