import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/nip_51_list.dart';
import 'package:ndk/shared/event_filters/nip51_mute_event_filter.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/shared/nips/nip25/reactions.dart';

void main() {
  group('Nip51MuteEventFilter', () {
    late Nip51MuteEventFilter filter;
    late Nip51List muteList;

    setUp(() {
      filter = Nip51MuteEventFilter();
      muteList = Nip51List(
        pubKey: 'testPubKey',
        kind: Nip51List.kMute,
        elements: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    });

    Nip01Event createEvent({
      String pubKey = 'pubkey1',
      int kind = 1,
      String content = 'hello world',
      List<List<String>> tags = const [],
      int? createdAt,
    }) {
      return Nip01Event(
        pubKey: pubKey,
        createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: kind,
        tags: tags,
        content: content,
      );
    }

    test('should not filter if mute list is empty', () {
      filter.muteList = muteList;
      final event = createEvent();
      expect(filter.filter(event), isTrue);
    });

    test('should filter event from muted pubKey', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kPubkey, value: 'mutedPubKey', private: false));
      filter.muteList = muteList;
      final event = createEvent(pubKey: 'mutedPubKey');
      expect(filter.filter(event), isFalse);
    });

    test('should not filter event from non-muted pubKey', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kPubkey, value: 'mutedPubKey', private: false));
      filter.muteList = muteList;
      final event = createEvent(pubKey: 'anotherPubKey');
      expect(filter.filter(event), isTrue);
    });

    test('should not filter metadata events from muted pubKey', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kPubkey, value: 'mutedPubKey', private: false));
      filter.muteList = muteList;
      final event = createEvent(pubKey: 'mutedPubKey', kind: Metadata.kKind);
      expect(filter.filter(event), isTrue);
    });

    test('should filter event with muted word in content', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kWord, value: 'secret', private: false));
      filter.muteList = muteList;
      final event = createEvent(content: 'this is a secret message');
      expect(filter.filter(event), isFalse);
    });

    test('should filter event with muted word (case-insensitive) in content',
        () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kWord, value: 'Secret', private: false));
      filter.muteList = muteList;
      final event = createEvent(content: 'this is a sEcReT message');
      expect(filter.filter(event), isFalse);
    });

    test('should not filter event without muted word in content', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kWord, value: 'secret', private: false));
      filter.muteList = muteList;
      final event = createEvent(content: 'this is a public message');
      expect(filter.filter(event), isTrue);
    });

    test('should not filter reaction events with muted word in content', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kWord, value: 'secret', private: false));
      filter.muteList = muteList;
      final event = createEvent(
          content: 'this is a secret message', kind: Reaction.kKind);
      expect(filter.filter(event), isTrue);
    });

    test('should filter event with muted hashtag', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kHashtag, value: 'mutedTag', private: false));
      filter.muteList = muteList;
      final event = createEvent(tags: [
        ['t', 'mutedTag']
      ]);
      expect(filter.filter(event), isFalse);
    });

    test('should filter event with muted hashtag (case-insensitive)', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kHashtag, value: 'MutedTag', private: false));
      filter.muteList = muteList;
      final event = createEvent(tags: [
        ['t', 'mutedtag']
      ]);
      expect(filter.filter(event), isFalse);
    });

    test('should not filter event without muted hashtag', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kHashtag, value: 'mutedTag', private: false));
      filter.muteList = muteList;
      final event = createEvent(tags: [
        ['t', 'anotherTag']
      ]);
      expect(filter.filter(event), isTrue);
    });

    test('should not filter event with no t-tags even if hashtags are muted',
        () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kHashtag, value: 'mutedTag', private: false));
      filter.muteList = muteList;
      final event = createEvent(tags: [
        ['p', 'somepubkey']
      ]);
      expect(filter.filter(event), isTrue);
    });

    test('should filter based on multiple criteria (pubKey and word)', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kPubkey, value: 'mutedAuthor', private: false));
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kWord, value: 'danger', private: false));
      filter.muteList = muteList;

      final eventFromMutedAuthor =
          createEvent(pubKey: 'mutedAuthor', content: 'safe content');
      expect(filter.filter(eventFromMutedAuthor), isFalse,
          reason: "Event from muted author should be filtered");

      final eventWithMutedWord =
          createEvent(pubKey: 'safeAuthor', content: 'this is danger');
      expect(filter.filter(eventWithMutedWord), isFalse,
          reason: "Event with muted word should be filtered");
    });

    test('TrieTree: should find a word that exists', () {
      final trie =
          filter.buildTrieTree(["hello".codeUnits, "world".codeUnits], null);
      expect(trie.check("hello"), isTrue);
      expect(trie.check("world"), isTrue);
    });

    test(
        'TrieTree: should find a word that is a prefix of another word if marked as done',
        () {
      final trie =
          filter.buildTrieTree(["hell".codeUnits, "hello".codeUnits], null);
      expect(trie.check("hell"), isTrue);
      expect(trie.check("hello"), isTrue);
    });

    test('TrieTree: should handle empty string check', () {
      final trie = filter.buildTrieTree(["hello".codeUnits], null);
      expect(trie.check(""), isFalse);
    });

    test('TrieTree: should handle empty word list for building', () {
      final trie = filter.buildTrieTree([], null);
      expect(trie.check("anyword"), isFalse);
    });

    test('hasMutedWord: should correctly identify muted words', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kWord, value: 'test', private: false));
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kWord, value: 'filter', private: false));
      filter.muteList = muteList;
      expect(filter.hasMutedWord('this is a test message'), isTrue);
      expect(filter.hasMutedWord('apply this filter'), isTrue);
      expect(filter.hasMutedWord('This Is A Test Message'),
          isTrue); // case-insensitivity
    });

    test('hasMutedWord: should not identify non-muted words', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kWord, value: 'test', private: false));
      filter.muteList = muteList;
      expect(filter.hasMutedWord('this is a safe message'), isFalse);
    });

    test('isMutedPubKey: should correctly identify muted pubkeys', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kPubkey, value: 'pk1', private: false));
      filter.muteList = muteList;
      expect(filter.isMutedPubKey('pk1'), isTrue);
    });

    test('isMutedPubKey: should not identify non-muted pubkeys', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kPubkey, value: 'pk1', private: false));
      filter.muteList = muteList;
      expect(filter.isMutedPubKey('pk2'), isFalse);
    });

    test('hasMutedHashtag: should correctly identify muted hashtags', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kHashtag, value: 'nostr', private: false));
      filter.muteList = muteList;
      final eventWithMutedTag = createEvent(tags: [
        ['t', 'nostr']
      ]);
      final eventWithMutedTagCaps = createEvent(tags: [
        ['t', 'NOSTR']
      ]);
      expect(filter.hasMutedHashtag(eventWithMutedTag), isTrue);
      // Nip51MuteEventFilter converts muted tags to lowercase upon setting muteList
      // and event.tTags are also expected to be lowercase or handled as such by contains.
      // Let's ensure the comparison is robust.
      expect(filter.hasMutedHashtag(eventWithMutedTagCaps), isTrue);
    });

    test('hasMutedHashtag: should not identify non-muted hashtags', () {
      muteList.elements.add(Nip51ListElement(
          tag: Nip51List.kHashtag, value: 'nostr', private: false));
      filter.muteList = muteList;
      final eventWithoutMutedTag = createEvent(tags: [
        ['t', 'bitcoin']
      ]);
      expect(filter.hasMutedHashtag(eventWithoutMutedTag), isFalse);
    });
  });
}
