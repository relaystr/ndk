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
}
