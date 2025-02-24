import 'package:test/test.dart';
import 'package:ndk/entities.dart';

void main() {
  group('Filter', () {
    test('Constructor initializes correctly', () {
      var filter = Filter(
        ids: ['id1', 'id2'],
        authors: ['author1', 'author2'],
        kinds: [1, 2],
        search: 'search text',
        since: 1620000000,
        until: 1630000000,
        limit: 10,
        eTags: ['etag1'],
        pTags: ['ptag1'],
        tTags: ['ttag1'],
        aTags: ['atag1'],
        dTags: ['dtag1'],
        mTags: ['mtag1'],
      );

      expect(filter.ids, ['id1', 'id2']);
      expect(filter.authors, ['author1', 'author2']);
      expect(filter.kinds, [1, 2]);
      expect(filter.search, 'search text');
      expect(filter.since, 1620000000);
      expect(filter.until, 1630000000);
      expect(filter.limit, 10);
      expect(filter.eTags, ['etag1']);
      expect(filter.pTags, ['ptag1']);
      expect(filter.tTags, ['ttag1']);
      expect(filter.aTags, ['atag1']);
      expect(filter.dTags, ['dtag1']);
      expect(filter.mTags, ['mtag1']);
    });

    test('Constructor initializes tags correctly', () {
      var filter = Filter(
        tags: {
          '#e': ['etag1', 'etag2'],
          '#p': ['ptag1'],
        },
      );

      expect(filter.tags, isNotNull);
      expect(filter.tags!['#e'], ['etag1', 'etag2']);
      expect(filter.tags!['#p'], ['ptag1']);
    });

    test('fromMap initializes correctly', () {
      var map = {
        'ids': ['id1', 'id2'],
        'authors': ['author1', 'author2'],
        'kinds': [1, 2],
        'search': 'search text',
        'since': 1620000000,
        'until': 1630000000,
        'limit': 10,
        '#e': ['etag1'],
        '#p': ['ptag1'],
        '#t': ['ttag1'],
        '#a': ['atag1'],
        '#d': ['dtag1'],
        '#m': ['mtag1'],
      };

      var filter = Filter.fromMap(map);

      expect(filter.ids, ['id1', 'id2']);
      expect(filter.authors, ['author1', 'author2']);
      expect(filter.kinds, [1, 2]);
      expect(filter.search, 'search text');
      expect(filter.since, 1620000000);
      expect(filter.until, 1630000000);
      expect(filter.limit, 10);
      expect(filter.eTags, ['etag1']);
      expect(filter.pTags, ['ptag1']);
      expect(filter.tTags, ['ttag1']);
      expect(filter.aTags, ['atag1']);
      expect(filter.dTags, ['dtag1']);
      expect(filter.mTags, ['mtag1']);
    });

    test('toMap converts correctly', () {
      var filter = Filter(
        ids: ['id1', 'id2'],
        authors: ['author1', 'author2'],
        kinds: [1, 2],
        search: 'search text',
        since: 1620000000,
        until: 1630000000,
        limit: 10,
        eTags: ['etag1'],
        pTags: ['ptag1'],
        tTags: ['ttag1'],
        aTags: ['atag1'],
        dTags: ['dtag1'],
        mTags: ['mtag1'],
      );

      var map = filter.toMap();

      expect(map['ids'], ['id1', 'id2']);
      expect(map['authors'], ['author1', 'author2']);
      expect(map['kinds'], [1, 2]);
      expect(map['search'], 'search text');
      expect(map['since'], 1620000000);
      expect(map['until'], 1630000000);
      expect(map['limit'], 10);
      expect(map['#e'], ['etag1']);
      expect(map['#p'], ['ptag1']);
      expect(map['#t'], ['ttag1']);
      expect(map['#a'], ['atag1']);
      expect(map['#d'], ['dtag1']);
      expect(map['#m'], ['mtag1']);
    });

    test('clone creates a deep copy', () {
      var filter = Filter(
        ids: ['id1', 'id2'],
        authors: ['author1', 'author2'],
        kinds: [1, 2],
        search: 'search text',
        since: 1620000000,
        until: 1630000000,
        limit: 10,
        eTags: ['etag1'],
        pTags: ['ptag1'],
        tTags: ['ttag1'],
        aTags: ['atag1'],
        dTags: ['dtag1'],
        mTags: ['mtag1'],
      );

      var clone = filter.clone();

      expect(clone.ids, ['id1', 'id2']);
      expect(clone.authors, ['author1', 'author2']);
      expect(clone.kinds, [1, 2]);
      expect(clone.search, 'search text');
      expect(clone.since, 1620000000);
      expect(clone.until, 1630000000);
      expect(clone.limit, 10);
      expect(clone.eTags, ['etag1']);
      expect(clone.pTags, ['ptag1']);
      expect(clone.tTags, ['ttag1']);
      expect(clone.aTags, ['atag1']);
      expect(clone.dTags, ['dtag1']);
      expect(clone.mTags, ['mtag1']);
    });

    test('cloneWithAuthors updates authors', () {
      var filter = Filter(
        authors: ['author1', 'author2'],
      );

      var newAuthors = ['author3', 'author4'];
      var updatedFilter = filter.cloneWithAuthors(newAuthors);

      expect(updatedFilter.authors, newAuthors);
    });

    test('cloneWithPTags updates pTags', () {
      var filter = Filter(
        pTags: ['ptag1'],
      );

      var newPTags = ['ptag2', 'ptag3'];
      var updatedFilter = filter.cloneWithPTags(newPTags);

      expect(updatedFilter.pTags, newPTags);
    });

    test('mergeAuthors merges authors correctly', () {
      var filter1 = Filter(authors: ['author1', 'author2']);
      var filter2 = Filter(authors: ['author2', 'author3']);

      var mergedFilter = Filter.mergeAuthors(filter1, filter2);

      expect(mergedFilter.authors, ['author1', 'author2', 'author3']);
    });

    test('setTag and getTag work correctly', () {
      var filter = Filter();

      filter.setTag('x', ['xtag1', 'xtag2']);
      expect(filter.getTag('x'), ['xtag1', 'xtag2']);

      filter.setTag('#y', ['ytag1']);
      expect(filter.getTag('y'), ['ytag1']);
    });

  });
}