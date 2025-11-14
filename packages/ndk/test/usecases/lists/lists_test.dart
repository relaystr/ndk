import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../mocks/mock_event_verifier.dart';
import '../../mocks/mock_relay.dart';

void main() async {
  group('lists', () {
    KeyPair key0 = Bip340.generatePrivateKey();
    KeyPair key1 = Bip340.generatePrivateKey();
    Bip340EventSigner signer0 = Bip340EventSigner(
      privateKey: key0.privateKey,
      publicKey: key0.publicKey,
    );
    Bip340EventSigner signer1 = Bip340EventSigner(
      privateKey: key1.privateKey,
      publicKey: key1.publicKey,
    );

    final Nip51List bookmarkListKey0 = Nip51List(
        pubKey: key0.publicKey,
        kind: Nip51List.kBookmarks,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        elements: [
          Nip51ListElement(
              tag: Nip51List.kPubkey, value: key1.publicKey, private: false)
        ]);

    final Nip51Set favoriteRelaysKey1 = Nip51Set(
        pubKey: key1.publicKey,
        kind: Nip51List.kRelaySet,
        name: "my favorite relays",
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        elements: [
          Nip51ListElement(
              tag: Nip51List.kRelay, value: "wss://bla.com", private: true)
        ]);

    late MockRelay relay0;
    late Ndk ndk;

    setUp(() async {
      relay0 = MockRelay(name: "relay 0", explicitPort: 4096);
      Nip01Event event0 = await bookmarkListKey0.toEvent(signer0);
      Nip01Event event1 = await favoriteRelaysKey1.toEvent(signer1);

      await signer0.sign(event0);
      await signer1.sign(event1);

      await relay0.startServer(textNotes: {key0: event0, key1: event1});

      final cache = MemCacheManager();
      final NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: cache,
        bootstrapRelays: [relay0.url],
      );

      ndk = Ndk(config);
    });

    tearDown(() async {
      await relay0.stopServer();
    });

    test('lists get bookmarks', () async {
      Nip51List? bookmarks =
          await ndk.lists.getSingleNip51List(Nip51List.kBookmarks, signer0);
      expect(bookmarkListKey0.kind, bookmarks!.kind);
      expect(bookmarkListKey0.elements.length, bookmarks.elements.length);
      expect(bookmarkListKey0.elements.first.value,
          bookmarks.elements.first.value);
    });

    test('lists get favorite relays', () async {
      Nip51Set? relays = await ndk.lists
          .getSingleNip51RelaySet(favoriteRelaysKey1.name, signer1);
      expect(favoriteRelaysKey1.kind, relays!.kind);
      expect(favoriteRelaysKey1.elements.length, relays.elements.length);
      expect(
          favoriteRelaysKey1.elements.first.value, relays.elements.first.value);
    });

    test('lists get bookmarks with forceRefresh', () async {
      Nip51List? bookmarks = await ndk.lists.getSingleNip51List(
          Nip51List.kBookmarks, signer0,
          forceRefresh: true);
      expect(bookmarks, isNotNull);
      expect(bookmarkListKey0.kind, bookmarks!.kind);
    });

    test('lists get set by name', () async {
      Nip51Set? set = await ndk.lists.getSetByName(
          name: favoriteRelaysKey1.name,
          kind: Nip51List.kRelaySet,
          customSigner: signer1);
      expect(set, isNotNull);
      expect(set!.name, favoriteRelaysKey1.name);
    });

    test('lists get public sets', () async {
      final sets = ndk.lists
          .getPublicSets(kind: Nip51List.kRelaySet, publicKey: key1.publicKey);
      final result = await sets.first;
      expect(result, isNotNull);
      expect(result?.first.name, favoriteRelaysKey1.name);
    });

    test('addElementToList creates new list if not exists', () async {
      ndk.accounts.loginExternalSigner(signer: signer0);
      final list = await ndk.lists.addElementToList(
          kind: Nip51List.kBookmarks,
          tag: Nip51List.kPubkey,
          value: 'newPubkey123');
      expect(list.elements.any((e) => e.value == 'newPubkey123'), isTrue);
    });

    test('removeElementFromList removes element', () async {
      ndk.accounts.loginExternalSigner(signer: signer0);
      final list = await ndk.lists.removeElementFromList(
          kind: Nip51List.kBookmarks,
          tag: Nip51List.kPubkey,
          value: key1.publicKey);
      expect(list, isNotNull);
      expect(list!.pubKeys, isNot(contains(key1.publicKey)));
    });

    test('addElementToSet creates new set if not exists', () async {
      ndk.accounts.loginExternalSigner(signer: signer1);

      final setCheck = await ndk.lists
          .getSetByName(name: 'test-set', kind: Nip51List.kRelaySet);
      expect(setCheck, isNull);

      final set = await ndk.lists.addElementToSet(
          name: 'test-set',
          tag: Nip51List.kRelay,
          value: 'wss://test.com',
          kind: Nip51List.kRelaySet);
      expect(set, isNotNull);
      expect(set!.elements.any((e) => e.value == 'wss://test.com'), isTrue);
    });

    test('removeElementFromSet removes element', () async {
      ndk.accounts.loginExternalSigner(signer: signer1);
      final set = await ndk.lists.removeElementFromSet(
          name: favoriteRelaysKey1.name,
          tag: Nip51List.kRelay,
          value: 'wss://bla.com',
          kind: Nip51List.kRelaySet);

      final fetchedSet = await ndk.lists.getSetByName(
        name: favoriteRelaysKey1.name,
        kind: Nip51List.kRelaySet,
      );
      expect(set, isNotNull);
      expect(fetchedSet, isNotNull);
      expect(set!.elements.any((e) => e.value == 'wss://bla.com'), isFalse);
      expect(
          fetchedSet!.elements.any((e) => e.value == 'wss://bla.com'), isFalse);
    });

    test('setCompleteSet replaces existing set', () async {
      ndk.accounts.loginExternalSigner(signer: signer1);

      final newSet = Nip51Set(
          pubKey: key1.publicKey,
          kind: Nip51List.kRelaySet,
          name: "replacement-set",
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          elements: [
            Nip51ListElement(
                tag: Nip51List.kRelay,
                value: "wss://newrelay.com",
                private: false)
          ]);

      ndk.lists.addElementToSet(
          name: "replacement-set",
          tag: Nip51List.kRelay,
          value: "wss://oldrelay.com",
          kind: Nip51List.kRelaySet);

      final result = await ndk.lists
          .setCompleteSet(set: newSet, kind: Nip51List.kRelaySet);
      expect(result.name, "replacement-set");
      expect(result.elements.length, 1);
    });

    test('deleteSet removes set from cache', () async {
      ndk.accounts.loginExternalSigner(signer: signer1);

      const setName = "myDeletionSet";

      await ndk.lists.addElementToSet(
        name: setName,
        tag: "p",
        value: "mypubkey",
        kind: Nip51List.kRelaySet,
      );

      await ndk.lists.deleteSet(name: setName, kind: Nip51List.kRelaySet);

      // Verify deletion by trying to fetch
      final set = await ndk.lists.getSetByName(
        name: setName,
        kind: Nip51List.kRelaySet,
      );
      expect(set, isNull);
    });

    test('addElementToList throws without signer', () async {
      expect(
          () async => await ndk.lists.addElementToList(
              kind: Nip51List.kBookmarks,
              tag: Nip51List.kPubkey,
              value: 'test'),
          throwsException);
    });

    test('removeElementFromList throws without signer', () async {
      expect(
          () async => await ndk.lists.removeElementFromList(
              kind: Nip51List.kBookmarks,
              tag: Nip51List.kPubkey,
              value: 'test'),
          throwsException);
    });

    test('removeElementFromSet throws without signer', () async {
      expect(
          () async => await ndk.lists.removeElementFromSet(
              name: 'test-set',
              value: 'wss://test.com',
              tag: Nip51List.kRelay,
              kind: Nip51List.kRelaySet),
          throwsException);
    });

    test('deleteSet throws without signer', () async {
      expect(
          () async => await ndk.lists
              .deleteSet(name: 'test-set', kind: Nip51List.kRelaySet),
          throwsException);
    });

    test('getSetByName throws when not logged in and no custom signer',
        () async {
      expect(
          () async => await ndk.lists
              .getSetByName(name: 'test', kind: Nip51List.kRelaySet),
          throwsException);
    });

    test('addElementToList creates new list when none exists', () async {
      ndk.accounts.loginExternalSigner(signer: signer0);

      // Use a kind that doesn't exist
      const int nonExistentKind =
          30078; // Generic list kind that wasn't initialized

      final list = await ndk.lists.addElementToList(
        kind: nonExistentKind,
        tag: Nip51List.kPubkey,
        value: 'newPubkey123',
      );

      expect(list, isNotNull);
      expect(list.kind, nonExistentKind);
      expect(list.pubKey, key0.publicKey);
      expect(list.elements.length, 1);
      expect(list.elements.first.value, 'newPubkey123');
      expect(list.elements.first.tag, Nip51List.kPubkey);
    });

    test('removeElementFromList creates empty list when none exists', () async {
      ndk.accounts.loginExternalSigner(signer: signer0);

      // Use a kind that doesn't exist
      const int nonExistentKind = 30079;

      final list = await ndk.lists.removeElementFromList(
        kind: nonExistentKind,
        tag: Nip51List.kPubkey,
        value: 'somePubkey',
      );

      expect(list, isNotNull);
      expect(list!.kind, nonExistentKind);
      expect(list.pubKey, key0.publicKey);
      expect(list.elements.length, 0);
    });

    test('removeElementFromSetcreates empty list when none exists', () async {
      ndk.accounts.loginExternalSigner(signer: signer0);

      // Use a kind that doesn't exist

      final list = await ndk.lists.removeElementFromSet(
        name: 'nonExistentSet00',
        kind: Nip51List.kRelaySet,
        tag: Nip51List.kPubkey,
        value: 'somePubkey',
      );

      expect(list, isNotNull);
      expect(list!.pubKey, key0.publicKey);
      expect(list.elements.length, 0);
    });

    test('getSetByName returns most recent set when multiple exist', () async {
      ndk.accounts.loginExternalSigner(signer: signer1);

      const setName = "test-set-with-multiple-versions";

      final oldSet = Nip51Set(
        pubKey: key1.publicKey,
        kind: Nip51List.kRelaySet,
        name: setName,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 -
            100, // 100 seconds ago
        elements: [
          Nip51ListElement(
            tag: Nip51List.kRelay,
            value: "wss://old.com",
            private: false,
          )
        ],
      );

      final newSet = Nip51Set(
        pubKey: key1.publicKey,
        kind: Nip51List.kRelaySet,
        name: setName,
        createdAt:
            DateTime.now().millisecondsSinceEpoch ~/ 1000, // current time
        elements: [
          Nip51ListElement(
            tag: Nip51List.kRelay,
            value: "wss://new.com",
            private: false,
          )
        ],
      );

      // Convert to events and save to cache
      final oldEvent = await oldSet.toEvent(signer1);
      final newEvent = await newSet.toEvent(signer1);

      await signer1.sign(oldEvent);
      await signer1.sign(newEvent);

      // Save both to cache
      await ndk.config.cache.saveEvent(oldEvent);
      await ndk.config.cache.saveEvent(newEvent);

      // Fetch the set - should return the newer one
      final fetchedSet = await ndk.lists.getSetByName(
        name: setName,
        kind: Nip51List.kRelaySet,
      );

      expect(fetchedSet, isNotNull);
      expect(fetchedSet!.name, setName);
      expect(fetchedSet.createdAt, newSet.createdAt);
      expect(fetchedSet.elements.first.value, "wss://new.com");
    });
  });
}
